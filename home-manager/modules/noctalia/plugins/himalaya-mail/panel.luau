--!nonstrict
-- Inbox panel: unread envelopes from state "mail" with per-row actions.
-- Row actions update the shared state immediately (so the bar count follows)
-- and ask the poller service for a re-fetch once himalaya has finished.

local himalaya = require("./lib/himalaya.luau")

local mail = noctalia.state.get("mail")
local open = false
local nonce = 0

local render -- forward declaration

local function requestRefresh()
  nonce += 1
  noctalia.state.set("command", { action = "refresh", nonce = nonce })
end

local function setEnvelopes(envelopes)
  mail = { envelopes = envelopes, error = if type(mail) == "table" then mail.error else nil }
  noctalia.state.set("mail", mail)
end

local function without(id)
  local kept = {}
  if type(mail) == "table" then
    for _, e in mail.envelopes do
      if e.id ~= id then
        table.insert(kept, e)
      end
    end
  end
  return kept
end

local function run(label, cmd, onOk)
  noctalia.runAsync(cmd, function(result)
    if result.exitCode ~= 0 then
      noctalia.notifyError(`{label} failed`, noctalia.string.trim(result.stderr))
    elseif onOk ~= nil then
      onOk(result)
    end
    requestRefresh()
  end, 60000)
end

local function markRead(id)
  setEnvelopes(without(id))
  run("Mark as read", himalaya.argv({ "flag", "add" }, { "--flag", "seen", id }))
end

local function archive(id)
  setEnvelopes(without(id))
  run("Archive", himalaya.argv({ "message", "move" }, { "--to", "Archive", id }, "--from"))
end

local function trash(id)
  setEnvelopes(without(id))
  run("Delete", himalaya.argv({ "message", "move" }, { "--to", "Trash", id }, "--from"))
end

local function toggleFlag(envelope)
  local updated = {}
  for _, e in mail.envelopes do
    if e.id == envelope.id then
      e = table.clone(e)
      e.flagged = not envelope.flagged
    end
    table.insert(updated, e)
  end
  setEnvelopes(updated)
  local verb = if envelope.flagged then "remove" else "add"
  run("Flag toggle", himalaya.argv({ "flag", verb }, { "--flag", "flagged", envelope.id }))
end

local function escapeHtml(s)
  return (s:gsub("[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
end

-- Render the message's text part (falling back to its HTML part) into a
-- local file and hand it to the browser. Remote content is never fetched
-- for the text path, which is what the old QML panel did too.
local function openInBrowser(envelope)
  run("Open", himalaya.argv({ "message", "read" }, { envelope.id }), function(result)
    local msg = noctalia.json.decode(result.stdout)
    if type(msg) ~= "table" or type(msg.parts) ~= "table" then
      noctalia.notifyError("Open failed", "unexpected himalaya output")
      return
    end
    local function part(indexes, kind)
      if type(indexes) ~= "table" or indexes[1] == nil then
        return nil
      end
      local p = msg.parts[indexes[1] + 1] -- JSON indexes are zero-based
      if type(p) == "table" and type(p.body) == "table" and type(p.body[kind]) == "string" then
        return p.body[kind]
      end
      return nil
    end
    local html
    local text = part(msg.text_body, "Text")
    if text ~= nil then
      html = "<html><head><meta charset='utf-8'><style>body{font-family:sans-serif;max-width:800px;"
        .. "margin:2em auto;padding:0 1em;line-height:1.6;white-space:pre-wrap;color:#222;background:#fafafa}"
        .. "</style></head><body>"
        .. `<h2>{escapeHtml(envelope.subject)}</h2><p><b>{escapeHtml(envelope.from)}</b> · {escapeHtml(envelope.date)}</p><hr>`
        .. escapeHtml(text)
        .. "</body></html>"
    else
      html = part(msg.html_body, "Html")
    end
    if html == nil then
      noctalia.notifyError("Open failed", "message has no readable body")
      return
    end
    local dir = noctalia.pluginDataDir()
    if dir == nil then
      noctalia.notifyError("Open failed", "no plugin data directory")
      return
    end
    local path = dir .. "/view.html"
    local ok, err = noctalia.writeFile(path, html)
    if not ok then
      noctalia.notifyError("Open failed", err or path)
      return
    end
    noctalia.runAsync({ "xdg-open", path })
  end)
end

local function envelopeRow(e)
  return ui.column({ key = e.id, gap = 2, padding = 8, fill = "surface_variant", radius = 8 }, {
    ui.label({ text = e.subject, fontWeight = "bold", maxLines = 1 }),
    ui.row({ gap = 4, align = "center" }, {
      ui.label({
        text = `{e.from}  ·  {e.date}`,
        fontSize = 12,
        color = "on_surface_variant",
        maxLines = 1,
        flexGrow = 1,
      }),
      ui.button({
        glyph = "external-link",
        variant = "ghost",
        controlSize = "sm",
        tooltip = "Open in browser",
        onClick = function()
          openInBrowser(e)
        end,
      }),
      ui.button({
        glyph = if e.flagged then "star-filled" else "star",
        variant = "ghost",
        controlSize = "sm",
        tooltip = if e.flagged then "Unflag" else "Flag",
        onClick = function()
          toggleFlag(e)
        end,
      }),
      ui.button({
        glyph = "check",
        variant = "ghost",
        controlSize = "sm",
        tooltip = "Mark as read",
        onClick = function()
          markRead(e.id)
        end,
      }),
      ui.button({
        glyph = "archive",
        variant = "ghost",
        controlSize = "sm",
        tooltip = "Archive",
        onClick = function()
          archive(e.id)
        end,
      }),
      ui.button({
        glyph = "trash",
        variant = "ghost",
        controlSize = "sm",
        tooltip = "Delete",
        onClick = function()
          trash(e.id)
        end,
      }),
    }),
  })
end

function render()
  local envelopes = if type(mail) == "table" then mail.envelopes else {}
  local children = {
    ui.row({ gap = 8, align = "center" }, {
      ui.glyph({ name = "mail", size = 18, color = "primary" }),
      ui.label({ text = `Unread Mail ({#envelopes})`, fontWeight = "bold", fontSize = 16, flexGrow = 1 }),
      ui.button({ glyph = "refresh", variant = "ghost", tooltip = "Refresh", onClick = "onRefresh" }),
    }),
  }
  if type(mail) == "table" and mail.error ~= nil then
    table.insert(children, ui.label({ text = mail.error, color = "error", maxLines = 3 }))
  end
  if #envelopes == 0 then
    table.insert(children, ui.label({ text = "No unread mail", color = "on_surface_variant", textAlign = "center" }))
  else
    local rows = {}
    for _, e in envelopes do
      table.insert(rows, envelopeRow(e))
    end
    table.insert(children, ui.scroll({ gap = 6, flexGrow = 1 }, rows))
  end
  panel.render(ui.column({ gap = 10, padding = 12, align = "stretch" }, children))
end

function onRefresh()
  requestRefresh()
end

noctalia.state.watch("mail", function(value)
  mail = value
  if open then
    render()
  end
end)

function onOpen(_context)
  open = true
  mail = noctalia.state.get("mail")
  render()
  requestRefresh()
end

function onClose()
  open = false
end

--!nonstrict
-- Askpass prompt panel. Opened by the noctalia-askpass script with a JSON
-- context { prompt, caller, fifo }. The answer is written to the FIFO the
-- script blocks on; an empty answer means cancel (script exits 1).

local request = nil -- { prompt, caller, fifo } of the pending request
local answered = false
local password = ""
local inputKey = 0

local function reply(fifo, text)
  -- Detached: opening a FIFO blocks until the reader shows up, and a reader
  -- that already gave up must never stall the shell. The text travels as an
  -- argv element, never through shell parsing.
  noctalia.runAsync({ "sh", "-c", 'printf %s "$1" > "$2"', "sh", text, fifo })
end

local function settle(text)
  if request == nil or answered then
    return
  end
  answered = true
  reply(request.fifo, text)
end

local function render()
  local prompt = if request ~= nil then request.prompt else "Enter password"
  local caller = if request ~= nil then request.caller else ""
  panel.render(ui.column({ gap = 12, padding = 14, align = "stretch" }, {
    ui.row({ gap = 10, align = "center" }, {
      ui.glyph({ name = "lock", size = 24, color = "primary" }),
      ui.column({ gap = 2, flexGrow = 1 }, {
        ui.label({ text = prompt, fontWeight = "bold", maxLines = 2 }),
        ui.label({
          text = "Requested by: " .. caller,
          fontSize = 12,
          color = "on_surface_variant",
          maxLines = 1,
          visible = caller ~= "",
        }),
      }),
    }),
    ui.input({
      key = "pw_" .. tostring(inputKey),
      value = "",
      placeholder = "Password",
      password = true,
      focus = true,
      onChange = "onPasswordChange",
      onSubmit = "onSubmit",
    }),
    ui.row({ gap = 8, justify = "end" }, {
      ui.button({ text = "Cancel", variant = "outline", onClick = "onCancel" }),
      ui.button({ text = "Unlock", glyph = "lock-open", variant = "primary", onClick = "onSubmit" }),
    }),
  }))
end

function onPasswordChange(value)
  password = if type(value) == "string" then value else ""
end

function onSubmit()
  if request == nil or password == "" then
    return
  end
  local pw = password
  password = ""
  settle(pw)
  panel.close()
end

function onCancel()
  panel.close()
end

function onOpen(context)
  -- Re-opened with a new request while one is still pending: cancel the old.
  settle("")
  request = nil
  answered = false
  password = ""
  inputKey += 1

  local decoded = if type(context) == "string" then noctalia.json.decode(context) else nil
  if type(decoded) == "table" and type(decoded.fifo) == "string" and decoded.fifo ~= "" then
    request = {
      prompt = if type(decoded.prompt) == "string" and decoded.prompt ~= "" then decoded.prompt else "Enter password",
      caller = if type(decoded.caller) == "string" then decoded.caller else "",
      fifo = decoded.fifo,
    }
  else
    noctalia.log("askpass: opened without a request context; nothing to answer")
  end
  render()
end

function onClose()
  -- Escape / Cancel / any other dismissal: release the waiting script.
  settle("")
  request = nil
  password = ""
end

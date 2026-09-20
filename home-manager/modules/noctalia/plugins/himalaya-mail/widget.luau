--!nonstrict
-- Bar widget: mail glyph + unread count ("N+" when the poll hit its
-- page_size cap). Red "!" with the error in the tooltip when the last poll
-- failed. Click opens the inbox panel.

local pageSize = noctalia.getConfig("page_size")

local function render(mail)
  local text = "…"
  local color = nil
  if type(mail) == "table" then
    if mail.error ~= nil then
      text = "!"
      color = "error"
      barWidget.setTooltip(mail.error)
    else
      local n = #mail.envelopes
      text = if n >= pageSize then `{n}+` else tostring(n)
      barWidget.setTooltip(if n >= pageSize then `at least {n} unread` else `{n} unread`)
    end
  end
  local container = if barWidget.isVertical() then ui.column else ui.row
  barWidget.render(container({ gap = 4, align = "center" }, {
    ui.glyph({ name = "mail", size = 14, color = color }),
    ui.label({ text = text, color = color }),
  }))
end

noctalia.state.watch("mail", render)

function update()
  noctalia.setUpdateInterval(60000)
  render(noctalia.state.get("mail"))
end

function onClick()
  noctalia.togglePanel("pinpox/himalaya-mail:inbox")
end

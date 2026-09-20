--!nonstrict
-- Polls unread envelopes and publishes them as state "mail":
--   { envelopes = { {id, subject, from, date, flagged}… }, error = string? }
-- Other entries request a re-fetch by setting state "command" to
-- { action = "refresh", nonce = <unique> }.

local himalaya = require("./lib/himalaya.luau")

local busy = false

local function publish(envelopes, err)
  noctalia.state.set("mail", { envelopes = envelopes, error = err })
end

local function fetch()
  if busy then
    return
  end
  busy = true
  local cmd = himalaya.argv(
    { "envelope", "search", "--page-size", tostring(noctalia.getConfig("page_size")) },
    { "not flag seen" }
  )
  noctalia.runAsync(cmd, function(result)
    busy = false
    if result.exitCode ~= 0 then
      local msg = noctalia.string.trim(result.stderr)
      if msg == "" then
        msg = if result.timedOut then "himalaya timed out" else `himalaya exited with {result.exitCode}`
      end
      noctalia.log("himalaya-mail: " .. msg)
      publish(noctalia.state.get("mail") and noctalia.state.get("mail").envelopes or {}, msg)
      return
    end
    local data = noctalia.json.decode(result.stdout)
    if type(data) ~= "table" or type(data.envelopes) ~= "table" then
      publish({}, "unexpected himalaya output")
      return
    end
    local envelopes = {}
    for _, env in data.envelopes do
      table.insert(envelopes, himalaya.envelope(env))
    end
    publish(envelopes, nil)
  end, 60000)
end

noctalia.state.watch("command", function(cmd)
  if type(cmd) == "table" and cmd.action == "refresh" then
    fetch()
  end
end)

function onConfigChanged()
  noctalia.setUpdateInterval(noctalia.getConfig("poll_seconds") * 1000)
  fetch()
end

function update()
  fetch()
end

noctalia.setUpdateInterval(noctalia.getConfig("poll_seconds") * 1000)
fetch()

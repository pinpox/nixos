--!nonstrict
-- Shared himalaya CLI argv builders. himalaya is resolved from PATH; its
-- config (and the password command it runs) comes from home-manager.

local M = {}

-- `himalaya --json [--account A] <subcommand…> [<mailboxFlag> M] <rest…>`
-- --account is global; the mailbox option belongs to the subcommand and is
-- spelled --mailbox everywhere except `message move`/`copy`, which use --from.
function M.argv(subcommand, rest, mailboxFlag)
  local cmd = { "himalaya", "--json" }
  local account = noctalia.getConfig("account")
  if type(account) == "string" and account ~= "" then
    table.insert(cmd, "--account")
    table.insert(cmd, account)
  end
  for _, a in subcommand do
    table.insert(cmd, a)
  end
  local mailbox = noctalia.getConfig("mailbox")
  if type(mailbox) == "string" and mailbox ~= "" then
    table.insert(cmd, mailboxFlag or "--mailbox")
    table.insert(cmd, mailbox)
  end
  for _, a in rest do
    table.insert(cmd, a)
  end
  return cmd
end

-- "2026-09-20T20:49:04Z" -> local "2026-09-20 22:49"; anything else verbatim.
function M.localDate(iso)
  if type(iso) ~= "string" then
    return ""
  end
  local y, mo, d, h, mi, s = iso:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
  if y == nil then
    return iso
  end
  -- os.time reads the table as local time; shift by the local UTC offset.
  local asLocal = os.time({
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(s),
  })
  local offset = os.time() - os.time(os.date("!*t"))
  return os.date("%Y-%m-%d %H:%M", asLocal + offset)
end

-- Normalise one JSON envelope into the plain table shared over state.
function M.envelope(env)
  local from = "Unknown"
  if type(env.from) == "table" and env.from[1] ~= nil then
    local f = env.from[1]
    from = if type(f.name) == "string" and f.name ~= "" then f.name else (f.email or "Unknown")
  end
  local flagged = false
  if type(env.flags) == "table" then
    for _, flag in env.flags do
      if type(flag) == "string" and flag:lower() == "flagged" then
        flagged = true
      end
    end
  end
  return {
    id = tostring(env.id or ""),
    subject = if type(env.subject) == "string" and env.subject ~= "" then env.subject else "(no subject)",
    from = from,
    date = M.localDate(env.date),
    flagged = flagged,
  }
end

return M

--!nonstrict
-- Launcher provider: fuzzy search over the Firefox history exported by
-- firefox-history-helper (top 500 places by frecency, with cached favicons).
-- The export is refreshed in the background once it is older than MAX_AGE.

local PYTHON = "@python3@"
local MAX_AGE = 60 -- seconds
local MAX_RESULTS = 50

local entries = nil -- { { url, title, icon } … } or nil before the first load
local loadedAt = 0
local loading = false
local pendingQuery = nil

local function load()
  if loading then
    return
  end
  loading = true
  noctalia.runAsync({ PYTHON, noctalia.pluginDir() .. "/firefox-history-helper" }, function(result)
    loading = false
    if result.exitCode ~= 0 then
      noctalia.log("firefox-history: helper failed: " .. noctalia.string.trim(result.stderr))
      entries = entries or {}
    else
      local decoded = noctalia.json.decode(result.stdout)
      entries = if type(decoded) == "table" then decoded else {}
    end
    loadedAt = os.time()
    if pendingQuery ~= nil then
      local q = pendingQuery
      pendingQuery = nil
      onQuery(q)
    end
  end, 30000)
end

local function toResult(e, score)
  local icon = if type(e.icon) == "string" and e.icon ~= "" then e.icon else nil
  return {
    id = e.url,
    title = if type(e.title) == "string" and e.title ~= "" then e.title else e.url,
    subtitle = e.url,
    icon = icon,
    glyph = if icon == nil then "world-www" else nil,
    score = score,
  }
end

local function results(text)
  if text == "" then
    -- Unfiltered: the export is already ordered by frecency.
    local rows = {}
    for i = 1, math.min(20, #entries) do
      table.insert(rows, toResult(entries[i], #entries - i))
    end
    return rows
  end
  local scored = {}
  for _, e in entries do
    local best = noctalia.fuzzyScore(text, e.title or "")
    local urlScore = noctalia.fuzzyScore(text, e.url or "")
    if urlScore ~= nil and (best == nil or urlScore > best) then
      best = urlScore
    end
    if best ~= nil then
      table.insert(scored, { entry = e, score = best })
    end
  end
  table.sort(scored, function(a, b)
    return a.score > b.score
  end)
  if #scored == 0 then
    return { { id = "", title = "No matches", subtitle = "No history entries match your query", glyph = "search-off" } }
  end
  local rows = {}
  for i = 1, math.min(MAX_RESULTS, #scored) do
    table.insert(rows, toResult(scored[i].entry, scored[i].score))
  end
  return rows
end

function onQuery(query)
  if entries == nil then
    pendingQuery = query
    launcher.setResults(query, { { id = "", title = "Loading Firefox history…", glyph = "loader" } })
    load()
    return
  end
  if os.time() - loadedAt > MAX_AGE then
    load() -- serve the stale export now; results refresh on the next keystroke
  end
  launcher.setResults(query, results(noctalia.string.trim(query)))
end

function onActivate(id)
  if id ~= "" then
    noctalia.runAsync({ "xdg-open", id })
  end
end

import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null
  property var launcher: null
  property string name: "Firefox History"
  property string supportedLayouts: "list"
  property bool handleSearch: true
  property bool supportsAutoPaste: false

  property var entries: []
  property bool loaded: false

  // Query Firefox history via sqlite3
  Process {
    id: historyProc
    property string output: ""

    command: root.pluginApi
      ? ["python3", root.pluginApi.pluginDir + "/firefox-history-helper"]
      : []

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        historyProc.output += data
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && historyProc.output.trim()) {
        try {
          root.entries = JSON.parse(historyProc.output)
          root.loaded = true
        } catch (e) {
          root.entries = []
        }
        if (root.launcher) root.launcher.updateResults()
      }
      historyProc.output = ""
    }
  }

  function init() {}

  function onOpened() {
    historyProc.output = ""
    historyProc.running = true
  }

  function handleCommand(searchText) {
    return searchText.startsWith(">firefox")
  }

  function commands() {
    return [{
      "name": ">firefox",
      "description": "Search Firefox browsing history",
      "icon": "brand-firefox",
      "isTablerIcon": true,
      "isImage": false,
      "onActivate": function() {
        launcher.setSearchText(">firefox ")
      }
    }]
  }

  function getResults(searchText) {
    if (!loaded) return []

    var query
    if (searchText.startsWith(">firefox")) {
      query = searchText.slice(8).trim().toLowerCase()
    } else {
      query = searchText.trim().toLowerCase()
    }

    if (!query) return []

    // Fuzzy match: each query char must appear in order, not necessarily consecutive.
    // Returns -1 for no match, or a score (lower = tighter match).
    function fuzzyScore(text, pattern) {
      var ti = 0, pi = 0, score = 0, lastMatch = -1
      while (ti < text.length && pi < pattern.length) {
        if (text[ti] === pattern[pi]) {
          if (lastMatch >= 0) score += (ti - lastMatch - 1)
          lastMatch = ti
          pi++
        }
        ti++
      }
      return pi === pattern.length ? score : -1
    }

    var scored = []
    for (var i = 0; i < entries.length; i++) {
      var e = entries[i]
      var titleLower = e.title ? e.title.toLowerCase() : ""
      var urlLower = e.url ? e.url.toLowerCase() : ""
      var ts = fuzzyScore(titleLower, query)
      var us = fuzzyScore(urlLower, query)
      if (ts >= 0 || us >= 0) {
        var best = ts >= 0 && us >= 0 ? Math.min(ts, us) : (ts >= 0 ? ts : us)
        scored.push({ entry: e, score: best })
      }
    }

    scored.sort(function(a, b) { return a.score - b.score })

    if (scored.length === 0) {
      return [{
        "name": "No matches",
        "description": "No history entries match your query",
        "icon": "search-off",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {}
      }]
    }

    return scored.slice(0, 50).map(function(s) {
      var e = s.entry
      var url = e.url
      var title = e.title || e.url
      var hasIcon = e.icon && e.icon !== ""
      return {
        "name": title,
        "description": url,
        "icon": hasIcon ? e.icon : "world-www",
        "isTablerIcon": !hasIcon,
        "isImage": false,
        "onActivate": function() {
          Quickshell.execDetached(["xdg-open", url])
          launcher.close()
        }
      }
    })
  }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  property real contentPreferredWidth: 600 * Style.uiScaleRatio
  property real contentPreferredHeight: 500 * Style.uiScaleRatio

  anchors.fill: parent

  // Settings
  readonly property string folder:
    pluginApi?.pluginSettings?.folder ||
    pluginApi?.manifest?.metadata?.defaultSettings?.folder ||
    "INBOX"
  readonly property string himalayaBin:
    pluginApi?.pluginSettings?.himalayaBin ||
    pluginApi?.manifest?.metadata?.defaultSettings?.himalayaBin ||
    "himalaya"
  readonly property string account:
    pluginApi?.pluginSettings?.account || ""

  // State
  property var envelopes: []
  property bool loading: false
  property string lastOutput: ""

  ListModel {
    id: mailModel
  }

  // Fetch envelopes process
  Process {
    id: fetchProc
    command: {
      var cmd = [root.himalayaBin, "envelope", "list",
                 "--folder", root.folder,
                 "-o", "json",
                 "--page-size", "50",
                 "not", "flag", "seen"]
      if (root.account !== "") {
        cmd = [root.himalayaBin, "--account", root.account,
               "envelope", "list",
               "--folder", root.folder,
               "-o", "json",
               "--page-size", "50",
               "not", "flag", "seen"]
      }
      return cmd
    }

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        root.lastOutput += data
      }
    }

    onExited: (exitCode, exitStatus) => {
      root.loading = false
      Logger.i("HimalayaMail", "Panel fetch exited:", exitCode, "output length:", root.lastOutput.length)
      if (exitCode !== 0) {
        Logger.e("HimalayaMail", "Fetch failed with code:", exitCode, root.lastOutput)
        root.lastOutput = ""
        return
      }

      try {
        var data = JSON.parse(root.lastOutput)
        Logger.i("HimalayaMail", "Parsed", data.length, "envelopes")
        mailModel.clear()
        for (var i = 0; i < data.length; i++) {
          var env = data[i]
          var fromStr = "Unknown"
          if (env.from) {
            if (typeof env.from === "object") {
              fromStr = env.from.name || env.from.addr || "Unknown"
            } else {
              fromStr = String(env.from)
            }
          }
          var flagged = false
          if (env.flags) {
            for (var j = 0; j < env.flags.length; j++) {
              if (env.flags[j] === "Flagged") { flagged = true; break }
            }
          }
          mailModel.append({
            envelopeId: String(env.id || ""),
            subject: env.subject || "(no subject)",
            from: fromStr,
            date: env.date || "",
            flagged: flagged
          })
        }
      } catch (e) {
        Logger.e("HimalayaMail", "Failed to parse:", e, "raw:", root.lastOutput.substring(0, 200))
      }
      root.lastOutput = ""
    }
  }

  // Generic action process
  Process {
    id: actionProc
    property var cmdArgs: []
    property string actionName: ""
    property int removeIndex: -1
    command: cmdArgs
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        ToastService.showError(actionName + " failed")
        // Re-fetch on failure to restore correct state
        refreshList()
      }
    }
  }

  function refreshList() {
    if (root.loading) return
    root.loading = true
    root.lastOutput = ""
    fetchProc.running = true
  }

  function removeFromModel(id) {
    for (var i = 0; i < mailModel.count; i++) {
      if (mailModel.get(i).envelopeId === id) {
        mailModel.remove(i)
        updateBarCount()
        return
      }
    }
  }

  // Update the bar widget count file
  Process {
    id: countWriter
    property int count: 0
    command: ["sh", "-c", "echo " + count + " > /tmp/himalaya-mail-count"]
  }

  function updateBarCount() {
    countWriter.count = mailModel.count
    countWriter.running = true
  }

  function archiveMessage(id) {
    removeFromModel(id)
    var cmd = [root.himalayaBin, "message", "move",
               "--folder", root.folder, "Archive", id]
    if (root.account !== "") {
      cmd = [root.himalayaBin, "--account", root.account,
             "message", "move",
             "--folder", root.folder, "Archive", id]
    }
    actionProc.actionName = "Archive"
    actionProc.cmdArgs = cmd
    actionProc.running = true
  }

  function deleteMessage(id) {
    removeFromModel(id)
    var cmd = [root.himalayaBin, "message", "delete",
               "--folder", root.folder, id]
    if (root.account !== "") {
      cmd = [root.himalayaBin, "--account", root.account,
             "message", "delete",
             "--folder", root.folder, id]
    }
    actionProc.actionName = "Delete"
    actionProc.cmdArgs = cmd
    actionProc.running = true
  }

  // Flag toggle process
  Process {
    id: flagProc
    property var cmdArgs: []
    command: cmdArgs
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        ToastService.showError("Flag toggle failed")
      }
    }
  }

  function toggleFlag(id, index, currentlyFlagged) {
    var action = currentlyFlagged ? "remove" : "add"
    var cmd = [root.himalayaBin, "flag", action,
               "--folder", root.folder, id, "flagged"]
    if (root.account !== "") {
      cmd = [root.himalayaBin, "--account", root.account,
             "flag", action,
             "--folder", root.folder, id, "flagged"]
    }
    mailModel.setProperty(index, "flagged", !currentlyFlagged)
    flagProc.cmdArgs = cmd
    flagProc.running = true
  }

  // Open message in browser
  Process {
    id: openProc
    property string msgId: ""
    command: {
      var him = root.himalayaBin
      var acct = root.account !== "" ? ("--account " + root.account + " ") : ""
      var script = him + " " + acct + "message read --folder " + root.folder + " --no-headers --preview " + msgId +
        " | sed 's/&/\\&amp;/g;s/</\\&lt;/g;s/>/\\&gt;/g'" +
        " | { echo \"<html><head><meta charset='utf-8'><style>body{font-family:sans-serif;max-width:800px;margin:2em auto;padding:0 1em;line-height:1.6;white-space:pre-wrap;color:#222;background:#fafafa}</style></head><body>\"; cat; echo '</body></html>'; }" +
        " > /tmp/himalaya-mail-view.html && xdg-open /tmp/himalaya-mail-view.html"
      return ["sh", "-c", script]
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        Logger.e("HimalayaMail", "Failed to open message:", exitCode)
        ToastService.showError("Failed to open message")
      }
    }
  }

  function openMessage(id) {
    openProc.msgId = id
    openProc.running = true
  }

  function markAsRead(id) {
    removeFromModel(id)
    var cmd = [root.himalayaBin, "flag", "add",
               "--folder", root.folder, id, "seen"]
    if (root.account !== "") {
      cmd = [root.himalayaBin, "--account", root.account,
             "flag", "add",
             "--folder", root.folder, id, "seen"]
    }
    actionProc.actionName = "Mark as read"
    actionProc.cmdArgs = cmd
    actionProc.running = true
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginL
      }
      spacing: Style.marginL

      // Header
      RowLayout {
        Layout.fillWidth: true

        NIcon {
          icon: "mail"
          color: Color.mPrimary
        }

        NText {
          text: "Unread Mail (" + mailModel.count + ")"
          pointSize: Style.fontSizeL
          font.weight: Font.Bold
          color: Color.mOnSurface
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "refresh"
          onClicked: refreshList()
        }
      }

      // Empty state
      NText {
        visible: !root.loading && mailModel.count === 0
        text: "No unread mail"
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeM
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Style.marginL
      }

      // Mail list
      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: mailColumn.implicitHeight
        clip: true
        visible: mailModel.count > 0
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: mailColumn
          width: parent.width
          spacing: Style.marginS

          Repeater {
            model: mailModel

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: contentCol.implicitHeight + Style.marginM * 2
              color: delegateMouseArea.containsMouse ? Color.mHover : Color.mSurface
              radius: Style.radiusM

              MouseArea {
                id: delegateMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: openMessage(model.envelopeId)
              }

              RowLayout {
                anchors {
                  fill: parent
                  margins: Style.marginM
                }
                spacing: Style.marginM

                ColumnLayout {
                  id: contentCol
                  Layout.fillWidth: true
                  spacing: Style.marginXS

                  NText {
                    text: model.subject
                    pointSize: Style.fontSizeM
                    font.weight: Font.Medium
                    color: Color.mOnSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }

                  RowLayout {
                    spacing: Style.marginS

                    NText {
                      text: model.from
                      pointSize: Style.fontSizeS
                      color: Color.mPrimary
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                      Layout.maximumWidth: 250
                    }

                    NText {
                      text: model.date
                      pointSize: Style.fontSizeS
                      color: Color.mOnSurfaceVariant
                    }
                  }
                }

                // Action buttons
                RowLayout {
                  spacing: Style.marginXS

                  NIconButton {
                    icon: model.flagged ? "star-filled" : "star"
                    tooltipText: model.flagged ? "Unflag" : "Flag"
                    onClicked: toggleFlag(model.envelopeId, model.index, model.flagged)
                  }

                  NIconButton {
                    icon: "eye"
                    tooltipText: "Mark as read"
                    onClicked: markAsRead(model.envelopeId)
                  }

                  NIconButton {
                    icon: "trash"
                    tooltipText: "Delete"
                    onClicked: deleteMessage(model.envelopeId)
                  }

                  NIconButton {
                    icon: "archive"
                    tooltipText: "Archive"
                    onClicked: archiveMessage(model.envelopeId)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // Read cache file
  Process {
    id: cacheReadProc
    command: ["cat", "/tmp/himalaya-mail-cache.json"]
    property string output: ""

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        cacheReadProc.output += data
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && cacheReadProc.output.length > 0) {
        try {
          var data = JSON.parse(cacheReadProc.output)
          Logger.i("HimalayaMail", "Loaded", data.length, "envelopes from cache")
          populateModel(data)
        } catch (e) {
          Logger.e("HimalayaMail", "Cache parse error:", e)
          refreshList()
        }
      } else {
        refreshList()
      }
      cacheReadProc.output = ""
    }
  }

  function populateModel(data) {
    mailModel.clear()
    for (var i = 0; i < data.length; i++) {
      var env = data[i]
      var fromStr = "Unknown"
      if (env.from) {
        if (typeof env.from === "object") {
          fromStr = env.from.name || env.from.addr || "Unknown"
        } else {
          fromStr = String(env.from)
        }
      }
      var flagged = false
      if (env.flags) {
        for (var j = 0; j < env.flags.length; j++) {
          if (env.flags[j] === "Flagged") { flagged = true; break }
        }
      }
      mailModel.append({
        envelopeId: String(env.id || ""),
        subject: env.subject || "(no subject)",
        from: fromStr,
        date: env.date || "",
        flagged: flagged
      })
    }
  }

  Component.onCompleted: {
    cacheReadProc.running = true
  }
}

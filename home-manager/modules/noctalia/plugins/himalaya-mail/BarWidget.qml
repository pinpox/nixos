import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Per-screen bar properties
  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Settings
  readonly property string folder:
    pluginApi?.pluginSettings?.folder ||
    pluginApi?.manifest?.metadata?.defaultSettings?.folder ||
    "INBOX"
  readonly property int pollIntervalSec:
    pluginApi?.pluginSettings?.pollIntervalSec ||
    pluginApi?.manifest?.metadata?.defaultSettings?.pollIntervalSec ||
    60
  readonly property string himalayaBin:
    pluginApi?.pluginSettings?.himalayaBin ||
    pluginApi?.manifest?.metadata?.defaultSettings?.himalayaBin ||
    "himalaya"
  readonly property string account:
    pluginApi?.pluginSettings?.account || ""

  // State
  property int unreadCount: 0
  property bool loading: false
  property bool hasError: false
  property string lastOutput: ""


  readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  // Visual capsule
  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: "mail"
        color: root.hasError ? Color.mError :
               root.unreadCount > 0 ? Color.mPrimary :
               Color.mOnSurface
      }

      NText {
        text: root.hasError ? "!" :
              root.loading ? "…" :
              root.unreadCount.toString()
        color: root.hasError ? Color.mError :
               root.unreadCount > 0 ? Color.mPrimary :
               Color.mOnSurface
        pointSize: barFontSize
        font.weight: root.unreadCount > 0 ? Font.Bold : Font.Normal
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen, root)
      }
    }
    onEntered: {
      var tip = root.unreadCount + " unread in " + root.folder
      if (root.hasError) tip = "Error fetching mail — click to retry"
      TooltipService.show(root, tip, BarService.getTooltipDirection())
    }
    onExited: {
      TooltipService.hide()
    }
  }

  // Poll timer
  Timer {
    id: pollTimer
    interval: root.pollIntervalSec * 1000
    repeat: true
    running: true
    onTriggered: fetchMail()
  }

  // Watch for count updates from panel
  Timer {
    interval: 500
    repeat: true
    running: true
    onTriggered: countReader.running = true
  }

  Process {
    id: countReader
    command: ["cat", "/tmp/himalaya-mail-count"]
    property string output: ""
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => { countReader.output += data }
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && countReader.output.trim().length > 0) {
        var n = parseInt(countReader.output.trim())
        if (!isNaN(n) && n !== root.unreadCount) {
          root.unreadCount = n
        }
      }
      countReader.output = ""
    }
  }

  // Process to run himalaya
  Process {
    id: himalayaProc
    command: {
      var bin = root.himalayaBin
      var acct = root.account !== "" ? ("--account " + root.account + " ") : ""
      var sh = bin + " " + acct + "envelope list --folder " + root.folder +
               " -o json --page-size 9999 not flag seen"
      return ["sh", "-c", sh + " > /tmp/himalaya-mail-cache.json && cat /tmp/himalaya-mail-cache.json"]
    }

    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        root.lastOutput += data
      }
    }

    onExited: (exitCode, exitStatus) => {
      root.loading = false
      if (exitCode !== 0) {
        root.hasError = true
        Logger.e("HimalayaMail", "himalaya exited with code:", exitCode)
        root.lastOutput = ""
        return
      }

      try {
        var envelopes = JSON.parse(root.lastOutput)
        root.unreadCount = envelopes.length
        root.hasError = false
        Logger.i("HimalayaMail", "Unread count:", envelopes.length)
        // Sync count file
        countWriter.running = true

      } catch (e) {
        Logger.e("HimalayaMail", "Failed to parse JSON:", e, root.lastOutput.substring(0, 200))
        root.hasError = true
      }
      root.lastOutput = ""
    }
  }



  Process {
    id: countWriter
    command: ["sh", "-c", "echo " + root.unreadCount + " > /tmp/himalaya-mail-count"]
  }

  function fetchMail() {
    if (root.loading) return
    root.loading = true
    root.lastOutput = ""
    himalayaProc.running = true
  }

  Component.onCompleted: {
    Logger.i("HimalayaMail", "Widget loaded, polling every", root.pollIntervalSec, "seconds")
    fetchMail()
  }
}

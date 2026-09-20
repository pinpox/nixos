import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  property real contentPreferredWidth: 500 * Style.uiScaleRatio
  property real contentPreferredHeight: 300 * Style.uiScaleRatio

  anchors.fill: parent

  // Find the Main.qml instance to access state
  readonly property var mainInstance: pluginApi?.mainInstance ?? null
  readonly property string prompt: mainInstance?.currentPrompt ?? "Enter password"
  readonly property string caller: mainInstance?.currentCaller ?? ""

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

      // Header with lock icon
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "lock"
          color: Color.mPrimary
          pointSize: Style.fontSizeXL
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          NText {
            text: root.prompt
            pointSize: Style.fontSizeL
            font.weight: Font.Bold
            color: Color.mOnSurface
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          NText {
            visible: root.caller !== ""
            text: "Requested by: " + root.caller
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
        }
      }

      // PIN input
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: pinInput.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mPrimary
        border.width: Math.max(1, Math.round(2 * Style.uiScaleRatio))

        TextInput {
          id: pinInput
          anchors {
            fill: parent
            margins: Style.marginM
          }
          color: Color.mOnSurface
          font.pixelSize: Style.fontSizeL * 1.5
          font.family: Settings.data.ui.fontFixed
          echoMode: TextInput.Password
          passwordCharacter: "●"
          focus: true
          verticalAlignment: TextInput.AlignVCenter

          Keys.onReturnPressed: submitFromInput()
          Keys.onEnterPressed: submitFromInput()
          Keys.onEscapePressed: cancelFromInput()
        }
      }

      // Buttons
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Item { Layout.fillWidth: true }

        NButton {
          text: "Cancel"
          outlined: true
          onClicked: cancelFromInput()
        }

        NButton {
          text: "Unlock"
          icon: "lock-open"
          onClicked: submitFromInput()
        }
      }
    }
  }

  function submitFromInput() {
    var pin = pinInput.text
    if (pin === "") return
    pinInput.text = ""
    if (root.mainInstance) {
      root.mainInstance.submitPin(pin)
    }
  }

  function cancelFromInput() {
    pinInput.text = ""
    if (root.mainInstance) {
      root.mainInstance.cancelPin()
    }
  }

  Component.onCompleted: {
    pinInput.forceActiveFocus()
  }
}

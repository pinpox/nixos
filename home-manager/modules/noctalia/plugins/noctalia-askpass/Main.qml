import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  property var pluginApi: null

  // State shared with the panel
  property string currentPrompt: ""
  property string currentCaller: ""
  property string currentFifo: ""
  property bool pinRequested: false

  IpcHandler {
    target: "plugin:noctalia-askpass"

    function prompt(promptText: string, caller: string, fifoPath: string) {
      Logger.i("Askpass", "Password requested:", promptText, "caller:", caller, "fifo:", fifoPath)
      currentPrompt = promptText || "Enter password"
      currentCaller = caller || ""
      currentFifo = fifoPath || ""
      pinRequested = true

      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.openPanel(screen)
        })
      }
    }
  }

  // Write PIN to the FIFO
  Process {
    id: pinWriter
    property string pin: ""
    property string fifo: ""
    command: ["sh", "-c", "printf '%s' '" + pin.replace(/'/g, "'\\''") + "' > '" + fifo + "'"]
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        Logger.e("Askpass", "Failed to write password to FIFO")
      }
      pinWriter.pin = ""
    }
  }

  // Write empty to FIFO on cancel
  Process {
    id: cancelWriter
    property string fifo: ""
    command: ["sh", "-c", "printf '' > '" + fifo + "'"]
  }

  function submitPin(pin) {
    if (currentFifo === "") return
    pinWriter.pin = pin
    pinWriter.fifo = currentFifo
    pinWriter.running = true
    pinRequested = false
    currentFifo = ""
    currentPrompt = ""
    currentCaller = ""

    if (pluginApi) {
      pluginApi.withCurrentScreen(screen => {
        pluginApi.closePanel(screen)
      })
    }
  }

  function cancelPin() {
    if (currentFifo !== "") {
      cancelWriter.fifo = currentFifo
      cancelWriter.running = true
    }
    pinRequested = false
    currentFifo = ""
    currentPrompt = ""
    currentCaller = ""

    if (pluginApi) {
      pluginApi.withCurrentScreen(screen => {
        pluginApi.closePanel(screen)
      })
    }
  }
}

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace("file://", "")
  readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy/claude-launcher.json"

  readonly property var models: ["fable", "opus", "sonnet", "haiku"]
  readonly property var efforts: ["default", "low", "medium", "high", "xhigh", "max"]

  property bool opened: false
  property int modelIndex: 1
  property int effortIndex: 0
  property var profiles: []
  property var recents: []
  property string currentDir: ""
  // Slot 0 is the active terminal's folder, slots 1-5 are the recent folders.
  property int folderIndex: 0
  readonly property var folders: [root.currentDir].concat(root.recents.filter(function(d) { return d !== root.currentDir }).slice(0, 5))
  readonly property string recentPath: Quickshell.env("HOME") + "/.local/state/claude-launcher/recent"

  // Shares the [menu] surface tokens, so any theme that styles the menu styles this.
  property color background: Commons.Color.menu.background
  property color foreground: Commons.Color.menu.text
  property color border: Commons.Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Commons.Color.menu.scrim
  property color selectedBackground: Commons.Color.menu.selectedBackground
  property color selectedText: Commons.Color.menu.selectedText
  property string fontFamily: Style.font.menuFamily

  // Resolve the terminal's folder before the overlay takes focus.
  function open(payloadJson) {
    root.folderIndex = 0
    cwdProc.running = true
  }

  function show() {
    root.opened = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function tilde(path) {
    var home = Quickshell.env("HOME")
    return path.indexOf(home) === 0 ? "~" + path.slice(home.length) : path
  }

  function pickFolder(i) {
    if (i >= 0 && i < root.folders.length) root.folderIndex = i
  }

  function browse() {
    var args = ["omarchy-launch-tui", "--app-id=org.omarchy.claude-pick-dir", root.pluginDir + "bin/claude-pick-dir", root.models[root.modelIndex], root.efforts[root.effortIndex]]
    root.dismiss()
    Quickshell.execDetached(args)
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "flintspark.claude-launcher")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function rotate(index, list, delta) {
    return (index + delta + list.length) % list.length
  }

  function launch() {
    var args = [root.pluginDir + "bin/claude-launch", "--dir", root.folders[root.folderIndex], root.models[root.modelIndex], root.efforts[root.effortIndex]]
    root.dismiss()
    Quickshell.execDetached(args)
  }

  function launchProfile(i) {
    if (i < 0 || i >= root.profiles.length) return
    var args = [root.pluginDir + "bin/claude-launch", "--dir", root.folders[root.folderIndex], "--profile", root.profiles[i].name]
    root.dismiss()
    Quickshell.execDetached(args)
  }

  FileView {
    path: root.configPath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try { root.profiles = JSON.parse(text()).profiles || [] } catch (e) { root.profiles = [] }
    }
    onLoadFailed: root.profiles = []
    onFileChanged: reload()
  }

  Process {
    id: cwdProc
    command: ["omarchy-cmd-terminal-cwd"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { root.currentDir = text.trim(); root.show() }
    }
  }

  FileView {
    path: root.recentPath
    watchChanges: true
    printErrors: false
    onLoaded: root.recents = text().split("\n").filter(function(l) { return l })
    onLoadFailed: root.recents = []
    onFileChanged: reload()
  }

  component Chip: Rectangle {
    property string label
    property bool active
    implicitWidth: chipText.implicitWidth + Style.spacing.md * 2
    implicitHeight: chipText.implicitHeight + Style.spacing.controlPaddingY * 2
    radius: Style.cornerRadius
    color: active ? root.selectedBackground : "transparent"
    Text {
      id: chipText
      anchors.centerIn: parent
      text: parent.label
      textFormat: Text.PlainText
      color: parent.active ? root.selectedText : root.foreground
      opacity: parent.active ? 1 : 0.6
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-claude-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle { anchors.fill: parent; color: root.scrim }
    MouseArea { anchors.fill: parent; onClicked: root.dismiss() }

    BorderSurface {
      id: card
      width: Math.min(Style.space(520), panel.width - Style.gapsOut * 2)
      height: content.implicitHeight + Style.spacing.panelPadding * 2
      anchors.centerIn: parent
      radius: Style.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      padding: Style.spacing.panelPadding

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          var k = event.key
          if (event.modifiers & Qt.AltModifier) {
            if (k === Qt.Key_0) root.pickFolder(0)
            else if (k >= Qt.Key_1 && k <= Qt.Key_5) root.pickFolder(k - Qt.Key_0)
            else return
          }
          else if (k === Qt.Key_BracketRight || k === Qt.Key_PageDown) root.folderIndex = root.rotate(root.folderIndex, root.folders, 1)
          else if (k === Qt.Key_BracketLeft || k === Qt.Key_PageUp) root.folderIndex = root.rotate(root.folderIndex, root.folders, -1)
          else if (k === Qt.Key_B) root.browse()
          else if (k === Qt.Key_Escape) root.dismiss()
          else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.launch()
          else if (k === Qt.Key_Right || k === Qt.Key_Tab || k === Qt.Key_L) root.modelIndex = root.rotate(root.modelIndex, root.models, 1)
          else if (k === Qt.Key_Left || k === Qt.Key_Backtab || k === Qt.Key_H) root.modelIndex = root.rotate(root.modelIndex, root.models, -1)
          else if (k === Qt.Key_Down || k === Qt.Key_J) root.effortIndex = root.rotate(root.effortIndex, root.efforts, 1)
          else if (k === Qt.Key_Up || k === Qt.Key_K) root.effortIndex = root.rotate(root.effortIndex, root.efforts, -1)
          else if (k >= Qt.Key_1 && k <= Qt.Key_9) root.launchProfile(k - Qt.Key_1)
          else return
          event.accepted = true
        }
      }

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.padding
        spacing: Style.spacing.md

        Text {
          text: "Claude Launcher"
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
        }
        Row {
          spacing: Style.spacing.sm
          Repeater { model: root.models; Chip { label: modelData; active: index === root.modelIndex } }
        }
        Row {
          spacing: Style.spacing.sm
          Repeater { model: root.efforts; Chip { label: modelData; active: index === root.effortIndex } }
        }
        Column {
          Repeater {
            model: root.folders
            Text {
              textFormat: Text.PlainText
              elide: Text.ElideMiddle
              width: content.width
              color: index === root.folderIndex ? root.selectedText : root.foreground
              opacity: index === root.folderIndex ? 1 : 0.6
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              text: (index === 0 ? "alt+0 " : "alt+" + index + " ") + root.tilde(modelData) + (index === 0 ? "  (terminal)" : "")
            }
          }
        }
        Repeater {
          model: root.profiles.slice(0, 9)
          Text {
            textFormat: Text.PlainText
            color: root.foreground
            opacity: 0.8
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            text: (index + 1) + "  " + modelData.name + "  ·  " + modelData.model + " / " + (modelData.effort || "default")
          }
        }
        Text {
          textFormat: Text.PlainText
          color: root.foreground
          opacity: 0.45
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          text: "←/→ model  ↑/↓ thinking  [ ] folder  b browse  ⏎ launch  1-9 profile"
        }
      }
    }
  }
}

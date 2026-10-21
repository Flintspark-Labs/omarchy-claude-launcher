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

  // Shares the [menu] surface tokens, so any theme that styles the menu styles this.
  property color background: Commons.Color.menu.background
  property color foreground: Commons.Color.menu.text
  property color border: Commons.Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Commons.Color.menu.scrim
  property color selectedBackground: Commons.Color.menu.selectedBackground
  property color selectedText: Commons.Color.menu.selectedText
  property string fontFamily: Style.font.menuFamily

  function open(payloadJson) {
    root.opened = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "rexsilex.claude-launcher")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function rotate(index, list, delta) {
    return (index + delta + list.length) % list.length
  }

  function launch() {
    var args = [root.pluginDir + "bin/claude-launch", root.models[root.modelIndex], root.efforts[root.effortIndex]]
    root.dismiss()
    Quickshell.execDetached(args)
  }

  function launchProfile(i) {
    if (i < 0 || i >= root.profiles.length) return
    var args = [root.pluginDir + "bin/claude-launch", "--profile", root.profiles[i].name]
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
          if (k === Qt.Key_Escape) root.dismiss()
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
          text: "←/→ model   ↑/↓ thinking   ⏎ launch   1-9 profile   esc close"
        }
      }
    }
  }
}

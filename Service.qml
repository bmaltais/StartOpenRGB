// StartOpenRGB: set the colour of the machine's RGB lights, from the Omarchy shell. Everything it
// does goes through bin/startopenrgb (the QML never runs openrgb itself); this file owns the window
// and the IPC entry points.
//
//   omarchy-shell io.github.bmaltais.startopenrgb open            toggle the window
//   omarchy-shell io.github.bmaltais.startopenrgb color RRGGBB    set every light
//   omarchy-shell io.github.bmaltais.startopenrgb off             turn every light off
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

Item {
  id: root

  // Injected by omarchy-shell (the plugin service loader).
  property var shell: null

  readonly property string cli: Qt.resolvedUrl("bin/startopenrgb").toString().replace("file://", "")
  readonly property int radius: Math.max(Style.cornerRadius, Style.space(10))
  readonly property var presets: ["ff0000", "ff8000", "ffff00", "00ff00", "00ffff", "0000ff", "8000ff", "ff00ff", "ffffff", "000000"]

  property bool shown: false
  property bool installed: true
  property bool stateKnown: false
  property var devices: []
  property string color: ""
  // What the last command said, shown under the swatches: a failure is red.
  property string note: ""
  property bool noteError: false
  property bool busy: false

  function focusedScreen() {
    var monitor = Hyprland.focusedMonitor
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++) {
      if (monitor && screens[i].name === monitor.name) return screens[i]
    }
    return screens.length ? screens[0] : null
  }
  function show() { win.screen = root.focusedScreen(); root.note = ""; root.shown = true; root.refresh() }
  function close() { root.shown = false }
  function refresh() { stateProc.running = true }

  // One command at a time, in order, so a quick second click is never dropped.
  property var queue: []
  function run(args, doneNote) {
    root.queue = root.queue.concat([{ args: args, note: doneNote || "" }])
    root.next()
  }
  function next() {
    if (cmd.running || root.queue.length === 0) return
    var item = root.queue[0]
    root.queue = root.queue.slice(1)
    cmd.last = ""
    cmd.doneNote = item.note
    root.busy = true
    cmd.command = [root.cli].concat(item.args)
    cmd.running = true
  }
  function setColor(hex, device) {
    var args = ["color", hex]
    if (device !== undefined) args.push(String(device))
    root.run(args, hex === "000000" ? "Lights off" : "Set to #" + hex)
  }

  IpcHandler {
    target: "io.github.bmaltais.startopenrgb"
    function open(): void { if (root.shown) root.close(); else root.show() }
    function toggle(): void { if (root.shown) root.close(); else root.show() }
    function close(): void { root.close() }
    function color(hex: string): string { root.setColor(hex.replace("#", "")); return "ok" }
    function off(): string { root.setColor("000000"); return "ok" }
    function state(): string { return JSON.stringify({ shown: root.shown, installed: root.installed, devices: root.devices, color: root.color }) }
  }

  Process {
    id: stateProc
    command: [root.cli, "state"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var s = JSON.parse(text)
          root.installed = s.installed
          root.stateKnown = true
          root.devices = s.devices
          root.color = s.color
        } catch (e) { console.log("startopenrgb state:", e) }
      }
    }
  }

  Process {
    id: cmd
    property string last: ""
    property string doneNote: ""
    stderr: SplitParser { onRead: line => { if (cmd.last === "") cmd.last = line } }
    onExited: (code, status) => {
      root.busy = false
      root.noteError = code !== 0
      root.note = code === 0 ? cmd.doneNote : (cmd.last !== "" ? cmd.last : "Failed (exit code " + code + ")")
      console.log("startopenrgb", JSON.stringify(cmd.command), "exited", code)
      root.refresh()
      root.next()
    }
  }

  // While the window is open, look again every few seconds: lights turn up as OpenRGB finishes probing, and the install
  // (it runs in a terminal of its own) finishes by itself.
  Timer { interval: 4000; repeat: true; running: root.shown; onTriggered: root.refresh() }

  // OpenRGB's server, kept running for as long as the shell is: it probes the hardware once so every other call is fast, and
  // `serve` puts the saved colour back at login once the lights have turned up.
  Process { running: root.stateKnown && root.installed; command: [root.cli, "serve"] }
  Component.onCompleted: root.refresh()

  PanelWindow {
    id: win
    visible: root.shown
    color: "transparent"
    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omarchy-startopenrgb"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Dimmed scrim: a click outside the card closes it.
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.35) }
    MouseArea { anchors.fill: parent; onClicked: root.close() }

    Rectangle {
      id: frame
      anchors.centerIn: parent
      width: Style.space(520)
      height: col.implicitHeight + Style.spacing.panelPadding * 2
      radius: root.radius
      color: Color.menu.background
      border.width: Style.normalBorderWidth
      border.color: Util.alpha(Color.foreground, 0.14)
      focus: true
      Keys.onEscapePressed: root.close()

      // Swallow clicks so they do not reach the scrim behind the card.
      MouseArea { anchors.fill: parent }

      ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        spacing: Style.spacing.panelGap

        ColumnLayout {
          spacing: 0
          Text {
            text: "StartOpenRGB"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.bold: true
          }
          Text {
            text: !root.installed ? "OPENRGB NOT INSTALLED"
              : root.devices.length === 0 ? "NO LIGHTS FOUND"
              : root.devices.length + (root.devices.length === 1 ? " DEVICE" : " DEVICES")
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
          }
        }

        // OpenRGB is missing: one button installs it.
        ColumnLayout {
          visible: !root.installed
          Layout.fillWidth: true
          spacing: Style.spacing.panelGap
          Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "StartOpenRGB drives your lights through OpenRGB, which is not on this machine yet."
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
          }
          Button {
            text: "Install OpenRGB"
            enabled: !root.busy
            onClicked: root.run(["install"], "Installing in a terminal: type your password there")
          }
        }

        // The colours.
        ColumnLayout {
          visible: root.installed
          Layout.fillWidth: true
          spacing: Style.spacing.panelGap

          Flow {
            Layout.fillWidth: true
            spacing: Style.space(8)
            Repeater {
              model: root.presets
              Rectangle {
                required property string modelData
                width: Style.space(36)
                height: Style.space(36)
                radius: Style.space(8)
                color: "#" + modelData
                border.width: root.color === modelData ? Style.space(3) : Style.normalBorderWidth
                border.color: root.color === modelData ? Color.accent : Util.alpha(Color.foreground, 0.3)
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.setColor(modelData)
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)
            Rectangle {
              Layout.fillWidth: true
              height: Style.space(34)
              radius: Style.space(8)
              color: Util.alpha(Color.foreground, 0.06)
              border.width: Style.normalBorderWidth
              border.color: hex.activeFocus ? Color.accent : Util.alpha(Color.foreground, 0.14)
              TextInput {
                id: hex
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                verticalAlignment: TextInput.AlignVCenter
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                maximumLength: 7
                selectByMouse: true
                onAccepted: if (/^#?[0-9a-fA-F]{6}$/.test(text)) root.setColor(text.replace("#", ""))
                Text {
                  visible: hex.text === "" && !hex.activeFocus
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Any colour: RRGGBB, then Enter"
                  color: Color.muted
                  font: hex.font
                }
              }
            }
            Button {
              text: "Lights off"
              onClicked: root.setColor("000000")
            }
          }

          Text {
            visible: root.note !== ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: root.note
            color: root.noteError ? Color.urgent : Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }

          // What OpenRGB found.
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(2)
            Repeater {
              model: root.devices
              Text {
                required property var modelData
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: modelData.name
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        Text {
          text: root.installed ? "The colour comes back at login · Esc to close" : "Esc to close"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Button {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Style.space(8)
        iconText: ""
        tooltipText: "Close  (Esc)"
        onClicked: root.close()
      }
    }
  }
}

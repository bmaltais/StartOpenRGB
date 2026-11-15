// The optional bar icon: a light bulb that opens the StartOpenRGB window.
import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.bmaltais.startopenrgb"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌵"
    onPressed: function (mouse) {
      if (!root.bar) return
      if (mouse === Qt.RightButton) root.bar.run("omarchy-shell io.github.bmaltais.startopenrgb off")
      else root.bar.run("omarchy-shell io.github.bmaltais.startopenrgb open")
    }
  }
}

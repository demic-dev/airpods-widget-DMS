import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

// Orientation changes layout only; icon, battery text and decoration stay shared.
StyledRect {
    id: root
    required property var controller
    property bool vertical: false
    property bool showBattery: true
    property real iconSize: Theme.iconSize
    property real thickness: 30
    // DMS BasePill owns the button background, padding and interaction states.
    // This component supplies content only, for either orientation/format.
    implicitWidth: vertical ? thickness : content.implicitWidth
    implicitHeight: vertical ? content.implicitHeight : thickness
    color: "transparent"
    border.width: 0

    GridLayout {
        id: content
        anchors.centerIn: parent
        columns: root.vertical ? 1 : 2
        rowSpacing: 1
        columnSpacing: Theme.spacingXS

        DankIcon {
            Layout.alignment: Qt.AlignCenter
            name: root.controller.deviceIcon
            filled: root.controller.connected
            size: root.iconSize
            color: root.controller.connected ? Theme.primary : Theme.surfaceVariantText
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            visible: root.showBattery && (!root.vertical || root.controller.lowestLevel >= 0)
            text: root.controller.connected && root.controller.lowestLevel >= 0
                ? root.controller.lowestLevel + (root.vertical ? "" : "%")
                : (root.controller.connected ? "On" : "-")
            font.pixelSize: root.vertical ? Theme.fontSizeSmall : Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: root.controller.connected ? Theme.primary : Theme.surfaceVariantText
        }
    }
}

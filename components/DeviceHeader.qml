import QtQuick
import qs.Common
import qs.Widgets

Row {
    id: root
    required property var controller

    height: 48
    spacing: Theme.spacingM

    Rectangle {
        width: 46
        height: 46
        radius: 14
        color: Theme.primary
        anchors.verticalCenter: parent.verticalCenter

        DankIcon {
            anchors.centerIn: parent
            name: root.controller.deviceIcon
            filled: true
            size: Theme.iconSizeLarge - 6
            color: Theme.primaryText
        }
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, parent.width - 46 - Theme.spacingM)
        text: root.controller.deviceName
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.DemiBold
        color: Theme.surfaceText
        elide: Text.ElideRight
    }
}

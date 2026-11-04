import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root
    property int level: -1

    implicitHeight: Theme.iconSizeLarge * 3 + Theme.spacingL * 2
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh

    Rectangle {
        id: iconBackground
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingL
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.iconSizeLarge * 2 + Theme.spacingM
        height: width
        radius: width / 2
        color: Theme.withAlpha(Theme.primary, 0.12)

        DankIcon {
            anchors.centerIn: parent
            name: "headphones"
            filled: true
            size: Theme.iconSizeLarge * 2
            color: Theme.primary
        }
    }

    Column {
        anchors.left: iconBackground.right
        anchors.leftMargin: Theme.spacingL
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingL
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXS

        StyledText {
            text: "AirPods Max"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: Theme.surfaceVariantText
        }

        StyledText {
            text: root.level >= 0 ? root.level + "%" : "—"
            font.pixelSize: Theme.fontSizeLarge * 2
            font.weight: Font.DemiBold
            color: root.level >= 0 && root.level <= 20 ? Theme.warning : Theme.surfaceText
        }

        Rectangle {
            width: parent.width
            height: Theme.spacingXS
            radius: height / 2
            color: Theme.withAlpha(Theme.primary, 0.15)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root.level)) / 100
                height: parent.height
                radius: parent.radius
                color: root.level <= 20 ? Theme.warning : Theme.primary
                Behavior on width {
                    NumberAnimation { duration: Theme.shortDuration; easing.type: Easing.OutCubic }
                }
            }
        }

        StyledText {
            width: parent.width
            text: root.level >= 0 ? "Battery" : "Waiting for battery status"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
        }
    }
}

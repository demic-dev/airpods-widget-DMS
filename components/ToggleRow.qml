import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    signal toggled(bool value)

    implicitHeight: Math.max(56, labels.implicitHeight + Theme.spacingS * 2)

    Row {
        anchors.left: parent.left
        anchors.right: toggle.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingXS
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingM

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            filled: root.checked && root.enabled
            size: Theme.iconSize - 2
            color: filled ? Theme.primary : Theme.surfaceVariantText
        }

        Column {
            id: labels
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - (Theme.iconSize - 2) - Theme.spacingM)
            spacing: 1

            StyledText {
                width: parent.width
                text: root.title
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                elide: Text.ElideRight
            }

            StyledText {
                width: parent.width
                text: root.subtitle
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }
    }

    DankToggle {
        id: toggle
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        hideText: true
        checked: root.checked
        enabled: root.enabled
        onToggled: value => root.toggled(value)
    }
}

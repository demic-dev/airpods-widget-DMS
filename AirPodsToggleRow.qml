import QtQuick
import qs.Common
import qs.Widgets

// A settings-style row: leading icon, title + subtitle, trailing switch.
Item {
    id: row

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false

    signal toggled(bool value)

    implicitHeight: 56

    Row {
        anchors.left: parent.left
        anchors.right: toggle.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingXS
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingM

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: row.icon
            filled: row.checked && row.enabled
            size: Theme.iconSize - 2
            color: row.checked && row.enabled ? Theme.primary : Theme.surfaceVariantText
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (Theme.iconSize - 2) - Theme.spacingM
            spacing: 1

            StyledText {
                text: row.title
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                elide: Text.ElideRight
                width: parent.width
            }

            StyledText {
                text: row.subtitle
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }

    DankToggle {
        id: toggle
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        hideText: true
        checked: row.checked
        enabled: row.enabled
        onToggled: value => row.toggled(value)
    }
}

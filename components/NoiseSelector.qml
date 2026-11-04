import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root
    required property var controller
    readonly property int modeCount: modes.count

    spacing: Theme.spacingS

    StyledText {
        text: "NOISE CONTROL"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        font.letterSpacing: 0.5
        color: Theme.surfaceVariantText
    }

    Rectangle {
        width: parent.width
        height: 68
        radius: 18
        color: Theme.surfaceContainerHigh

        Row {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 4

            Repeater {
                id: modes
                model: root.controller.noiseModes

                delegate: Rectangle {
                    id: segment
                    required property var modelData
                    readonly property bool selected: root.controller.mode === modelData.id
                    width: (parent.width - parent.spacing * (modes.count - 1)) / Math.max(1, modes.count)
                    height: parent.height
                    radius: 14
                    color: selected ? Theme.primaryContainer : (area.containsMouse && root.controller.connected ? Theme.surfaceContainerHighest : "transparent")

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        DankIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: segment.modelData.icon
                            filled: segment.selected
                            size: Theme.iconSize - 2
                            color: segment.selected ? Theme.primary : Theme.surfaceVariantText
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: segment.modelData.label
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: segment.selected ? Theme.primary : Theme.surfaceVariantText
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.controller.connected
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.controller.setNoise(segment.modelData.id)
                    }
                }
            }
        }
    }
}

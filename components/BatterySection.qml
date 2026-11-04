import QtQuick
import qs.Common
import qs.Widgets

Loader {
    id: root
    required property var controller

    sourceComponent: controller.isHeadset ? headset : earbuds

    Component {
        id: headset
        HeadsetBattery { level: root.controller.batHeadset }
    }

    Component {
        id: earbuds
        Row {
            spacing: Theme.spacingS

            Repeater {
                model: [
                    { name: "Left", level: root.controller.batLeft, charging: false },
                    { name: "Right", level: root.controller.batRight, charging: false },
                    { name: "Case", level: root.controller.batCase, charging: root.controller.batCase >= 100 }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - Theme.spacingS * 2) / 3
                    height: 108
                    radius: 16
                    color: Theme.surfaceContainerHigh

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        BatteryRing {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 56
                            height: 56
                            level: modelData.level
                            charging: modelData.charging
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                    }
                }
            }
        }
    }
}

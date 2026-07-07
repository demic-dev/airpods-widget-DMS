import QtQuick
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

// Popout panel for the AirPods widget. `controller` is the AirPodsWidget that
// owns the live state and control functions.
PopoutComponent {
    id: pop

    property var controller

    headerText: "ciao"      // custom header below
    showCloseButton: false

    property bool renaming: false

    Column {
        width: parent.width
        spacing: Theme.spacingM

        // ---- header --------------------------------------------------------
        Item {
            width: parent.width
            height: 48

            Row {
                anchors.left: parent.left
                anchors.right: editBtn.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Theme.spacingS
                spacing: Theme.spacingM

                Rectangle {
                    width: 46
                    height: 46
                    radius: 14
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter

                    DankIcon {
                        anchors.centerIn: parent
                        name: "earbuds"
                        filled: true
                        size: Theme.iconSizeLarge - 6
                        color: Theme.primaryText
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 46 - Theme.spacingM
                    spacing: 2

                    Loader {
                        active: !pop.renaming
                        width: parent.width
                        sourceComponent: StyledText {
                            text: pop.controller.deviceName
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.DemiBold
                            color: Theme.surfaceText
                            elide: Text.ElideRight
                            width: parent ? parent.width : implicitWidth
                        }
                    }

                    Loader {
                        active: pop.renaming
                        width: parent.width
                        sourceComponent: DankTextField {
                            width: parent ? parent.width : 200
                            text: pop.controller.deviceName
                            Component.onCompleted: forceActiveFocus()
                            onAccepted: {
                                pop.controller.rename(text)
                                pop.renaming = false
                            }
                            Keys.onEscapePressed: pop.renaming = false
                        }
                    }

                    Row {
                        spacing: Theme.spacingXS
                        visible: !pop.renaming

                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            anchors.verticalCenter: parent.verticalCenter
                            color: pop.controller.connected ? Theme.success : Theme.surfaceVariantText
                        }

                        StyledText {
                            text: pop.controller.connected ? "Connected · LibrePods" : "Disconnected"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }
                }
            }

            Rectangle {
                id: editBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                radius: 11
                color: editArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                DankIcon {
                    anchors.centerIn: parent
                    name: pop.renaming ? "close" : "edit"
                    size: Theme.iconSize - 6
                    color: Theme.surfaceVariantText
                }

                MouseArea {
                    id: editArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pop.renaming = !pop.renaming
                }
            }
        }

        // ---- battery -------------------------------------------------------
        Row {
            width: parent.width
            spacing: Theme.spacingS

            // buds model: Left / Right / Case
            Repeater {
                model: pop.controller.model === "headset" ? [] : [
                    { name: "Left", level: pop.controller.batLeft, charging: false },
                    { name: "Right", level: pop.controller.batRight, charging: false },
                    { name: "Case", level: pop.controller.batCase, charging: pop.controller.batCase >= 0 && pop.controller.batCase >= 100 }
                ]

                delegate: Rectangle {
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

            // headset model: single ring
            Loader {
                active: pop.controller.model === "headset"
                width: parent.width
                sourceComponent: Rectangle {
                    height: 108
                    radius: 16
                    color: Theme.surfaceContainerHigh

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingM

                        BatteryRing {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 56
                            height: 56
                            level: pop.controller.batHeadset
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Headset"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                    }
                }
            }
        }

        // ---- noise control -------------------------------------------------
        Column {
            width: parent.width
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
                        model: [
                            { id: "off", icon: "block", label: "Off" },
                            { id: "transparency", icon: "noise_aware", label: "Transparency" },
                            { id: "adaptive", icon: "auto_mode", label: "Adaptive" },
                            { id: "anc", icon: "noise_control_on", label: "Noise" }
                        ]

                        delegate: Rectangle {
                            readonly property bool selected: pop.controller.mode === modelData.id
                            width: (parent.width - 4 * 3) / 4
                            height: parent.height
                            radius: 14
                            color: selected ? Theme.primaryContainer : (segArea.containsMouse && pop.controller.connected ? Theme.surfaceContainerHighest : "transparent")

                            Column {
                                anchors.centerIn: parent
                                spacing: 3

                                DankIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: modelData.icon
                                    filled: parent.parent.selected
                                    size: Theme.iconSize - 2
                                    color: parent.parent.selected ? Theme.primary : Theme.surfaceVariantText
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: parent.parent.selected ? Theme.primary : Theme.surfaceVariantText
                                }
                            }

                            MouseArea {
                                id: segArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: pop.controller.connected
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pop.controller.setNoise(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // ---- toggles -------------------------------------------------------
        Column {
            width: parent.width
            spacing: 0

            AirPodsToggleRow {
                width: parent.width
                icon: "record_voice_over"
                title: "Conversation Awareness"
                subtitle: "Lowers volume when you start talking"
                checked: pop.controller.conversation
                enabled: pop.controller.connected
                onToggled: pop.controller.toggleConversation()
            }

            Rectangle {
                width: parent.width - Theme.spacingS * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
                color: Theme.outline
                opacity: 0.5
            }

            AirPodsToggleRow {
                width: parent.width
                icon: "hearing"
                title: "Automatic Ear Detection"
                subtitle: "Pause audio when a bud is removed"
                checked: pop.controller.earDetection
                onToggled: pop.controller.setEarDetection(value)
            }
        }

        // ---- footer --------------------------------------------------------
        Rectangle {
            width: parent.width
            height: 40
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingM
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "info"
                    size: Theme.iconSizeSmall
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: pop.controller.connected ? ("LibrePods · " + pop.controller.modeLabel) : "Waiting for LibrePods"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}


import QtQuick
import qs.Common
import qs.Widgets

// The same content is used by the bar popout and Control Center detail.
Column {
    id: root
    required property var controller

    spacing: Theme.spacingM

    DeviceHeader {
        width: parent.width
        controller: root.controller
    }

    BatterySection {
        width: parent.width
        controller: root.controller
    }

    NoiseSelector {
        width: parent.width
        controller: root.controller
    }

    Column {
        width: parent.width

        ToggleRow {
            visible: !root.controller.isHeadset
            width: parent.width
            icon: "record_voice_over"
            title: "Conversation Awareness"
            subtitle: "Lowers volume when you speak · set in LibrePods"
            checked: root.controller.conversation
            enabled: root.controller.connected
            onToggled: root.controller.conversationInfo()
        }

        Rectangle {
            visible: !root.controller.isHeadset
            width: parent.width - Theme.spacingS * 2
            anchors.horizontalCenter: parent.horizontalCenter
            height: 1
            color: Theme.outline
            opacity: 0.5
        }

        ToggleRow {
            width: parent.width
            icon: root.controller.deviceIcon
            title: root.controller.isHeadset ? "Automatic Head Detection" : "Automatic Ear Detection"
            subtitle: root.controller.isHeadset ? "Pause audio when you take off your headphones" : "Pause audio when a bud is removed"
            checked: root.controller.earDetection
            enabled: root.controller.connected
            onToggled: value => root.controller.setEarDetection(value)
        }
    }
}

import QtQuick
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins
import "components"
import "logic"
import "logic/State.js" as State

// DMS integration only: live state and presentation live in separate components.
PluginComponent {
    id: root

    property var popoutService: null
    readonly property string barVisibility: setting("barVisibility", "connected")
    readonly property string controlCenterVisibility: setting("controlCenterVisibility", "always")
    readonly property bool barVisible: State.isVisible(barVisibility, airpods.connected)
    // Exposed for hosts supporting per-surface visibility (see integrations/).
    readonly property bool ccWidgetVisible: State.isVisible(controlCenterVisibility, airpods.connected)
    onBarVisibleChanged: root.setVisibilityOverride(barVisible)
    readonly property bool showBatteryInBar: setting("barDisplay", "battery") !== "icon"
    readonly property real barIconSize: showBatteryInBar ? root.iconSize
        : Theme.barIconSize(root.barThickness, -4, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)

    function setting(key, fallback) {
        return pluginData[key] === undefined
            ? SettingsData.getPluginSetting("librepods", key, fallback) : pluginData[key];
    }

    AirPodsController {
        id: airpods
        pollInterval: State.pollInterval(root.setting("pollInterval", ""),
            SettingsData.getPluginSetting("airpods", "pollInterval", "5"))
        // CC detail instances can have neither pluginService nor pluginId.
        // Resolve from this entry point so its nested controller works there too.
        scriptPath: {
            var base = root.pluginService && root.pluginId ? root.pluginService.getPluginPath(root.pluginId) : "";
            return base ? base + "/scripts/librepods-bridge.sh"
                : Qt.resolvedUrl("scripts/librepods-bridge.sh").toString().replace(/^file:\/\//, "").replace(/\?.*$/, "");
        }
    }

    Component.onCompleted: root.setVisibilityOverride(barVisible)

    popoutWidth: 380
    popoutHeight: 480
    popoutContent: Component {
        PopoutComponent {
            headerText: ""
            showCloseButton: true

            AirPodsPanel {
                width: parent.width
                controller: airpods
            }
        }
    }

    horizontalBarPill: Component {
        BarPill {
            controller: airpods
            showBattery: root.showBatteryInBar
            iconSize: root.barIconSize
            thickness: root.widgetThickness
        }
    }

    verticalBarPill: Component {
        BarPill {
            controller: airpods
            vertical: true
            showBattery: root.showBatteryInBar
            iconSize: root.barIconSize
            thickness: root.widgetThickness
        }
    }

    ccWidgetIcon: airpods.deviceIcon
    ccWidgetPrimaryText: airpods.deviceName
    ccWidgetSecondaryText: airpods.connected
        ? airpods.modeLabel + (airpods.lowestLevel >= 0 ? " · " + airpods.lowestLevel + "%" : "")
        : "Disconnected"
    ccWidgetIsActive: airpods.connected && airpods.mode !== "off" && airpods.mode !== "unknown"
    ccDetailHeight: 440 // Initial estimate, replaced by the measured panel height.
    onCcWidgetToggled: airpods.cycleAncTransparency()

    ccDetailContent: Component {
        Rectangle {
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            AirPodsPanel {
                id: detailPanel
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacingM
                controller: airpods

                Binding {
                    target: root
                    property: "ccDetailHeight"
                    value: detailPanel.implicitHeight + Theme.spacingM * 2
                }
            }
        }
    }
}

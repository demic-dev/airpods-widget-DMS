import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "librepods"

    SelectionSetting {
        settingKey: "barVisibility"
        label: "Bar visibility"
        description: "Show the bar widget all the time or only while AirPods are connected."
        options: [
            { label: "Only when connected", value: "connected" },
            { label: "Always", value: "always" }
        ]
        defaultValue: "connected"
    }

    SelectionSetting {
        settingKey: "controlCenterVisibility"
        label: "Control Center visibility"
        description: "Independent of the bar. Hiding disconnected tiles requires the DMS integration described in the README."
        options: [
            { label: "Always", value: "always" },
            { label: "Only when connected", value: "connected" }
        ]
        defaultValue: "always"
    }

    SelectionSetting {
        settingKey: "barDisplay"
        label: "Bar appearance"
        description: "Choose a battery readout or a compact icon without text."
        options: [
            { label: "Icon + battery percentage", value: "battery" },
            { label: "Minimal icon", value: "icon" }
        ]
        defaultValue: "battery"
    }

    SelectionSetting {
        settingKey: "pollInterval"
        label: "Refresh interval"
        description: "How often to poll LibrePods for battery and status."
        options: [
            { label: "1 second", value: "1" },
            { label: "2 seconds", value: "2" },
            { label: "5 seconds", value: "5" },
            { label: "10 seconds", value: "10" },
            { label: "30 seconds", value: "30" }
        ]
        // Preserve refresh intervals saved by the old settings page ID.
        defaultValue: String(SettingsData.getPluginSetting("airpods", "pollInterval", "5"))
    }
}

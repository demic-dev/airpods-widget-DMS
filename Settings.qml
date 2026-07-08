import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "airpods"

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
        defaultValue: "2"
    }
}

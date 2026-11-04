pragma Singleton
import QtQuick

QtObject {
    property var settings: ({})
    function getPluginSetting(plugin, key, fallback) {
        var value = (settings[plugin] || ({}))[key];
        return value === undefined ? fallback : value;
    }
}

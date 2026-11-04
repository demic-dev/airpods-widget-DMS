pragma Singleton
import QtQuick

QtObject {
    property var globalVars: ({})
    function setGlobalVar(id, key, value) {
        var store = Object.assign({}, globalVars[id] || ({}));
        store[key] = value;
        var next = Object.assign({}, globalVars);
        next[id] = store;
        globalVars = next;
    }
}

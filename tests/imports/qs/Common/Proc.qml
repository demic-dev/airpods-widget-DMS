pragma Singleton
import QtQuick

QtObject {
    property var calls: []
    property var status: ({ connected: true, model: "headset", headset: 85, mode: "transparency" })
    property int exitCode: 0

    function runCommand(id, args, callback, debounce, timeout) {
        calls = calls.concat([{ id: id, args: args }]);
        callback(args[2] === "status" ? JSON.stringify(status) : "", exitCode);
    }
}

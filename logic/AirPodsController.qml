import QtQuick
import qs.Common
import qs.Services
import "State.js" as State

// Each DMS surface owns a controller, but all of them publish to one shared store.
Item {
    id: root

    property string scriptPath: ""
    property int pollInterval: 5
    readonly property string storeId: "airpods_state"
    readonly property string procTag: "airpods_" + Math.floor(Math.random() * 1e9)
    readonly property var shared: PluginService.globalVars[storeId]?.state || ({})
    readonly property var locks: PluginService.globalVars[storeId]?.locks || ({})

    readonly property bool connected: shared.connected === true
    readonly property bool isHeadset: shared.model === "headset"
    readonly property string deviceIcon: isHeadset ? "headphones" : "earbuds"
    readonly property string deviceName: shared.deviceName || "AirPods"
    readonly property int batLeft: shared.left === undefined ? -1 : shared.left
    readonly property int batRight: shared.right === undefined ? -1 : shared.right
    readonly property int batCase: shared.case === undefined ? -1 : shared.case
    readonly property int batHeadset: shared.headset === undefined ? -1 : shared.headset
    readonly property int lowestLevel: State.lowestBattery(shared)
    readonly property string mode: shared.mode || "unknown"
    readonly property bool conversation: shared.conversation === true
    readonly property bool earDetection: shared.earDetection === true
    readonly property var modeInfo: ({
        off: { icon: "block", label: "Off" },
        transparency: { icon: "noise_aware", label: "Transparency" },
        adaptive: { icon: "auto_mode", label: "Adaptive" },
        anc: { icon: "noise_control_on", label: "Noise Cancellation" },
        unknown: { icon: deviceIcon, label: "-" }
    })
    readonly property var modeOrder: isHeadset ? ["off", "transparency", "anc"] : ["off", "transparency", "adaptive", "anc"]
    readonly property string modeLabel: (modeInfo[mode] || modeInfo.unknown).label
    readonly property var noiseModes: modeOrder.map(function (id) {
        return { id: id, icon: root.modeInfo[id].icon, label: id === "anc" ? "ANC" : root.modeInfo[id].label };
    })

    function publish(result) {
        var next = State.reconcile(result, locks, Date.now());
        if (!State.same(shared, next.state))
            PluginService.setGlobalVar(storeId, "state", next.state);
        PluginService.setGlobalVar(storeId, "locks", next.locks);
    }

    function optimisticSet(field, value) {
        var next = State.optimistic(shared, locks, field, value, Date.now(), 4000);
        PluginService.setGlobalVar(storeId, "state", next.state);
        PluginService.setGlobalVar(storeId, "locks", next.locks);
    }

    function refresh() {
        if (!scriptPath)
            return;
        // Unique command IDs prevent concurrent surfaces replacing each other's callbacks.
        Proc.runCommand(procTag + "_status", ["bash", scriptPath, "status"], function (out, code) {
            try {
                if (code !== 0 || !out)
                    throw new Error("Bridge status unavailable");
                root.publish(State.normalize(JSON.parse(out.trim()), root.deviceName));
            } catch (error) {
                // A callback may outlive its QML instance after a plugin reload.
                try {
                    root.publish(State.normalize({}, root.deviceName));
                } catch (destroyed) {}
            }
        }, 0, 6000);
    }

    // All writes share execution and delayed confirmation; the UI remains optimistic.
    function command(action, args, field, value, message) {
        if (!scriptPath)
            return;
        optimisticSet(field, value);
        Proc.runCommand(procTag + "_" + action, ["bash", scriptPath, action].concat(args), function (out, code) {
            try {
                if (code !== 0)
                    ToastService.showInfo("LibrePods command failed; check that LibrePods is running");
                else if (message)
                    ToastService.showInfo(message);
                refreshSoon.restart();
            } catch (destroyed) {}
        }, 0, 6000);
    }

    function setNoise(mode) {
        if (connected && modeOrder.indexOf(mode) >= 0)
            command("noise", [mode], "mode", mode, "");
    }

    function cycleAncTransparency() {
        setNoise(mode === "anc" ? "transparency" : "anc");
    }

    function conversationInfo() {
        ToastService.showInfo("Conversation Awareness is set in the LibrePods app");
    }

    function setEarDetection(on) {
        command("eardetection", [on ? "on" : "off"], "earDetection", on,
                (isHeadset ? "Head" : "Ear") + " detection " + (on ? "enabled" : "disabled") + " - reconnect AirPods to apply");
    }

    function rename(name) {
        if (name && name.length)
            command("rename", [name], "deviceName", name, "Renamed - reconnect AirPods to apply");
    }

    Component.onCompleted: refresh()

    Timer {
        interval: Math.max(1, root.pollInterval) * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // LibrePods' tray state can lag hardware by 1–2 seconds.
    Timer {
        id: refreshSoon
        interval: 2500
        onTriggered: root.refresh()
    }
}

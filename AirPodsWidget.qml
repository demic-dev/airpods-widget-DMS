import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

// AirPods widget for DankMaterialShell.
//
// This is the controller: it polls the LibrePods bridge for live state, exposes
// that state as reactive properties, and provides the control functions used by
// the bar pill, the popout (AirPodsPopout.qml) and the Control Center tile.
PluginComponent {
    id: root

    property var popoutService: null

    // ---- live state (fed by the bridge) -----------------------------------
    property bool connected: false
    property string model: "buds"          // "buds" | "headset"
    property int batLeft: -1
    property int batRight: -1
    property int batCase: -1
    property int batHeadset: -1
    property string mode: "unknown"        // off | transparency | adaptive | anc | unknown
    property bool conversation: false
    property bool earDetection: false
    property string deviceName: "AirPods"
    property bool ready: false             // first poll completed

    // ---- static metadata ---------------------------------------------------
    readonly property var modeInfo: ({
            "off": { icon: "block", label: "Off" },
            "transparency": { icon: "noise_aware", label: "Transparency" },
            "adaptive": { icon: "auto_mode", label: "Adaptive" },
            "anc": { icon: "noise_control_on", label: "Noise Cancellation" },
            "unknown": { icon: "earbuds", label: "—" }
        })
    readonly property var modeOrder: ["off", "transparency", "adaptive", "anc"]

    readonly property string modeLabel: (modeInfo[mode] || modeInfo["unknown"]).label
    readonly property string modeIcon: (modeInfo[mode] || modeInfo["unknown"]).icon

    // Lowest available bud level, used for the compact bar/CC readouts.
    readonly property int lowestLevel: {
        if (model === "headset")
            return batHeadset
        var vals = []
        if (batLeft >= 0)
            vals.push(batLeft)
        if (batRight >= 0)
            vals.push(batRight)
        return vals.length ? Math.min.apply(Math, vals) : -1
    }

    readonly property string scriptPath: (pluginService ? pluginService.getPluginPath(pluginId) : ".") + "/scripts/librepods-bridge.sh"
    readonly property int pollInterval: (pluginData && pluginData.pollInterval) ? parseInt(pluginData.pollInterval) : 5

    // ---- data plumbing -----------------------------------------------------
    function refresh() {
        if (!pluginService)
            return
        Proc.runCommand("airpods.status", ["bash", scriptPath, "status"], function (out, code) {
            root.ready = true
            if (code !== 0 || !out) {
                root.connected = false
                return
            }
            try {
                var s = JSON.parse(out.trim())
                root.connected = !!s.connected
                root.model = s.model || "buds"
                root.batLeft = s.left
                root.batRight = s.right
                root.batCase = s.case
                root.batHeadset = s.headset
                root.mode = s.mode || "unknown"
                root.conversation = !!s.conversation
                root.earDetection = !!s.earDetection
                if (s.deviceName)
                    root.deviceName = s.deviceName
            } catch (e) {
                root.connected = false
            }
        }, 0, 6000)
    }

    // ---- control -----------------------------------------------------------
    function setNoise(id) {
        if (!pluginService || modeOrder.indexOf(id) < 0)
            return
        root.mode = id // optimistic
        Proc.runCommand("airpods.noise", ["bash", scriptPath, "noise", id], function () {
            refreshSoon.restart()
        }, 0, 6000)
    }

    function cycleAncTransparency() {
        setNoise(mode === "anc" ? "transparency" : "anc")
    }

    function toggleConversation() {
        if (!pluginService)
            return
        root.conversation = !root.conversation // optimistic
        Proc.runCommand("airpods.conversation", ["bash", scriptPath, "conversation"], function () {
            refreshSoon.restart()
        }, 0, 6000)
    }

    function setEarDetection(on) {
        if (!pluginService)
            return
        root.earDetection = on // optimistic
        Proc.runCommand("airpods.eardetection", ["bash", scriptPath, "eardetection", on ? "on" : "off"], function () {
            ToastService?.showInfo("Ear detection " + (on ? "enabled" : "disabled") + " — reconnect AirPods to apply")
        }, 0, 6000)
    }

    function rename(name) {
        if (!pluginService || !name || !name.length)
            return
        root.deviceName = name // optimistic
        Proc.runCommand("airpods.rename", ["bash", scriptPath, "rename", name], function () {
            ToastService?.showInfo("Renamed — reconnect AirPods to apply")
            refreshSoon.restart()
        }, 0, 6000)
    }

    Component.onCompleted: refresh()

    Timer {
        interval: root.pollInterval * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // Debounced re-poll shortly after issuing a control command.
    Timer {
        id: refreshSoon
        interval: 400
        repeat: false
        onTriggered: root.refresh()
    }

    // ---- popout ------------------------------------------------------------
    popoutWidth: 380
    popoutHeight: 560

    popoutContent: Component {
        AirPodsPopout {
            controller: root
        }
    }

    // ---- bar pills ---------------------------------------------------------
    horizontalBarPill: Component {
        StyledRect {
            implicitWidth: pillRow.implicitWidth + Theme.spacingM * 2
            height: parent.widgetThickness
            radius: Theme.cornerRadius
            color: root.connected ? Theme.primaryContainer : Theme.surfaceContainerHigh
            border.width: root.conversation ? 2 : 0
            border.color: Theme.primary

            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "earbuds"
                    filled: root.connected
                    size: root.iconSize
                    color: root.connected ? Theme.primary : Theme.surfaceVariantText
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.connected && root.lowestLevel >= 0 ? root.lowestLevel + "%" : (root.connected ? "On" : "—")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: root.connected ? Theme.primary : Theme.surfaceVariantText
                }
            }
        }
    }

    verticalBarPill: Component {
        StyledRect {
            width: parent.widgetThickness
            implicitHeight: pillCol.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: root.connected ? Theme.primaryContainer : Theme.surfaceContainerHigh
            border.width: root.conversation ? 2 : 0
            border.color: Theme.primary

            Column {
                id: pillCol
                anchors.centerIn: parent
                spacing: 1

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "earbuds"
                    filled: root.connected
                    size: root.iconSize
                    color: root.connected ? Theme.primary : Theme.surfaceVariantText
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.connected && root.lowestLevel >= 0 ? root.lowestLevel : ""
                    visible: text.length > 0
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
            }
        }
    }

    // ---- Control Center tile ----------------------------------------------
    ccWidgetIcon: "earbuds"
    ccWidgetPrimaryText: root.deviceName
    ccWidgetSecondaryText: root.connected ? (root.modeLabel + (root.lowestLevel >= 0 ? " · " + root.lowestLevel + "%" : "")) : "Disconnected"
    ccWidgetIsActive: root.connected && root.mode !== "off"

    onCcWidgetToggled: {
        if (root.connected)
            root.cycleAncTransparency()
    }
}


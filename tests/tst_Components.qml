import QtQuick
import QtTest
import qs.Common
import qs.Services
import "../logic"
import "../components"
import ".."

TestCase {
    id: tests
    name: "Components"
    when: windowShown
    width: 800
    height: 800

    Component { id: controllerFactory; AirPodsController {} }
    Component { id: widgetFactory; AirPodsWidget {} }
    Component { id: panelFactory; AirPodsPanel { width: 380 } }
    Component { id: pillFactory; BarPill {} }
    Component { id: selectorFactory; NoiseSelector { width: 380 } }
    Component { id: settingsFactory; Settings {} }

    function init() {
        PluginService.globalVars = ({});
        Proc.calls = [];
        Proc.exitCode = 0;
        Proc.status = { connected: true, model: "headset", headset: 85, mode: "transparency" };
        ToastService.message = "";
        SettingsData.settings = ({});
    }

    function state(status) { PluginService.setGlobalVar("airpods_state", "state", status); }

    function test_sharedController() {
        var first = createTemporaryObject(controllerFactory, tests);
        var second = createTemporaryObject(controllerFactory, tests);
        state(Proc.status);
        compare(first.deviceIcon, "headphones");
        compare(first.lowestLevel, 85);
        first.optimisticSet("mode", "anc");
        compare(second.mode, "anc");
        second.publish(Proc.status);
        compare(first.mode, "anc");
        verify(first.procTag !== second.procTag);
    }

    function test_noiseCapabilities() {
        var controller = createTemporaryObject(controllerFactory, tests, { scriptPath: "/bridge.sh" });
        var selector = createTemporaryObject(selectorFactory, tests, { controller: controller });
        compare(selector.modeCount, 3);
        Proc.calls = [];
        controller.setNoise("adaptive");
        compare(Proc.calls.length, 0);
        controller.setNoise("anc");
        compare(Proc.calls[0].args, ["bash", "/bridge.sh", "noise", "anc"]);
        compare(controller.mode, "anc");
        state({ connected: true, model: "buds", left: 50, right: 80 });
        compare(selector.modeCount, 4);
        controller.setNoise("adaptive");
        compare(controller.mode, "adaptive");
    }

    function test_panelHeight() {
        var controller = createTemporaryObject(controllerFactory, tests);
        state(Proc.status);
        var panel = createTemporaryObject(panelFactory, tests, { controller: controller });
        verify(panel);
        wait(50);
        var maxHeight = panel.implicitHeight;
        verify(maxHeight > 200);
        state({ connected: true, model: "buds", left: 80, right: 70, case: 50 });
        wait(50);
        verify(panel.implicitHeight > maxHeight);
        state(Proc.status);
        tryCompare(panel, "implicitHeight", maxHeight);
        panel.destroy();
        wait(0);
    }

    function test_barOrientation_data() {
        return [
            { tag: "horizontal-battery", vertical: false, battery: true },
            { tag: "horizontal-icon", vertical: false, battery: false },
            { tag: "vertical-battery", vertical: true, battery: true },
            { tag: "vertical-icon", vertical: true, battery: false }
        ];
    }

    function test_barOrientation(data) {
        var controller = createTemporaryObject(controllerFactory, tests);
        state(Proc.status);
        var pill = createTemporaryObject(pillFactory, tests, {
            controller: controller, vertical: data.vertical, showBattery: data.battery, iconSize: 20
        });
        wait(0);
        verify(pill.implicitWidth > 0);
        verify(pill.implicitHeight > 0);
        if (!data.battery)
            compare(data.vertical ? pill.implicitHeight : pill.implicitWidth, 20);
    }

    function test_entryPointAndDetail() {
        var widget = createTemporaryObject(widgetFactory, tests);
        verify(widget);
        compare(widget.ccWidgetIcon, "headphones");
        var detail = createTemporaryObject(widget.ccDetailContent, tests, { width: 500 });
        verify(detail);
        wait(0);
        verify(widget.ccDetailHeight > 200);
        verify(widget.ccDetailHeight < 440);
        verify(Proc.calls[0].args[1].endsWith("/scripts/librepods-bridge.sh"));
        var pill = createTemporaryObject(widget.horizontalBarPill, tests);
        verify(pill);
        var vertical = createTemporaryObject(widget.verticalBarPill, tests);
        verify(vertical);
        var popout = createTemporaryObject(widget.popoutContent, tests, { width: 380 });
        verify(popout);
        state({ connected: false });
        compare(widget.effectiveVisible, false);
        compare(widget.ccWidgetIsActive, false);
    }

    function test_bridgeFailure() {
        Proc.exitCode = 1;
        var controller = createTemporaryObject(controllerFactory, tests, { scriptPath: "/bridge.sh" });
        compare(controller.connected, false);
        state(Proc.status);
        controller.setNoise("anc");
        verify(ToastService.message.indexOf("failed") >= 0);
    }

    function test_independentVisibility() {
        var widget = createTemporaryObject(widgetFactory, tests);
        state({ connected: false });
        compare(widget.barVisible, false);
        compare(widget.ccWidgetVisible, true);
        widget.pluginData = { barVisibility: "always", controlCenterVisibility: "connected" };
        compare(widget.effectiveVisible, true);
        compare(widget.ccWidgetVisible, false);
        state({ connected: true });
        compare(widget.ccWidgetVisible, true);
        widget.pluginData = { barVisibility: "connected", controlCenterVisibility: "always" };
        state({ connected: false });
        compare(widget.effectiveVisible, false);
        compare(widget.ccWidgetVisible, true);
    }

    function test_settingsWithoutPluginService() {
        SettingsData.settings = { librepods: { barVisibility: "always", barDisplay: "icon", pollInterval: "2" } };
        var widget = createTemporaryObject(widgetFactory, tests);
        state({ connected: false });
        compare(widget.effectiveVisible, true);
        compare(widget.showBatteryInBar, false);
        compare(widget.setting("pollInterval", "5"), "2");
        widget.pluginData = { barDisplay: "battery" };
        compare(widget.showBatteryInBar, true);
    }

    function test_settingsPage() {
        var page = createTemporaryObject(settingsFactory, tests);
        verify(page);
        compare(page.pluginId, "librepods");
        var defaults = {};
        for (var i = 0; i < page.data.length; i++)
            defaults[page.data[i].settingKey] = page.data[i].defaultValue;
        compare(defaults.barVisibility, "connected");
        compare(defaults.controlCenterVisibility, "always");
        compare(defaults.barDisplay, "battery");
        compare(defaults.pollInterval, "5");
    }
}

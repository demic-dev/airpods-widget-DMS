import QtQuick
import QtTest
import "../logic/State.js" as State

TestCase {
    name: "State"

    function test_normalizeDefaults() {
        var state = State.normalize({}, "AirPods");
        compare(state.ready, true);
        compare(state.connected, false);
        compare(state.left, -1);
        compare(state.right, -1);
        compare(state.case, -1);
        compare(state.headset, -1);
        compare(state.mode, "unknown");
        compare(state.deviceName, "AirPods");
    }

    function test_lowestBattery_data() {
        return [
            { tag: "missing", state: {}, expected: -1 },
            { tag: "buds", state: { left: 80, right: 60, case: 10 }, expected: 60 },
            { tag: "one-bud", state: { left: -1, right: 42 }, expected: 42 },
            { tag: "empty", state: { left: 0, right: 50 }, expected: 0 },
            { tag: "max", state: { model: "headset", headset: 85, left: 20 }, expected: 85 },
            { tag: "max-missing", state: { model: "headset" }, expected: -1 }
        ];
    }

    function test_lowestBattery(data) { compare(State.lowestBattery(data.state), data.expected); }

    function test_reconcile_data() {
        return [
            { tag: "stale", mode: "off", connected: true, now: 10, expected: "anc", locked: true },
            { tag: "confirmed", mode: "anc", connected: true, now: 10, expected: "anc", locked: false },
            { tag: "expired", mode: "off", connected: true, now: 100, expected: "off", locked: false },
            { tag: "disconnect", mode: "unknown", connected: false, now: 10, expected: "unknown", locked: false }
        ];
    }

    function test_reconcile(data) {
        var locks = { mode: { value: "anc", until: 100 } };
        var next = State.reconcile({ mode: data.mode, connected: data.connected }, locks, data.now);
        compare(next.state.mode, data.expected);
        compare(!!next.locks.mode, data.locked);
        verify(!!locks.mode); // Inputs are never mutated.
    }

    function test_optimistic() {
        var original = { mode: "off", headset: 85 };
        var next = State.optimistic(original, {}, "mode", "anc", 100, 4000);
        compare(next.state.mode, "anc");
        compare(next.state.headset, 85);
        compare(next.locks.mode.until, 4100);
        compare(original.mode, "off");
    }

    function test_sameState() {
        var state = State.normalize({ connected: true, headset: 85 }, "Max");
        verify(State.same(state, Object.assign({}, state)));
        State.fields.forEach(function (field) {
            var changed = Object.assign({}, state);
            changed[field] = "changed";
            verify(!State.same(state, changed), field);
        });
    }

    function test_pollInterval_data() {
        return [
            { tag: "new", value: "2", legacy: "30", expected: 2 },
            { tag: "legacy", value: undefined, legacy: "30", expected: 30 },
            { tag: "default", value: undefined, legacy: undefined, expected: 5 },
            { tag: "invalid", value: "abc", legacy: "30", expected: 5 },
            { tag: "negative", value: "-1", legacy: "30", expected: 5 },
            { tag: "zero", value: "0", legacy: "30", expected: 5 }
        ];
    }

    function test_pollInterval(data) { compare(State.pollInterval(data.value, data.legacy), data.expected); }

    function test_visibility_data() {
        return [
            { tag: "always-connected", policy: "always", connected: true, expected: true },
            { tag: "always-disconnected", policy: "always", connected: false, expected: true },
            { tag: "connected", policy: "connected", connected: true, expected: true },
            { tag: "disconnected", policy: "connected", connected: false, expected: false }
        ];
    }

    function test_visibility(data) { compare(State.isVisible(data.policy, data.connected), data.expected); }
}

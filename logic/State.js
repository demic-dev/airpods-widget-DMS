// Pure state operations: shared by controllers and covered without a live daemon.
var fields = ["ready", "connected", "model", "left", "right", "case", "headset",
              "mode", "conversation", "earDetection", "deviceName"];

function same(a, b) {
    return fields.every(function (key) { return a[key] === b[key]; });
}

function normalize(status, deviceName) {
    function battery(value) { return typeof value === "number" ? value : -1; }
    return {
        ready: true,
        connected: !!status.connected,
        model: status.model || "buds",
        left: battery(status.left),
        right: battery(status.right),
        case: battery(status.case),
        headset: battery(status.headset),
        mode: status.mode || "unknown",
        conversation: !!status.conversation,
        earDetection: !!status.earDetection,
        deviceName: status.deviceName || deviceName
    };
}

function optimistic(state, locks, field, value, now, duration) {
    var nextState = Object.assign({}, state);
    var nextLocks = Object.assign({}, locks);
    nextState[field] = value;
    nextLocks[field] = { value: value, until: now + duration };
    return { state: nextState, locks: nextLocks };
}

function reconcile(status, locks, now) {
    var nextState = Object.assign({}, status);
    var nextLocks = Object.assign({}, locks);
    Object.keys(locks).forEach(function (field) {
        var lock = locks[field];
        if (!lock)
            return;
        if (!status.connected || status[field] === lock.value || now >= lock.until)
            delete nextLocks[field];
        else
            nextState[field] = lock.value;
    });
    return { state: nextState, locks: nextLocks };
}

function lowestBattery(state) {
    if (state.model === "headset")
        return state.headset === undefined ? -1 : state.headset;
    var levels = [state.left, state.right].filter(function (level) {
        return typeof level === "number" && level >= 0;
    });
    return levels.length ? Math.min.apply(Math, levels) : -1;
}

function pollInterval(value, legacy) {
    var interval = parseInt(value || legacy || "5", 10);
    return interval > 0 ? interval : 5;
}

function isVisible(policy, connected) {
    return policy !== "connected" || connected;
}

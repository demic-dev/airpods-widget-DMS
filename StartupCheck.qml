import QtQuick
import qs.Common

// Blocks activation unless the LibrePods control CLI is installed.
QtObject {
    function check(done) {
        Proc.runCommand("airpods.depCheck", ["sh", "-c", "command -v librepods-ctl && command -v dbus-send"], function (stdout, exitCode) {
            if (exitCode === 0) {
                done(null)
                return
            }
            done({
                "title": "LibrePods is required",
                "details": "This plugin needs 'librepods-ctl' (from LibrePods) and 'dbus-send' on your PATH. Install LibrePods and re-enable the plugin."
            })
        })
    }
}

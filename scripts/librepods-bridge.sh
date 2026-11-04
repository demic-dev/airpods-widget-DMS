#!/usr/bin/env bash
#
# librepods-bridge.sh
# -------------------
# Bridge between the DankMaterialShell "AirPods" plugin and the LibrePods daemon.
#
# LibrePods (https://github.com/kavishdevar/librepods) does not expose a public
# read API, but the running daemon publishes everything the plugin needs through
# its system-tray StatusNotifierItem:
#
#   * battery (L / R / case, or a single headset level) -> tray ToolTip
#       "Battery Status: Left: 82%, Right: 79%, Case: 100%"
#   * current noise mode + conversation awareness        -> tray DBusMenu toggles
#   * device name + ear-detection setting                -> LibrePods config file
#
# Control is done through the shipped `librepods-ctl` CLI (noise modes) and the
# tray DBusMenu (conversation awareness toggle).
#
# Usage:
#   librepods-bridge.sh status                       # -> one line of JSON
#   librepods-bridge.sh noise off|transparency|adaptive|anc
#   librepods-bridge.sh conversation                 # toggles conversation awareness
#   librepods-bridge.sh eardetection on|off          # writes LibrePods config
#   librepods-bridge.sh rename <name>                # writes LibrePods config
#
# `eardetection` and `rename` write to LibrePods' own config file; LibrePods
# picks the change up when the AirPods next (re)connect. Everything else is live.
#
# Dependencies: dbus-send (from dbus), librepods-ctl (from librepods).

set -uo pipefail

SNI_WATCHER_DEST="org.kde.StatusNotifierWatcher"
SNI_WATCHER_PATH="/StatusNotifierWatcher"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/AirPodsTrayApp/AirPodsTrayApp.conf"

# --- helpers ---------------------------------------------------------------

# Locate the LibrePods StatusNotifierItem -> prints "SERVICE PATH" or nothing.
find_sni() {
    local reply entry service path id tooltip fallback=""
    reply=$(dbus-send --session --print-reply=literal \
        --dest="$SNI_WATCHER_DEST" "$SNI_WATCHER_PATH" \
        org.freedesktop.DBus.Properties.Get \
        string:"$SNI_WATCHER_DEST" string:RegisteredStatusNotifierItems 2>/dev/null) || return 1

    # Entries look like  ":1.89/StatusNotifierItem"  or  ":1.37/org/ayatana/..."
    for entry in $(echo "$reply" | grep -oE '(:[0-9]+\.[0-9]+|org\.[A-Za-z0-9._-]+)(/[A-Za-z0-9/_-]+)?'); do
        if [[ "$entry" == */* ]]; then
            service="${entry%%/*}"
            path="/${entry#*/}"
        else
            service="$entry"
            path="/StatusNotifierItem"
        fi
        # Literal reply looks like:  "   variant       librepods"  -> take last field.
        id=$(dbus-send --session --print-reply=literal --dest="$service" "$path" \
            org.freedesktop.DBus.Properties.Get \
            string:org.kde.StatusNotifierItem string:Id 2>/dev/null | awk 'NF{last=$NF} END{print last}')
        if [[ "$id" == "librepods" ]]; then
            # A second LibrePods process may register an empty tray item.
            # Prefer the instance actually reporting device battery data.
            [[ -z "$fallback" ]] && fallback="$service $path"
            tooltip=$(read_tooltip "$service" "$path")
            if grep -qiE '(Headset|Left):[[:space:]]*[0-9]+%' <<<"$tooltip"; then
                echo "$service $path"
                return 0
            fi
        fi
    done
    if [[ -n "$fallback" ]]; then
        echo "$fallback"
        return 0
    fi
    return 1
}

# Read the tray ToolTip for the given service/path (raw text, all fields).
read_tooltip() {
    local service="$1" path="$2"
    dbus-send --session --print-reply --dest="$service" "$path" \
        org.freedesktop.DBus.Properties.Get \
        string:org.kde.StatusNotifierItem string:ToolTip 2>/dev/null
}

# Read the DBusMenu layout (after asking it to refresh).
read_menu() {
    local service="$1"
    dbus-send --session --dest="$service" /MenuBar \
        com.canonical.dbusmenu.AboutToShow int32:0 >/dev/null 2>&1
    dbus-send --session --print-reply --dest="$service" /MenuBar \
        com.canonical.dbusmenu.GetLayout int32:0 int32:-1 array:string: 2>/dev/null
}

json_escape() { sed -E 's/\\/\\\\/g; s/"/\\"/g'; }

# Authoritative connection state, straight from BlueZ (org.bluez Device1.Connected).
# LibrePods leaves its tray ToolTip/menu stale after the buds go back in the case
# — it only refreshes on restart — so the tray is NOT a reliable "connected" signal.
# BlueZ flips immediately. We match the AirPods device by its Alias: first against
# LibrePods' configured deviceName, then any "AirPod" as a fallback.
# Prints "true" / "false", or nothing if the device/bus can't be found (caller then
# falls back to the tray heuristic rather than forcing a state).
bt_connected() {
    local want objs dev alias conn
    want=$(grep -E '^deviceName=' "$CONF" 2>/dev/null | head -1 | cut -d= -f2-)
    objs=$(dbus-send --system --print-reply --dest=org.bluez / \
        org.freedesktop.DBus.ObjectManager.GetManagedObjects 2>/dev/null) || return 1
    while read -r dev; do
        [[ -z "$dev" ]] && continue
        alias=$(dbus-send --system --print-reply=literal --dest=org.bluez "$dev" \
            org.freedesktop.DBus.Properties.Get \
            string:org.bluez.Device1 string:Alias 2>/dev/null \
            | tail -1 | sed -E 's/^[[:space:]]*variant[[:space:]]+string[[:space:]]+//')
        if { [[ -n "$want" ]] && [[ "$alias" == "$want" ]]; } || [[ "$alias" == *AirPod* ]]; then
            conn=$(dbus-send --system --print-reply=literal --dest=org.bluez "$dev" \
                org.freedesktop.DBus.Properties.Get \
                string:org.bluez.Device1 string:Connected 2>/dev/null \
                | tail -1 | awk '{print $NF}')
            [[ "$conn" == "true" || "$conn" == "false" ]] && { echo "$conn"; return 0; }
        fi
    done < <(grep -oE '/org/bluez/hci[0-9]+/dev_[0-9A-F_]+"' <<<"$objs" \
        | tr -d '"' | grep -vE '/(sep|fd)[0-9]' | sort -u)
    return 1
}

# --- commands --------------------------------------------------------------

cmd_status() {
    local sni service="" path="" tooltip="" menu=""
    local connected=false model="buds"
    local left=-1 right=-1 case=-1 headset=-1
    local mode="unknown" conversation=false
    local name=""

    # Authoritative connection state (empty => couldn't determine, fall back to tray).
    local bt
    bt=$(bt_connected) || bt=""

    sni=$(find_sni) && read -r service path <<<"$sni"

    if [[ -n "$service" ]]; then
        tooltip=$(read_tooltip "$service" "$path")
        menu=$(read_menu "$service")
    fi

    # Battery from the tooltip string.
    if [[ -n "$tooltip" ]]; then
        if grep -qiE 'Headset:[[:space:]]*[0-9]+%' <<<"$tooltip"; then
            model="headset"
            headset=$(grep -oiE 'Headset:[[:space:]]*[0-9]+' <<<"$tooltip" | grep -oE '[0-9]+' | head -1)
            connected=true
        elif grep -qiE 'Left:[[:space:]]*[0-9]+%' <<<"$tooltip"; then
            left=$(grep -oiE 'Left:[[:space:]]*[0-9]+'   <<<"$tooltip" | grep -oE '[0-9]+' | head -1)
            right=$(grep -oiE 'Right:[[:space:]]*[0-9]+' <<<"$tooltip" | grep -oE '[0-9]+' | head -1)
            case=$(grep -oiE 'Case:[[:space:]]*[0-9]+'   <<<"$tooltip" | grep -oE '[0-9]+' | head -1)
            connected=true
        fi
    fi

    # Noise mode + conversation awareness from the tray menu toggle states.
    if [[ -n "$menu" ]]; then
        local label="" state=""
        while IFS= read -r line; do
            if [[ "$line" == LABEL:* ]]; then
                label="${line#LABEL:}"
            elif [[ "$line" == STATE:* ]]; then
                state="${line#STATE:}"
                case "$label" in
                    "Off")                [[ "$state" == 1 ]] && mode="off" ;;
                    "Transparency")       [[ "$state" == 1 ]] && mode="transparency" ;;
                    "Adaptive")           [[ "$state" == 1 ]] && mode="adaptive" ;;
                    "Noise Cancellation") [[ "$state" == 1 ]] && mode="anc" ;;
                    "Toggle Conversational Awareness")
                        [[ "$state" == 1 ]] && conversation=true ;;
                esac
            fi
        done < <(echo "$menu" | grep -oE 'string "[^"]+"|int32 [0-9]+' | awk '
            /^string "label"/        { next }
            /^string "toggle-state"/ { expect_state=1; next }
            /^string "/              { gsub(/^string "|"$/,""); print "LABEL:" $0; next }
            /^int32/                 { if (expect_state) { print "STATE:" $2; expect_state=0 } }
        ')
        # If a menu exists we consider the device present even without battery yet.
        [[ "$mode" != "unknown" ]] && connected=true
    fi

    # Device name + ear-detection setting from the LibrePods config file.
    local eardetection=false ed_setting configured_model=""
    if [[ -f "$CONF" ]]; then
        name=$(grep -E '^deviceName=' "$CONF" | head -1 | cut -d= -f2-)
        configured_model=$(grep -E '^model=' "$CONF" | head -1 | cut -d= -f2-)
        ed_setting=$(grep -E '^setting=' "$CONF" | head -1 | cut -d= -f2-)
        # setting >= 1 => ear detection active (pause when a bud is removed).
        [[ "${ed_setting:-0}" =~ ^[0-9]+$ ]] && (( ed_setting >= 1 )) && eardetection=true
    fi
    [[ -z "$name" ]] && name="AirPods"

    # LibrePods 0.2.5: Max Lightning = 7, Max USB-C = 8. Battery data may
    # be temporarily unavailable, but that must not change the device layout.
    if [[ "$configured_model" == 7 || "$configured_model" == 8 || "$name" == *AirPods*Max* ]]; then
        model="headset"
    fi

    # BlueZ has the final say when it knows. On disconnect LibrePods' tray stays
    # stale, so we must actively clear the readouts rather than echo the old values.
    case "$bt" in
        true)  connected=true ;;
        false) connected=false
               left=-1; right=-1; case=-1; headset=-1
               mode="unknown"; conversation=false ;;
    esac

    printf '{"connected":%s,"model":"%s","left":%s,"right":%s,"case":%s,"headset":%s,"mode":"%s","conversation":%s,"earDetection":%s,"deviceName":"%s"}\n' \
        "$connected" "$model" "${left:--1}" "${right:--1}" "${case:--1}" "${headset:--1}" \
        "$mode" "$conversation" "$eardetection" "$(printf '%s' "$name" | json_escape)"
}

# Replace `key=value` under a QSettings ini, preserving the rest of the file.
_conf_set() {
    local key="$1" val="$2"
    [[ -f "$CONF" ]] || return 1
    if grep -qE "^${key}=" "$CONF"; then
        sed -i -E "s|^${key}=.*|${key}=${val//|/\\|}|" "$CONF"
    else
        printf '%s=%s\n' "$key" "$val" >>"$CONF"
    fi
}

cmd_eardetection() {
    case "${1:-}" in
        on)  _conf_set setting 1 ;;
        off) _conf_set setting 0 ;;
        *) echo "usage: $0 eardetection on|off" >&2; exit 2 ;;
    esac
}

cmd_rename() {
    local name="${*:-}"
    [[ -z "$name" ]] && { echo "usage: $0 rename <name>" >&2; exit 2; }
    _conf_set deviceName "$name"
}

cmd_noise() {
    case "${1:-}" in
        off|transparency|adaptive|anc) librepods-ctl "noise:${1}" ;;
        *) echo "unknown noise mode: ${1:-}" >&2; exit 2 ;;
    esac
}

# --- dispatch --------------------------------------------------------------
#
# Note: conversation awareness is read-only. LibrePods 0.2.5 offers no external
# way to toggle it (librepods-ctl only does noise, its control socket only
# accepts noise:* commands, and the tray DBusMenu ignores activation events), so
# there is deliberately no `conversation` command here.

case "${1:-status}" in
    status)       cmd_status ;;
    noise)        cmd_noise "${2:-}" ;;
    eardetection) cmd_eardetection "${2:-}" ;;
    rename)       shift; cmd_rename "$@" ;;
    *) echo "usage: $0 {status|noise <mode>|eardetection on|off|rename <name>}" >&2; exit 2 ;;
esac

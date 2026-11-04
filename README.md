> DISCLAIMER: This widget was built with heavy assistance from LLMs (Claude). However, before publishing the plugin, the code was reviewed by me, for which I take responsibility.

# AirPods for DankMaterialShell

Battery status and noise control in the bar and Control Center, powered by
[LibrePods](https://github.com/librepods-org/librepods).

- **Bar:** battery percentage or a minimal icon using DMS's standard icon size and padding.
- **Panel:** shared by the bar popout and Control Center, with battery, noise modes and detection settings.
- **AirPods Max:** headphones icon, one headset battery card, Off / Transparency / ANC,
  and Automatic Head Detection. Earbuds retain Left / Right / Case and Adaptive mode.
- **Control Center tile:** click to cycle ANC / Transparency; expand for the full panel.
- **Independent visibility:** hide the disconnected bar widget while keeping the menu tile visible.

![Control Center](./assets/control-center.png)
![Widget](./assets/widget.png)

## Requirements and installation

- DMS with widget and Control Center plugin support.
- Qt 6.6 or newer (the battery ring uses the Qt Quick Shapes curve renderer).
- `librepods-ctl` and `dbus-send` on `PATH`, checked at plugin startup.
- LibrePods running, with AirPods paired.

Copy or symlink this repository into your DMS plugin directory as `librepods`:

```sh
ln -s "$PWD" ~/.config/DankMaterialShell/plugins/librepods
```

Use your installation's actual config directory (some versions use `~/.config/dms`).
Add **AirPods Control** in DMS's bar / Control Center settings.

If your shell configuration is a read-only Nix store link, declare widget placement
through your Nix / Home Manager configuration instead of changing it at runtime.

## Settings

| Setting | Options | Default |
| --- | --- | --- |
| Bar appearance | Icon + battery percentage / Minimal icon | Battery percentage |
| Bar visibility | Only when connected / Always | Only when connected |
| Control Center visibility | Always / Only when connected | Always |
| Refresh interval | 1 / 2 / 5 / 10 / 30 seconds | 5 seconds |

Refresh intervals previously saved under the legacy `airpods` settings ID are
preserved until overridden under `librepods`.

### Control Center visibility integration

Bar visibility is handled by the plugin and needs no shell modifications.
The Control Center is always visible by default, independently of the bar.

Some DMS versions do **not** consult a plugin's visibility when laying out Control
Center tiles. On those versions, selecting **Only when connected** for the Control
Center requires shell-side integration; the plugin cannot remove the host's tile
or reclaim its layout space by itself.

[`integrations/dms-control-center-visibility.patch`](integrations/dms-control-center-visibility.patch)
adds that integration for DMS versions with `Modules/ControlCenter/utils/widgets.js`.
Apply it to the shell source (or declaratively through a Nix package override),
then rebuild/restart the shell. Other versions may need an equivalent adapter.
Without integration, the Control Center tile remains visible regardless of this setting.

The plugin also exposes `ccWidgetVisible` for hosts supporting that contract.
The adapter checks the saved setting and `PluginService.globalVars.airpods_state.state.connected`.
It filters displayed tiles rather than deleting saved widget placement.

## LibrePods interfaces and limitations

The plugin shells out to [`scripts/librepods-bridge.sh`](scripts/librepods-bridge.sh):

| Data / operation | Interface |
| --- | --- |
| Battery | tray StatusNotifierItem ToolTip |
| Noise mode / Conversation Awareness | tray DBusMenu toggle states |
| Connection | BlueZ Device1.Connected, with a tray fallback |
| Device name / detection setting / Max model | LibrePods config file |
| Change noise mode | `librepods-ctl noise:<mode>` |
| Change detection / rename | config file; reconnect to apply |

LibrePods 0.2.5 limitations:

- **Conversation Awareness is read-only:** there is no external write command.
  The panel directs you to the LibrePods app to change it.
- **Detection and rename require reconnecting.** A toast reminds you after writing.
- **Initial noise selection may be missing:** LibrePods can receive Transparency
  without updating its tray checkmark when it matches its default. This requires
  an upstream LibrePods fix; the widget deliberately does not invent a selected mode.
- **Run one LibrePods instance.** The bridge prefers the tray instance with battery
  data if duplicates exist, but duplicate daemons can still break the control socket.
- The LibrePods config contains pairing secrets. Do not attach it to issues or PRs.

Codec preference, native notifications and LibrePods startup are outside this
plugin's scope. This repository does not install system services or patch codecs.

## Architecture

All executable source and test files are limited to 300 lines.

| File / directory | Responsibility |
| --- | --- |
| `AirPodsWidget.qml` | DMS entry point, surface wiring, settings, visibility and detail sizing |
| `logic/AirPodsController.qml` | Shared live state, polling, commands and delayed confirmation |
| `logic/State.js` | Pure normalization, reconciliation, battery and visibility helpers |
| `components/AirPodsPanel.qml` | Composes the shared panel |
| `components/DeviceHeader.qml` | Device icon and name |
| `components/BatterySection.qml` | Selects the headset or earbuds layout |
| `components/HeadsetBattery.qml` | AirPods Max battery card |
| `components/BatteryRing.qml` | Reusable earbuds battery indicator |
| `components/NoiseSelector.qml` | Capability-aware noise buttons |
| `components/ToggleRow.qml` | Reusable detection / conversation row |
| `components/BarPill.qml` | One implementation for horizontal and vertical bars |
| `Settings.qml`, `StartupCheck.qml` | Settings UI and dependency check |
| `scripts/librepods-bridge.sh` | D-Bus / BlueZ / config boundary |
| `tests/` | Headless QtTest suite with small DMS boundary mocks |

Each DMS surface can instantiate the entry point independently. Controllers share
one reactive store (`airpods_state`), including optimistic write locks, so a stale
poll cannot immediately undo a click on another surface. Locks expire after four
seconds or clear on hardware confirmation / disconnection. Each controller uses
unique process IDs so simultaneous polls do not replace one another's callbacks.

Control Center detail instances may not have a `pluginService` or `pluginId`.
The entry point resolves the bridge relative to its own file as a fallback and
passes the absolute path to the controller. Nested components never need to know
the plugin installation path.

## Development and tests

With Qt 6's `qmltestrunner` and `qmllint` on `PATH`:

```sh
bash tests/run.sh
```

Or provide executable paths with `QMLTESTRUNNER` and `QMLLINT`. On NixOS, ensure
Qt's QML modules are available through `QML2_IMPORT_PATH` if not provided by your shell.
The runner checks QML syntax, shell syntax and the 300-line limit, then runs QtTest
offscreen. The suite was validated locally with Qt 6.12.0.

Tests cover state normalization, lock confirmation / expiry / disconnection,
battery fallbacks, legacy settings, independent visibility, shared controllers,
Max / earbuds modes, both bar orientations and formats, panel sizing and DMS entry
point construction. DMS singletons / widgets are mocked only at the host boundary;
the actual plugin controller, panel and subcomponents are instantiated.
These tests do not replace a live Bluetooth / D-Bus smoke test.

Reload the installed plugin:

```sh
dms ipc call plugins reload librepods
```

Close and reopen the surface being tested; already-open surfaces can retain their
old instances. For shell versions with older IPC names, use their equivalent reload
command. Also check both connected and disconnected states, bar orientations,
Control Center expansion, noise switching and settings changes on a live shell.

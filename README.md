# flutter_mic_selector

Android-only Flutter plugin for listing audio input devices, selecting a preferred microphone, persisting that selection, and explicitly controlling an app-owned recording session.

The plugin restores the saved device when the app opens, **but does not activate the microphone** until your app calls `start()`. If the saved device is not currently connected, the selector reports no selected device until that input appears again.

---

## Features

- List all available Android audio input devices
- Watch device connection and disconnection changes in real time
- Select or clear a preferred microphone input
- Persist and restore the selected device ID in the native Android layer (no `shared_preferences`)
- Start and stop an app-owned microphone activation session
- Check and request `RECORD_AUDIO` permission
- Stream state changes for devices, selected device, and active flag
- Use built-in widgets or compose fully custom UI

---

## Platform Support

| Platform | Support |
|---|---|
| Android | ✅ Fully supported |
| iOS | ❌ Returns `platformNotSupported` |
| Web | ❌ Returns `platformNotSupported` |
| Desktop | ❌ Returns `platformNotSupported` |

---

## Contributions Welcome

Contributions are welcome, especially for adding support for platforms beyond Android.

The current implementation focuses on Android microphone input routing. If you are interested in helping with iOS, web, macOS, Windows, or Linux support, feel free to open an issue or pull request with your proposed approach. Platform implementations should keep the public Dart API consistent and return `platformNotSupported` for APIs that cannot be implemented safely on that platform.

Bug reports, documentation improvements, tests, and small API polish are also appreciated.

---

## Android Setup

The plugin declares `android.permission.RECORD_AUDIO` in its own manifest. Your app still needs to request the permission at runtime before starting a microphone session:

```dart
final selector = MicSelector.instance;

final status = await selector.hasPermission();
if (status != MicPermissionStatus.granted) {
  await selector.requestPermission();
}
```

---

## API Reference

### `MicSelector`

The main entry point for the plugin. Use the singleton `MicSelector.instance` for all operations.

---

#### `getDevices()` → `Future<List<MicInputDevice>>`

Returns the list of all audio input devices currently available on the Android device.

**How it works:**  
Calls `AudioManager.getDevices(GET_DEVICES_INPUTS)` on the native side and maps each `AudioDeviceInfo` to a `MicInputDevice`. The result reflects the state at the moment of the call — use `watchDevices()` to receive automatic updates.

```dart
final devices = await MicSelector.instance.getDevices();
for (final device in devices) {
  print('${device.displayName} (${device.type})');
}
```

---

#### `watchDevices()` → `Stream<List<MicInputDevice>>`

A stream that emits the latest device list whenever a device is connected or disconnected.

**How it works:**  
Registers an `AudioDeviceCallback` in native Android. Every time Android reports a change (`onAudioDevicesAdded` / `onAudioDevicesRemoved`), the native side sends an event through an `EventChannel` to Dart.

```dart
MicSelector.instance.watchDevices().listen((devices) {
  print('Devices changed: ${devices.length} input(s) available');
});
```

---

#### `selectDevice(String deviceId)` → `Future<void>`

Selects and persists the preferred audio input device.

**How it works:**  
1. Sends `deviceId` to native via the method channel.
2. Native validates that the device exists in `GET_DEVICES_INPUTS`.
3. If an `AudioRecord` session is currently active, native immediately applies routing to that device via `AudioRecord.setPreferredDevice()`.
4. The device ID is written to a file in the app's private files directory.

Throws a `MicException` if the device is not found or Android rejects the routing.

```dart
final devices = await MicSelector.instance.getDevices();
await MicSelector.instance.selectDevice(devices.first.id);
```

---

#### `clearSelectedDevice()` → `Future<void>`

Removes the persisted device preference.

**How it works:**  
Clears the ID from the in-process state, then deletes the storage file in native Android. If an `AudioRecord` session is active, the preferred device is also cleared (`setPreferredDevice(null)`), letting Android fall back to its default routing.

```dart
await MicSelector.instance.clearSelectedDevice();
```

---

#### `getSelectedDevice()` → `Future<MicInputDevice?>`

Returns the currently selected `MicInputDevice`, or `null` if none has been chosen.

**How it works:**  
Reads from the internal Dart state that is populated during plugin initialisation — no extra I/O is performed. The device is restored from native storage on first use.

```dart
final selected = await MicSelector.instance.getSelectedDevice();
print(selected?.displayName ?? 'No device selected');
```

---

#### `start({String? deviceId})` → `Future<void>`

**The only API that activates the microphone.** Starts an app-owned `AudioRecord` session.

**How it works:**  
1. Checks `RECORD_AUDIO` permission — throws an error if not granted.
2. Stops any existing session first.
3. Creates a new `AudioRecord` instance at 44 100 Hz, mono, PCM 16-bit.
4. If a `deviceId` is provided (from the argument or from the selected state), applies the preferred device via `AudioRecord.setPreferredDevice()`.
5. Starts a background read loop that computes RMS and peak levels from each PCM buffer and pushes them to the `watchInputLevel()` stream.

> ⚠️ Restoring a saved device ID **never** starts recording automatically. `start()` must be called explicitly.

```dart
final status = await MicSelector.instance.hasPermission();
if (status == MicPermissionStatus.granted) {
  await MicSelector.instance.start();
}
```

---

#### `stop()` → `Future<void>`

Stops the active `AudioRecord` session.

**How it works:**  
Sets the `isRecording` flag to `false`, waits for the background read thread to finish (250 ms timeout), stops and releases the `AudioRecord`, then emits a `0.0` level event so the UI can reflect the inactive state.

```dart
await MicSelector.instance.stop();
```

---

#### `watchState()` → `Stream<MicSelectorState>`

A stream that emits a `MicSelectorState` snapshot whenever the device list, selected device, or active flag changes.

**How it works:**  
On first subscription, the stream immediately emits the current state without waiting for the next change. Subsequent emissions come from the internal broadcast controller whenever `selectDevice()`, `clearSelectedDevice()`, `start()`, `stop()`, or a device-list update occurs.

```dart
MicSelector.instance.watchState().listen((state) {
  print('Devices: ${state.devices.length}');
  print('Selected: ${state.selectedDevice?.displayName}');
  print('Active: ${state.isActive}');
});
```

---

#### `watchInputLevel()` → `Stream<MicInputLevel>`

A stream that continuously emits RMS and peak audio levels while a session is active.

**How it works:**  
The native Android layer reads PCM 16-bit buffers from `AudioRecord` in a background thread, calculates RMS (`√(Σx²/n) / MAX_VALUE`) and the absolute peak, then sends the values to Flutter via an `EventChannel`. Both values are normalised between `0.0` (silence) and `1.0` (full scale).

```dart
MicSelector.instance.watchInputLevel().listen((level) {
  print('RMS:  ${level.rms.toStringAsFixed(3)}');
  print('Peak: ${level.peak.toStringAsFixed(3)}');
});
```

---

#### `hasPermission()` → `Future<MicPermissionStatus>`

Returns the current `RECORD_AUDIO` permission status without prompting the user.

```dart
final status = await MicSelector.instance.hasPermission();
if (status == MicPermissionStatus.granted) { ... }
```

---

#### `requestPermission()` → `Future<MicPermissionStatus>`

Shows the Android system permission dialog for `RECORD_AUDIO`.

**How it works:**  
Calls `Activity.requestPermissions()` and waits for the `onRequestPermissionsResult` callback. If the permission was already granted, the result is returned immediately without displaying any dialog.

```dart
final status = await MicSelector.instance.requestPermission();
if (status != MicPermissionStatus.granted) {
  // Inform the user that the permission is required
}
```

---

### `MicSelectorState`

An immutable state snapshot emitted by `watchState()`.

| Field | Type | Description |
|---|---|---|
| `devices` | `List<MicInputDevice>` | All available input devices at the time of this snapshot |
| `selectedDevice` | `MicInputDevice?` | The currently selected device, or `null` |
| `isActive` | `bool` | `true` while an `AudioRecord` session is running |

---

### `MicInputDevice`

Describes a single audio input device.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Stable Android audio device ID |
| `name` | `String` | Display name reported by the platform |
| `type` | `String` | Stable type string — compare with `MicInputDeviceTypes` constants |
| `typeId` | `int?` | Raw `AudioDeviceInfo.TYPE_*` value |
| `typeLabel` | `String?` | Human-friendly label for `type` |
| `rawName` | `String?` | Raw product name from Android |
| `address` | `String?` | Device address from Android |
| `isDefault` | `bool` | Whether this is the current default input route |
| `displayName` | `String` | Single-line selector label (getter) |
| `effectiveTypeLabel` | `String` | Best available label (getter) |

```dart
for (final device in await MicSelector.instance.getDevices()) {
  print(device.id);                 // "3"
  print(device.type);               // "usbDevice"
  print(device.effectiveTypeLabel); // "USB microphone"
  print(device.displayName);        // "USB microphone - Blue Yeti"

  if (device.type == MicInputDeviceTypes.bluetoothSco) {
    // Bluetooth headset microphone
  }
}
```

**Common device type constants:**

| Constant | Description |
|---|---|
| `builtInMic` | Device's built-in microphone |
| `wiredHeadset` | Wired headset with microphone |
| `usbDevice` | USB microphone |
| `usbHeadset` | USB headset with microphone |
| `bluetoothSco` | Bluetooth headset (SCO profile) |
| `bleHeadset` | Bluetooth LE headset |
| `telephony` | Telephony microphone |
| `auxLine` | Analog aux input |
| `hdmi` | HDMI audio input |
| `remoteSubmix` | Remote submix input |

---

### `MicInputLevel`

An audio level snapshot emitted by `watchInputLevel()`.

| Field | Type | Description |
|---|---|---|
| `rms` | `double` | Root-mean-square level, normalised `0.0–1.0` |
| `peak` | `double` | Absolute peak level, normalised `0.0–1.0` |

---

### `MicPermissionStatus`

| Value | Description |
|---|---|
| `granted` | Permission granted — microphone session can be started |
| `denied` | Permission denied or not yet requested |
| `platformNotSupported` | The platform cannot report microphone permission status |

---

### `MicError` / `MicException`

All operation failures are thrown as a `MicException` carrying a `MicError`.

| Code | Description |
|---|---|
| `platformNotSupported` | The API is not implemented on this platform |
| `permissionDenied` | `RECORD_AUDIO` permission has not been granted |
| `deviceNotFound` | The requested device could not be found |
| `activationFailed` | Android rejected the routing or the session could not be created |
| `unknown` | An unexpected platform or plugin error occurred |

```dart
try {
  await MicSelector.instance.start();
} on MicException catch (e) {
  print(e.error.code);    // MicErrorCode.permissionDenied
  print(e.error.message); // "RECORD_AUDIO permission is required."
}
```

---

## Built-in Widgets

### `MicSelectorView`

A full-featured UI with a device dropdown, Enable / Disable buttons, and a Clear button.

```dart
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: MicSelectorView(title: 'Microphone'),
      ),
    );
  }
}
```

---

### `MicSelectorDropdown`

A compact dropdown suitable for embedding inside a form.

```dart
const MicSelectorDropdown(
  hint: Text('Select microphone'),
)
```

---

### `MicSelectorBuilder`

A low-level builder for constructing fully custom UI from `MicSelectorState`.

**How it works:**  
Wraps a `StreamBuilder` connected to `MicSelector.watchState()`. Every time the state changes — a new device connects, the selection changes, or a session starts or stops — the builder is called with the latest snapshot.

```dart
MicSelectorBuilder(
  builder: (context, state, selector) {
    return Column(
      children: [
        for (final device in state.devices)
          RadioListTile<String>(
            value: device.id,
            groupValue: state.selectedDevice?.id,
            title: Text(device.displayName),
            subtitle: Text(device.effectiveTypeLabel),
            onChanged: (id) => selector.selectDevice(id!),
          ),
        SwitchListTile(
          value: state.isActive,
          title: const Text('Microphone active'),
          onChanged: (enabled) {
            enabled ? selector.start() : selector.stop();
          },
        ),
      ],
    );
  },
)
```

---

## Persistence

The selected device ID is stored by the native Android plugin in the app's private files directory:

```
/data/data/<applicationId>/files/flutter_mic_selector_selected_device_id.txt
```

- `selectDevice()` writes this file through the native Android plugin.
- `clearSelectedDevice()` deletes the file.
- The Dart package does not depend on `shared_preferences`.
- The Android implementation does not use Android `SharedPreferences` for this value.

---

## Full Usage Example

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

Future<void> setupMicrophone() async {
  final selector = MicSelector.instance;

  // 1. Request permission
  if (await selector.hasPermission() != MicPermissionStatus.granted) {
    final result = await selector.requestPermission();
    if (result != MicPermissionStatus.granted) return;
  }

  // 2. Fetch available devices
  final devices = await selector.getDevices();

  // 3. Prefer a USB microphone if one is connected
  final preferred = devices.firstWhere(
    (d) => d.type == MicInputDeviceTypes.usbDevice,
    orElse: () => devices.first,
  );
  await selector.selectDevice(preferred.id);

  // 4. Start the microphone session
  await selector.start();

  // 5. Monitor input level
  selector.watchInputLevel().listen((level) {
    print('RMS: ${(level.rms * 100).toInt()}%');
  });

  // 6. Stop when done
  await selector.stop();
}
```

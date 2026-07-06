# Usage Guide

## Import

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';
```

## Accessing the Singleton

All operations go through `MicSelector.instance`:

```dart
final selector = MicSelector.instance;
```

## 1. Permission Flow

Before activating the microphone, request `RECORD_AUDIO` permission:

```dart
// Check current permission state
MicPermissionStatus status = await selector.hasPermission();

// Request if not granted
if (status != MicPermissionStatus.granted) {
  status = await selector.requestPermission();
  if (status != MicPermissionStatus.granted) {
    // Show rationale — permission is required for mic access
    return;
  }
}
```

`MicPermissionStatus` has three values:
- `granted` — permission granted
- `denied` — denied or not yet requested
- `platformNotSupported` — platform cannot report permissions

## 2. Listing Available Devices

```dart
// One-shot fetch
final List<MicInputDevice> devices = await selector.getDevices();
for (final device in devices) {
  print('${device.displayName} (${device.type})');
}
```

Watch for real-time device changes (plug/unplug):

```dart
selector.watchDevices().listen((devices) {
  print('${devices.length} input(s) available');
});
```

## 3. Selecting a Device

```dart
final devices = await selector.getDevices();
if (devices.isNotEmpty) {
  // Select by device ID
  await selector.selectDevice(devices.first.id);

  // The selection is persisted automatically
  final selected = await selector.getSelectedDevice();
  print('Selected: ${selected?.displayName}');
}
```

Clear the selection:

```dart
await selector.clearSelectedDevice();
```

> **Note:** `selectDevice` persists the device ID to native Android storage. The selection survives app restarts. If the selected device disconnects, it returns `null` until it reconnects.

## 4. Starting and Stopping the Microphone

**This is the only API that activates the microphone.**

```dart
// Start — requires RECORD_AUDIO permission
await selector.start();

// ... do something with audio ...

// Stop
await selector.stop();
```

Check if a session is active:

```dart
if (selector.isActive) {
  // Microphone is currently active
}
```

## 5. Monitoring Input Level

While a session is active, stream RMS and peak levels:

```dart
selector.watchInputLevel().listen((MicInputLevel level) {
  print('RMS:  ${(level.rms * 100).toStringAsFixed(0)}%');
  print('Peak: ${(level.peak * 100).toStringAsFixed(0)}%');
});
```

Both values are normalised `0.0`–`1.0`.

## 6. Watching State Changes

Subscribe to the full state snapshot — devices, selected device, and active flag:

```dart
selector.watchState().listen((MicSelectorState state) {
  print('Devices: ${state.devices.length}');
  print('Selected: ${state.selectedDevice?.displayName}');
  print('Active: ${state.isActive}');
});
```

## Complete Example

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

  // 3. Prefer USB microphone if available
  final preferred = devices.firstWhere(
    (d) => d.type == MicInputDeviceTypes.usbDevice,
    orElse: () => devices.first,
  );
  await selector.selectDevice(preferred.id);

  // 4. Start microphone session
  await selector.start();

  // 5. Monitor input level
  selector.watchInputLevel().listen((level) {
    print('RMS: ${(level.rms * 100).toInt()}%');
  });

  // 6. Stop when done
  await Future.delayed(const Duration(seconds: 10));
  await selector.stop();
}
```

## Device Properties

`MicInputDevice` provides the following fields:

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
| `displayName` | `String` (getter) | Single-line label for selectors |
| `effectiveTypeLabel` | `String` (getter) | Best available type label |

Compare `type` against constants:

```dart
if (device.type == MicInputDeviceTypes.bluetoothSco) {
  // Bluetooth headset microphone
}
```

## Persistence

The selected device ID is stored in a file in the app's private directory:

```
/data/data/<applicationId>/files/flutter_mic_selector_selected_device_id.txt
```

- `selectDevice()` writes the file via native Android
- `clearSelectedDevice()` deletes the file
- No dependency on `shared_preferences`
- No use of Android `SharedPreferences`

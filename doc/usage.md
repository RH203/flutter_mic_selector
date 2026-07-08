# Usage Guide

## Import

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';
```

## Accessing the Singleton

```dart
final micSelector = FlutterMicSelector.instance;
```

## 1. Permission Flow

Before using microphone features, request `RECORD_AUDIO` permission:

```dart
if (!await micSelector.hasPermission()) {
  final granted = await micSelector.requestPermission();
  if (!granted) {
    // Show rationale — permission is required
    return;
  }
}
```

## 2. Listing Available Devices

```dart
// One-shot fetch
final devices = await micSelector.getAvailableMicrophones();
for (final device in devices) {
  print('${device.name} (${device.type.label})');
}
```

Watch real-time device changes (plug/unplug):

```dart
micSelector.microphoneDevicesChanged.listen((devices) {
  print('${devices.length} microphone(s) available');
});
```

## 3. Selecting a Device

```dart
final devices = await micSelector.getAvailableMicrophones();
if (devices.isNotEmpty) {
  // Select by device object
  await micSelector.selectMicrophone(devices.first);

  // Or select by native device ID
  await micSelector.selectMicrophoneById(devices.first.id);

  // Read the selected device
  final selected = await micSelector.getSelectedMicrophone();
  print('Selected: ${selected?.name}');
}
```

Clear selection:

```dart
await micSelector.clearSelectedMicrophone();
```

> **Note:** Selection is persisted to native Android storage. It survives app restarts. If the selected device disconnects, `getSelectedMicrophone()` returns `null` until it reconnects.

## Complete Example

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

Future<void> setupMicrophone() async {
  final micSelector = FlutterMicSelector.instance;

  // 1. Request permission
  if (!await micSelector.hasPermission()) {
    final granted = await micSelector.requestPermission();
    if (!granted) return;
  }

  // 2. Fetch available devices
  final devices = await micSelector.getAvailableMicrophones();

  // 3. Prefer USB microphone if available
  final preferred = devices.firstWhere(
    (d) => d.type == MicrophoneType.usb,
    orElse: () => devices.first,
  );
  await micSelector.selectMicrophone(preferred);

  // 4. Selection is persisted and ready for recording packages
  print('Selected: ${preferred.name}');
}
```

## Device Properties

`MicrophoneDevice` provides:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Stable Android audio device ID |
| `name` | `String` | Display name reported by the platform |
| `type` | `MicrophoneType` | Categorized device type |
| `isInput` | `bool` | Always `true` for microphones |
| `isSelected` | `bool` | Whether this is the currently selected device |

`MicrophoneType` values: `builtIn`, `wiredHeadset`, `bluetooth`, `usb`, `telephony`, `unknown`.

## Persistence

Selected device ID is stored at:

```
/data/data/<applicationId>/files/flutter_mic_selector_selected_device_id.txt
```

- `selectMicrophone()` / `selectMicrophoneById()` write via native Android
- `clearSelectedMicrophone()` deletes the file
- No `shared_preferences` dependency

# flutter_mic_selector

A Flutter plugin for discovering and selecting Android microphone input devices for use with compatible audio and video recording packages.

This plugin is focused solely on microphone discovery and selection. It does **not** record audio. Use external packages such as `record` for actual recording.

---

## Features

- List all available Android microphone input devices
- Select a microphone by device ID
- Read the currently selected microphone
- Clear the selection and restore system default routing
- Listen for microphone connection and disconnection events
- Persist the selected device ID in native Android storage
- Check and request `RECORD_AUDIO` permission

## Platform Support

| Platform | Support |
|----------|---------|
| Android  | ✅ Supported |
| iOS      | ❌ Not supported |
| Web      | ❌ Not supported |
| Windows  | ❌ Not supported |
| macOS    | ❌ Not supported |
| Linux    | ❌ Not supported |

## Android Requirements

- **minSdk**: 21 (Android 5.0)
- Device discovery requires API 23+ (Android 6.0) — returns empty list on older versions
- Device connection events (`AudioDeviceCallback`) require API 23+

## Installation

```yaml
dependencies:
  flutter_mic_selector: ^0.3.0
```

## Permission Setup

The plugin declares `android.permission.RECORD_AUDIO` in its own manifest. Your app must also request this permission at runtime before using microphone features:

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

final micSelector = FlutterMicSelector.instance;

if (await micSelector.hasPermission()) {
  // Permission granted
} else {
  final granted = await micSelector.requestPermission();
  if (!granted) return; // Handle denial
}
```

For more control over permission flows, use the `permission_handler` package.

---

## Usage

### Import

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';
```

### Listing Microphones

```dart
final micSelector = FlutterMicSelector.instance;
final devices = await micSelector.getAvailableMicrophones();

for (final device in devices) {
  print('${device.name} (${device.type.label})');
}
```

### Selecting a Microphone

```dart
final devices = await micSelector.getAvailableMicrophones();
if (devices.isNotEmpty) {
  await micSelector.selectMicrophone(devices.first);
  // or by ID:
  await micSelector.selectMicrophoneById(devices.first.id);
}
```

### Reading the Selected Microphone

```dart
final selected = await micSelector.getSelectedMicrophone();
print(selected?.name ?? 'No device selected');
```

### Clearing the Selection

```dart
await micSelector.clearSelectedMicrophone();
// System default routing is restored.
```

### Listening for Device Changes

```dart
micSelector.microphoneDevicesChanged.listen((devices) {
  print('Devices changed: ${devices.length} microphone(s) available');
});
```

---

## Audio Recording Integration

Use the `record` package to record audio with your selected microphone:

```dart
import 'package:record/record.dart';

final micSelector = FlutterMicSelector.instance;

// Select a microphone
await micSelector.selectMicrophoneById('some-device-id');

// Start recording (Android will route audio based on the selection)
final recorder = AudioRecorder();
await recorder.start(const RecordConfig(), path: '/path/to/output.m4a');
// ... later ...
await recorder.stop();
```

> **Note**: Audio routing to the selected microphone depends on Android's audio framework. The selected device is applied as a preference, not a guaranteed route for all recorder implementations.

---

## Video Recording Integration

The official Flutter `camera` package does not expose a public microphone device parameter. Video microphone selection depends on Android audio routing and device behavior, and may not work consistently across all devices.

The plugin does not currently mux separately recorded audio and video. For synchronized A/V recording, consider using the `camera` package's built-in audio capture.

---

## Model Reference

### `MicrophoneDevice`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Stable Android audio device ID |
| `name` | `String` | User-facing display name |
| `type` | `MicrophoneType` | Categorized device type |
| `isInput` | `bool` | Always `true` for microphones |
| `isSelected` | `bool` | Whether this is the currently selected device |

### `MicrophoneType`

| Value | Description |
|-------|-------------|
| `builtIn` | Built-in microphone (earpiece, speaker, or mic) |
| `wiredHeadset` | Wired headset, headphones, or line input |
| `bluetooth` | Bluetooth or BLE headset microphone |
| `usb` | USB microphone, headset, or accessory |
| `telephony` | Telephony microphone |
| `unknown` | Unknown or unsupported input type |

### Typed Exceptions

| Exception | When thrown |
|-----------|-------------|
| `MicrophoneNotFoundException` | The requested device ID does not exist |
| `MicrophoneSelectionException` | Android rejected the selection |
| `MicrophonePermissionException` | RECORD_AUDIO permission is missing |
| `UnsupportedMicrophoneException` | Operation not supported on this platform |

---

## Example Application

The `example/` directory contains a working application that demonstrates:

1. Requesting microphone permission
2. Listing available microphones
3. Selecting a microphone
4. Displaying selected device information
5. Recording audio using the selected microphone (via `record` package)
6. Handling device connection/disconnection events

Run the example:

```bash
cd example
flutter run
```

---

## Contributing

Contributions are welcome, especially for adding support for platforms beyond Android. Please open an issue or pull request with your proposed approach.

## License

MIT

# Error Handling

All failures throw typed exceptions.

## Exception Types

| Exception | When It Occurs |
|-----------|---------------|
| `MicrophoneNotFoundException` | `selectMicrophoneById()` with invalid or disconnected device ID |
| `MicrophoneSelectionException` | Android rejected the device selection or routing |
| `MicrophonePermissionException` | RECORD_AUDIO permission is missing |
| `UnsupportedMicrophoneException` | Operation called on non-Android platform |

## Catching Errors

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

try {
  await micSelector.selectMicrophoneById('99');
} on MicrophoneNotFoundException catch (e) {
  print('Device not found: ${e.deviceId}');
} on MicrophonePermissionException catch (e) {
  print('Permission required: ${e.message}');
} on UnsupportedMicrophoneException catch (e) {
  print('Platform not supported: ${e.message}');
} on MicrophoneSelectionException catch (e) {
  print('Selection failed: ${e.message}');
}
```

## Platform Not Supported

On iOS, web, and desktop, all methods throw `UnsupportedMicrophoneException`:

```dart
try {
  await micSelector.getAvailableMicrophones();
} on UnsupportedMicrophoneException catch (e) {
  // Hide mic selector UI on unsupported platforms
}
```

## Permission Denied

```dart
final granted = await micSelector.requestPermission();
if (!granted) {
  // Show rationale explaining why mic access is needed
}
```

## Edge Cases

### Device Disconnects After Selection

If the selected device disconnects, `getSelectedMicrophone()` returns `null` and the device list is updated. The selection persists in storage — it is restored if the device reconnects.

### No Devices Available

`getAvailableMicrophones()` returns an empty list on platforms without microphones or on Android API < 23.

### Selected Device Reconnects

If a saved device reconnects, the `microphoneDevicesChanged` stream emits the updated list. Call `getSelectedMicrophone()` to check if the restored device matches.

# Error Handling

All operation failures are thrown as `MicException` carrying a structured `MicError`.

## Error Codes

| Code | Description | When It Occurs |
|---|---|---|
| `platformNotSupported` | The API is not implemented on this platform | Calling any method on iOS, web, or desktop |
| `permissionDenied` | `RECORD_AUDIO` permission has not been granted | `start()` called without permission |
| `deviceNotFound` | The requested device could not be found | `selectDevice()` with an invalid or disconnected device ID |
| `activationFailed` | Android rejected routing or session creation failed | `start()` when AudioRecord creation fails or preferred device routing is rejected |
| `unknown` | An unexpected platform or plugin error occurred | Any unclassified native error |

## Catching Errors

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

try {
  await selector.start();
} on MicException catch (e) {
  switch (e.error.code) {
    case MicErrorCode.permissionDenied:
      // Show permission rationale
      break;
    case MicErrorCode.platformNotSupported:
      // Show platform-not-supported message
      break;
    case MicErrorCode.activationFailed:
      // Retry or fall back to default device
      break;
    case MicErrorCode.deviceNotFound:
      // Refresh device list and try again
      break;
    case MicErrorCode.unknown:
      // Log and show generic error
      break;
  }
}
```

## Platform Not Supported

On iOS, web, and desktop, every method throws `MicException` with `MicErrorCode.platformNotSupported`. Check before calling:

```dart
bool _canUseMicSelector = true;

try {
  await selector.getDevices();
} on MicException catch (e) {
  if (e.error.code == MicErrorCode.platformNotSupported) {
    _canUseMicSelector = false;
    // Hide mic selector UI
  }
}
```

## Permission Denied

When the user denies `RECORD_AUDIO`, the `start()` method throws `MicException(MicErrorCode.permissionDenied)`. The `MicSelectorView` widget handles this internally. For custom UI:

```dart
final status = await selector.requestPermission();
if (status != MicPermissionStatus.granted) {
  // Show rationale dialog explaining why mic access is needed
  // User may need to grant via Settings
}
```

## Edge Cases

### Device Disconnects During Session

If the selected device disconnects while a session is active, the mic routing falls back to Android's default input. The state stream emits an updated device list without the disconnected device, and `selectedDevice` becomes `null`.

### No Devices Available

`getDevices()` returns an empty list. `watchState()` emits `devices: []`. Widgets handle this gracefully — dropdown shows no items, `MicSelectorView` shows an empty state.

### Selected Device Reconnects

If a saved preferred device disconnects and reconnects later, the selector automatically picks it up. `watchState()` emits an updated state with `selectedDevice` populated again.

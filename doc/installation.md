# Installation

## Add Dependency

Add `flutter_mic_selector` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_mic_selector: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Android Setup

The plugin declares `android.permission.RECORD_AUDIO` in its own manifest. You do **not** need to add it to your app's manifest.

Your app **must** request the permission at runtime before starting a microphone session:

```dart
final selector = MicSelector.instance;

final status = await selector.hasPermission();
if (status != MicPermissionStatus.granted) {
  final result = await selector.requestPermission();
  if (result != MicPermissionStatus.granted) {
    // Handle denied permission
    return;
  }
}
```

## iOS

The iOS plugin is a stub that returns `platformNotSupported` for all APIs. This allows the app to compile for iOS without errors, but microphone selection is not available. Contributions for real iOS support are welcome.

## Minimum Requirements

| Requirement | Version |
|---|---|
| Dart SDK | ^3.8.1 |
| Flutter | >= 3.3.0 |
| Android | API 24+ (Android 7.0) |

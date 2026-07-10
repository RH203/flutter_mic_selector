## 1.0.2

* Added package topics and an issue tracker URL to pubspec.yaml.

## 1.0.1

* Added package topics and an issue tracker URL to pubspec.yaml.

## 1.0.0

* **Breaking**: Renamed `MicSelector` → `FlutterMicSelector` (kept as deprecated typedef).
* **Breaking**: New `MicrophoneDevice` model replaces `MicInputDevice` (removed).
* **Breaking**: New `MicrophoneType` enum replaces `MicInputDeviceTypes` string constants.
* **Breaking**: Removed built-in AudioRecord recording (`start()`, `stop()`, `watchInputLevel()`, `watchState()`, `isActive`).
* **Breaking**: Permission APIs now return `bool` instead of `MicPermissionStatus` (deprecated).
* **New**: `getAvailableMicrophones()` returns available input devices as `MicrophoneDevice` objects.
* **New**: `getSelectedMicrophone()` returns the currently selected device.
* **New**: `selectMicrophone()` and `selectMicrophoneById()` for device selection by object or native ID.
* **New**: `clearSelectedMicrophone()` restores system default routing.
* **New**: `microphoneDevicesChanged` stream emits when microphones connect or disconnect.
* **New**: Typed exceptions: `MicrophoneNotFoundException`, `MicrophoneSelectionException`, `MicrophonePermissionException`, `UnsupportedMicrophoneException`.
* **Removed**: Widget layer (`MicSelectorBuilder`, `MicSelectorDropdown`, `MicSelectorView`).
* **Removed**: `MicAudioRecorder` (built-in Android recording session).
* **Example**: Audio recording demo using `record` package.
* **Docs**: Updated README, API reference, and changelog.

## 0.0.2

* Update documented about `flutter_mic_selector`

## 0.0.1

* Documented the native storage path used for the selected microphone id.
* Added broader Android audio input type constants, native type ids, and UI-friendly labels on `MicInputDevice`.
* Clarified that `type` is for stable client logic while `typeLabel`, `effectiveTypeLabel`, and `displayName` are intended for UI.
* Improved `MicSelectorDropdown` so long device names truncate cleanly instead of overflowing.
* Fixed restored-device handling when the saved microphone is no longer connected.
* Hardened Android callback, permission, and recording cleanup paths to reduce leak risk.

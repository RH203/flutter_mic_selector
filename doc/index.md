# flutter_mic_selector

Android-only Flutter plugin for listing audio input devices, selecting a preferred microphone, persisting that selection, and explicitly controlling an app-owned recording session.

## Key Concept: Opt-in Activation

The plugin restores the saved device when the app opens, **but does not activate the microphone** until your app calls `start()`. If the saved device is not currently connected, the selector reports no selected device until that input appears again.

## Platform Support

| Platform | Support |
|---|---|
| Android | ✅ Fully supported |
| iOS | ❌ Returns `platformNotSupported` |
| Web | ❌ Returns `platformNotSupported` |
| Desktop | ❌ Returns `platformNotSupported` |

## Getting Started

- [Installation](installation.md) — Add the dependency, Android setup, iOS notes
- [Usage Guide](usage.md) — Permission flow, device listing, selection, activation, input levels
- [Widgets](widgets.md) — Built-in UI components for quick integration
- [Error Handling](error_handling.md) — Error codes, exception handling, edge cases

## Features

- List all available Android audio input devices
- Watch device connection and disconnection changes in real time
- Select or clear a preferred microphone input
- Persist and restore the selected device ID in the native Android layer (no `shared_preferences`)
- Start and stop an app-owned microphone activation session
- Check and request `RECORD_AUDIO` permission
- Stream state changes for devices, selected device, and active flag
- Use built-in widgets or compose fully custom UI

## API Reference

Generate the full API reference with `dart doc`. The generated output is available at `doc/api/index.html` and documents every public class, enum, and method.

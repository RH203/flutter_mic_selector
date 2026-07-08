# flutter_mic_selector

Android-only Flutter plugin for discovering and selecting Android microphone input devices. Does **not** record audio.

## Platform Support

| Platform | Support |
|----------|---------|
| Android  | ✅ Supported |
| iOS      | ❌ Not supported |
| Web      | ❌ Not supported |
| Desktop  | ❌ Not supported |

## Getting Started

- [Installation](installation.md) — Add the dependency, Android setup
- [Usage Guide](usage.md) — Permission flow, device listing, selection, events
- [Error Handling](error_handling.md) — Typed exceptions, edge cases

## Features

- List available Android microphone input devices
- Watch device connection/disconnection changes in real time
- Select or clear a preferred microphone input
- Persist and restore the selected device ID in native Android storage
- Check and request `RECORD_AUDIO` permission

## API Reference

Generate with `dart doc`. Output at `doc/api/index.html`.

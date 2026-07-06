# Built-in Widgets

The plugin provides three built-in widgets for common microphone selection UI patterns.

## MicSelectorView

A full-featured default UI with a device dropdown, Enable / Disable buttons, and a Clear button. Drop it in a settings page or audio configuration screen.

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

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

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `selector` | `MicSelector?` | `null` (uses singleton) | Custom selector instance |
| `title` | `String` | `'Microphone'` | Title displayed above controls |

The view handles the permission flow internally — pressing Enable checks and requests `RECORD_AUDIO` permission before starting the session.

## MicSelectorDropdown

A compact dropdown suitable for embedding inside a form. Shows device names with ellipsis overflow.

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

MicSelectorDropdown(
  decoration: const InputDecoration(
    border: OutlineInputBorder(),
    labelText: 'Preferred microphone',
  ),
  hint: const Text('Select a microphone'),
)
```

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `selector` | `MicSelector?` | `null` (uses singleton) | Custom selector instance |
| `decoration` | `InputDecoration?` | `null` | Material input decoration |
| `hint` | `Widget?` | `Text('Select microphone')` | Hint when no device selected |

## MicSelectorBuilder

A low-level builder widget for constructing fully custom UI. Wraps a `StreamBuilder` connected to `MicSelector.watchState()`. Every time the state changes — devices change, selection changes, session starts/stops — the builder is called with the latest snapshot.

```dart
import 'package:flutter_mic_selector/flutter_mic_selector.dart';

MicSelectorBuilder(
  builder: (context, state, selector) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Device list with radio buttons
        for (final device in state.devices)
          RadioListTile<String>(
            value: device.id,
            groupValue: state.selectedDevice?.id,
            title: Text(device.displayName),
            subtitle: Text(device.effectiveTypeLabel),
            onChanged: (id) => selector.selectDevice(id!),
          ),

        const SizedBox(height: 16),

        // Active toggle
        SwitchListTile(
          value: state.isActive,
          title: const Text('Microphone active'),
          onChanged: (enabled) {
            if (enabled) {
              selector.start();
            } else {
              selector.stop();
            }
          },
        ),
      ],
    );
  },
)
```

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `selector` | `MicSelector?` | `null` (uses singleton) | Custom selector instance |
| `builder` | `Widget Function(BuildContext, MicSelectorState, MicSelector)` | (required) | Builds UI from latest state |

The `MicSelectorState` provides:
- `state.devices` — current list of available devices
- `state.selectedDevice` — currently selected device or `null`
- `state.isActive` — whether the microphone session is active

## Choosing a Widget

| Widget | When to Use |
|---|---|
| `MicSelectorView` | Quick drop-in solution with full controls |
| `MicSelectorDropdown` | Embedding in a form or settings panel |
| `MicSelectorBuilder` | Custom UI, VU meters, or non-Material design |

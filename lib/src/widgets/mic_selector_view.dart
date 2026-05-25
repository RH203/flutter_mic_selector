import 'package:flutter/material.dart';

import '../../flutter_mic_selector.dart';

/// Default microphone selection and activation UI.
class MicSelectorView extends StatelessWidget {
  /// Creates the default microphone selector view.
  const MicSelectorView({
    super.key,
    this.selector,
    this.title = 'Microphone',
  });

  /// Selector instance used by this widget.
  final MicSelector? selector;

  /// Title displayed above the controls.
  final String title;

  @override
  Widget build(BuildContext context) {
    final currentSelector = selector ?? MicSelector.instance;
    return MicSelectorBuilder(
      selector: currentSelector,
      builder: (context, state, selector) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            MicSelectorDropdown(selector: selector),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: state.isActive ? null : () => _start(selector),
                  icon: const Icon(Icons.mic),
                  label: const Text('Enable'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isActive ? selector.stop : null,
                  icon: const Icon(Icons.mic_off),
                  label: const Text('Disable'),
                ),
                TextButton.icon(
                  onPressed: state.selectedDevice == null
                      ? null
                      : selector.clearSelectedDevice,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _start(MicSelector selector) async {
    final status = await selector.hasPermission();
    if (status == MicPermissionStatus.granted ||
        await selector.requestPermission() == MicPermissionStatus.granted) {
      await selector.start();
    }
  }
}

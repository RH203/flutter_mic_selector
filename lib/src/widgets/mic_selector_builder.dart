import 'package:flutter/widgets.dart';

import '../../flutter_mic_selector.dart';

/// Builds custom UI from [MicSelectorState].
class MicSelectorBuilder extends StatefulWidget {
  /// Creates a builder connected to a [MicSelector] instance.
  const MicSelectorBuilder({
    super.key,
    required this.builder,
    this.selector,
  });

  /// Selector instance used by this widget.
  final MicSelector? selector;

  /// Builds UI for the latest selector state.
  final Widget Function(
    BuildContext context,
    MicSelectorState state,
    MicSelector selector,
  ) builder;

  @override
  State<MicSelectorBuilder> createState() => _MicSelectorBuilderState();
}

class _MicSelectorBuilderState extends State<MicSelectorBuilder> {
  MicSelector get _selector => widget.selector ?? MicSelector.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MicSelectorState>(
      stream: _selector.watchState(),
      builder: (context, snapshot) {
        final state = snapshot.data ??
            const MicSelectorState(devices: <MicInputDevice>[]);
        return widget.builder(context, state, _selector);
      },
    );
  }
}

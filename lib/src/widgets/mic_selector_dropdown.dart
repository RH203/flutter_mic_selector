import 'package:flutter/material.dart';

import '../../flutter_mic_selector.dart';

/// Simple dropdown for selecting an available microphone input device.
class MicSelectorDropdown extends StatelessWidget {
  /// Creates a microphone selector dropdown.
  const MicSelectorDropdown({
    super.key,
    this.selector,
    this.decoration,
    this.hint,
  });

  /// Selector instance used by this widget.
  final MicSelector? selector;

  /// Optional input decoration.
  final InputDecoration? decoration;

  /// Optional hint shown when no device is selected.
  final Widget? hint;

  @override
  Widget build(BuildContext context) {
    final currentSelector = selector ?? MicSelector.instance;
    return MicSelectorBuilder(
      selector: currentSelector,
      builder: (context, state, selector) {
        return DropdownButtonFormField<String>(
          decoration: decoration,
          isExpanded: true,
          value: state.selectedDevice?.id,
          hint: hint ?? const Text('Select microphone'),
          items: state.devices
              .map(
                (device) => DropdownMenuItem<String>(
                  value: device.id,
                  child: _MicDeviceLabel(device: device),
                ),
              )
              .toList(growable: false),
          selectedItemBuilder: (context) {
            return state.devices
                .map((device) => _MicDeviceLabel(device: device))
                .toList(growable: false);
          },
          onChanged: (deviceId) {
            if (deviceId != null) {
              currentSelector.selectDevice(deviceId);
            }
          },
        );
      },
    );
  }
}

class _MicDeviceLabel extends StatelessWidget {
  const _MicDeviceLabel({required this.device});

  final MicInputDevice device;

  @override
  Widget build(BuildContext context) {
    return Text(
      device.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}

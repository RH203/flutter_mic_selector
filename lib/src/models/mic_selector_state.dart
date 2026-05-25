import 'mic_input_device.dart';

/// Immutable state snapshot emitted by [MicSelector].
class MicSelectorState {
  /// Creates a microphone selector state snapshot.
  const MicSelectorState({
    required this.devices,
    this.selectedDevice,
    this.isActive = false,
  });

  /// Available input devices at the time this state was emitted.
  final List<MicInputDevice> devices;

  /// Preferred input device restored from native storage or selected by the user.
  final MicInputDevice? selectedDevice;

  /// Whether this plugin currently owns an active microphone session.
  final bool isActive;

  /// Returns a copy with selected fields replaced.
  MicSelectorState copyWith({
    List<MicInputDevice>? devices,
    Object? selectedDevice = _sentinel,
    bool? isActive,
  }) {
    return MicSelectorState(
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice == _sentinel
          ? this.selectedDevice
          : selectedDevice as MicInputDevice?,
      isActive: isActive ?? this.isActive,
    );
  }
}

const Object _sentinel = Object();

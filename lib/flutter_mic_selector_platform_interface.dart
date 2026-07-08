import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_mic_selector_method_channel.dart';
import 'src/models/microphone_device.dart';

/// Platform contract implemented by Android and future platform backends.
abstract class FlutterMicSelectorPlatform extends PlatformInterface {
  /// Constructs a platform interface instance.
  FlutterMicSelectorPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterMicSelectorPlatform _instance =
      MethodChannelFlutterMicSelector();

  /// The active platform implementation.
  static FlutterMicSelectorPlatform get instance => _instance;

  /// Sets the active platform implementation.
  static set instance(FlutterMicSelectorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns available microphone input devices.
  Future<List<MicrophoneDevice>> getAvailableMicrophones() {
    throw UnimplementedError(
      'getAvailableMicrophones() has not been implemented.',
    );
  }

  /// Stream of device list changes when microphones connect or disconnect.
  Stream<List<MicrophoneDevice>> microphoneDevicesChanged() {
    throw UnimplementedError(
      'microphoneDevicesChanged() has not been implemented.',
    );
  }

  /// Returns the currently selected microphone device, or `null`.
  Future<MicrophoneDevice?> getSelectedMicrophone() {
    throw UnimplementedError(
      'getSelectedMicrophone() has not been implemented.',
    );
  }

  /// Selects [device] as the preferred microphone.
  Future<void> selectMicrophone(MicrophoneDevice device) {
    throw UnimplementedError('selectMicrophone() has not been implemented.');
  }

  /// Selects a microphone by its native device [deviceId].
  Future<void> selectMicrophoneById(String deviceId) {
    throw UnimplementedError(
      'selectMicrophoneById() has not been implemented.',
    );
  }

  /// Clears the preferred microphone selection.
  Future<void> clearSelectedMicrophone() {
    throw UnimplementedError(
      'clearSelectedMicrophone() has not been implemented.',
    );
  }

  /// Checks whether the RECORD_AUDIO permission is granted.
  Future<bool> hasPermission() {
    throw UnimplementedError('hasPermission() has not been implemented.');
  }

  /// Requests the RECORD_AUDIO permission.
  Future<bool> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }
}

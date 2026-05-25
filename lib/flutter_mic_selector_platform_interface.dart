import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_mic_selector_method_channel.dart';
import 'src/models/mic_input_device.dart';
import 'src/models/mic_input_level.dart';
import 'src/models/mic_permission_status.dart';

/// Platform contract implemented by Android and future platform backends.
abstract class FlutterMicSelectorPlatform extends PlatformInterface {
  /// Constructs a platform interface instance.
  FlutterMicSelectorPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterMicSelectorPlatform _instance = MethodChannelFlutterMicSelector();

  /// The active platform implementation.
  static FlutterMicSelectorPlatform get instance => _instance;

  /// Sets the active platform implementation.
  static set instance(FlutterMicSelectorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns available audio input devices.
  Future<List<MicInputDevice>> getDevices() {
    throw UnimplementedError('getDevices() has not been implemented.');
  }

  /// Watches platform audio input device connection changes.
  Stream<List<MicInputDevice>> watchDevices() {
    throw UnimplementedError('watchDevices() has not been implemented.');
  }

  /// Watches microphone input levels while the native session is active.
  Stream<MicInputLevel> watchInputLevel() {
    throw UnimplementedError('watchInputLevel() has not been implemented.');
  }

  /// Sends the preferred device id to the native session layer.
  Future<void> selectDevice(String deviceId) {
    throw UnimplementedError('selectDevice() has not been implemented.');
  }

  /// Returns the preferred device id persisted by the native platform layer.
  Future<String?> getSelectedDeviceId() {
    throw UnimplementedError('getSelectedDeviceId() has not been implemented.');
  }

  /// Clears the preferred device id from the native session layer.
  Future<void> clearSelectedDevice() {
    throw UnimplementedError('clearSelectedDevice() has not been implemented.');
  }

  /// Starts an app-owned microphone session, optionally routed to [deviceId].
  Future<void> start({String? deviceId}) {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Stops the app-owned microphone session.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Checks Android RECORD_AUDIO permission.
  Future<MicPermissionStatus> hasPermission() {
    throw UnimplementedError('hasPermission() has not been implemented.');
  }

  /// Requests Android RECORD_AUDIO permission.
  Future<MicPermissionStatus> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }
}

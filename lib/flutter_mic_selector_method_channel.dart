import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_mic_selector_platform_interface.dart';
import 'src/models/microphone_device.dart';
import 'src/models/microphone_exceptions.dart';

/// Method-channel implementation backed by the native Android plugin.
class MethodChannelFlutterMicSelector extends FlutterMicSelectorPlatform {
  /// Creates a method-channel platform implementation.
  MethodChannelFlutterMicSelector({
    MethodChannel? methodChannel,
    EventChannel? devicesEventChannel,
  }) : methodChannel =
           methodChannel ?? const MethodChannel('flutter_mic_selector'),
       devicesEventChannel =
           devicesEventChannel ??
           const EventChannel('flutter_mic_selector/devices');

  /// Method channel used for command and query calls.
  @visibleForTesting
  final MethodChannel methodChannel;

  /// Event channel used for audio device change events.
  @visibleForTesting
  final EventChannel devicesEventChannel;

  @override
  Future<List<MicrophoneDevice>> getAvailableMicrophones() async {
    final result = await _invoke<Object?>('getDevices');
    return _parseMicrophones(result);
  }

  @override
  Stream<List<MicrophoneDevice>> microphoneDevicesChanged() {
    return devicesEventChannel.receiveBroadcastStream().map((event) {
      return _parseMicrophones((event as List<Object?>?) ?? <Object?>[]);
    });
  }

  @override
  Future<MicrophoneDevice?> getSelectedMicrophone() async {
    final deviceId = await _invoke<String>('getSelectedDeviceId');
    if (deviceId == null || deviceId.isEmpty) return null;
    final devices = await getAvailableMicrophones();
    try {
      return devices.firstWhere((d) => d.id == deviceId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> selectMicrophone(MicrophoneDevice device) {
    return selectMicrophoneById(device.id);
  }

  @override
  Future<void> selectMicrophoneById(String deviceId) {
    return _invoke<void>('selectDevice', <String, Object?>{
      'deviceId': deviceId,
    });
  }

  @override
  Future<void> clearSelectedMicrophone() {
    return _invoke<void>('clearSelectedDevice');
  }

  @override
  Future<bool> hasPermission() async {
    final status = await _invoke<String>('hasPermission');
    return status == 'granted';
  }

  @override
  Future<bool> requestPermission() async {
    final status = await _invoke<String>('requestPermission');
    return status == 'granted';
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException catch (e) {
      throw UnsupportedMicrophoneException(
        'flutter_mic_selector is currently supported on Android only. '
        '(${e.message})',
      );
    } on PlatformException catch (e) {
      throw _convertError(e);
    }
  }

  static Never _convertError(PlatformException e) {
    final message = e.message ?? 'Microphone selector platform call failed.';
    switch (e.code) {
      case 'deviceNotFound':
        throw MicrophoneNotFoundException(message);
      case 'permissionDenied':
        throw MicrophonePermissionException(message);
      case 'activationFailed':
        throw MicrophoneSelectionException(message);
      default:
        throw MicrophoneSelectionException(message);
    }
  }

  static List<MicrophoneDevice> _parseMicrophones(Object? result) {
    final items = result is List<Object?> ? result : <Object?>[];
    return items
        .whereType<Map<Object?, Object?>>()
        .map(MicrophoneDevice.fromMap)
        .where((device) => device.id.isNotEmpty)
        .toList(growable: false);
  }
}

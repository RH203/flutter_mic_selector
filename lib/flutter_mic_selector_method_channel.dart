import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_mic_selector_platform_interface.dart';
import 'src/models/mic_error.dart';
import 'src/models/mic_input_device.dart';
import 'src/models/mic_input_level.dart';
import 'src/models/mic_permission_status.dart';

/// Method-channel implementation backed by the native Android plugin.
class MethodChannelFlutterMicSelector extends FlutterMicSelectorPlatform {
  /// Creates a method-channel platform implementation.
  MethodChannelFlutterMicSelector({
    MethodChannel? methodChannel,
    EventChannel? devicesEventChannel,
    EventChannel? levelsEventChannel,
  })  : methodChannel =
            methodChannel ?? const MethodChannel('flutter_mic_selector'),
        devicesEventChannel = devicesEventChannel ??
            const EventChannel('flutter_mic_selector/devices'),
        levelsEventChannel = levelsEventChannel ??
            const EventChannel('flutter_mic_selector/levels');

  /// Method channel used for command and query calls.
  @visibleForTesting
  final MethodChannel methodChannel;

  /// Event channel used for audio device change events.
  @visibleForTesting
  final EventChannel devicesEventChannel;

  /// Event channel used for microphone input level events.
  @visibleForTesting
  final EventChannel levelsEventChannel;

  @override
  Future<List<MicInputDevice>> getDevices() async {
    final result = await _invoke<Object?>('getDevices');
    return _parseDevices(result);
  }

  @override
  Stream<List<MicInputDevice>> watchDevices() {
    return devicesEventChannel.receiveBroadcastStream().map((event) {
      return _parseDevices((event as List<Object?>?) ?? <Object?>[]);
    });
  }

  @override
  Stream<MicInputLevel> watchInputLevel() {
    return levelsEventChannel.receiveBroadcastStream().map((event) {
      if (event is Map<Object?, Object?>) {
        return MicInputLevel.fromMap(event);
      }
      return const MicInputLevel(rms: 0, peak: 0);
    });
  }

  @override
  Future<void> selectDevice(String deviceId) {
    return _invoke<void>('selectDevice', <String, Object?>{'deviceId': deviceId});
  }

  @override
  Future<String?> getSelectedDeviceId() {
    return _invoke<String>('getSelectedDeviceId');
  }

  @override
  Future<void> clearSelectedDevice() {
    return _invoke<void>('clearSelectedDevice');
  }

  @override
  Future<void> start({String? deviceId}) {
    final arguments = deviceId == null
        ? null
        : <String, Object?>{'deviceId': deviceId};
    return _invoke<void>('start', arguments);
  }

  @override
  Future<void> stop() {
    return _invoke<void>('stop');
  }

  @override
  Future<MicPermissionStatus> hasPermission() async {
    final status = await _invoke<String>('hasPermission');
    return _parsePermissionStatus(status);
  }

  @override
  Future<MicPermissionStatus> requestPermission() async {
    final status = await _invoke<String>('requestPermission');
    return _parsePermissionStatus(status);
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException catch (error) {
      throw MicException(
        MicError(
          code: MicErrorCode.platformNotSupported,
          message: 'flutter_mic_selector is currently supported on Android only.',
          details: error.message,
        ),
      );
    } on PlatformException catch (error) {
      throw MicException(
        MicError(
          code: _parseErrorCode(error.code),
          message: error.message ?? 'Microphone selector platform call failed.',
          details: error.details,
        ),
      );
    }
  }

  static List<MicInputDevice> _parseDevices(Object? result) {
    final items = result is List<Object?> ? result : <Object?>[];
    return items
        .whereType<Map<Object?, Object?>>()
        .map(MicInputDevice.fromMap)
        .where((device) => device.id.isNotEmpty)
        .toList(growable: false);
  }

  static MicPermissionStatus _parsePermissionStatus(String? status) {
    return switch (status) {
      'granted' => MicPermissionStatus.granted,
      'platformNotSupported' => MicPermissionStatus.platformNotSupported,
      _ => MicPermissionStatus.denied,
    };
  }

  static MicErrorCode _parseErrorCode(String code) {
    return MicErrorCode.values.firstWhere(
      (value) => value.name == code,
      orElse: () => MicErrorCode.unknown,
    );
  }
}

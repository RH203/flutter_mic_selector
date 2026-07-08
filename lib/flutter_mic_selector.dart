import 'dart:async';

import 'package:flutter/foundation.dart';

import 'flutter_mic_selector_platform_interface.dart';
import 'src/models/mic_input_device.dart';
import 'src/models/microphone_device.dart';
import 'src/models/microphone_exceptions.dart';
import 'src/models/microphone_type.dart';

// Deprecated exports kept for backward compatibility.
export 'src/models/mic_error.dart';
export 'src/models/mic_input_device.dart';
export 'src/models/mic_input_level.dart';
export 'src/models/mic_permission_status.dart';
export 'src/models/mic_selector_state.dart';

// New public API exports.
export 'src/models/microphone_device.dart';
export 'src/models/microphone_exceptions.dart';
export 'src/models/microphone_type.dart';

/// Public entry point for microphone input device discovery and selection.
///
/// Use [FlutterMicSelector.instance] for the singleton, or create an isolated
/// instance with [FlutterMicSelector.test] for tests.
///
/// This plugin focuses solely on microphone device management — it does not
/// perform audio recording. Use external packages such as `record` for that.
class FlutterMicSelector {
  FlutterMicSelector._({required FlutterMicSelectorPlatform platform})
    : _platform = platform {
    _deviceSubscription = _platform.microphoneDevicesChanged().listen(
      _updateDeviceList,
      onError: _deviceController.addError,
    );
  }

  static FlutterMicSelector? _instance;

  /// Singleton instance using the default platform implementation.
  static FlutterMicSelector get instance {
    return _instance ??= FlutterMicSelector._(
      platform: FlutterMicSelectorPlatform.instance,
    );
  }

  /// Creates an isolated selector for tests or advanced dependency injection.
  @visibleForTesting
  factory FlutterMicSelector.test({
    required FlutterMicSelectorPlatform platform,
  }) {
    return FlutterMicSelector._(platform: platform);
  }

  final FlutterMicSelectorPlatform _platform;
  final StreamController<List<MicrophoneDevice>> _deviceController =
      StreamController<List<MicrophoneDevice>>.broadcast();
  StreamSubscription<List<MicrophoneDevice>>? _deviceSubscription;
  List<MicrophoneDevice> _devices = const <MicrophoneDevice>[];
  String? _selectedDeviceId;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns available microphone input devices.
  ///
  /// Only input-capable devices are included.
  Future<List<MicrophoneDevice>> getAvailableMicrophones() async {
    final devices = await _platform.getAvailableMicrophones();
    _updateDeviceList(devices);
    return devices;
  }

  /// Stream that emits the latest device list when a microphone is connected
  /// or disconnected.
  Stream<List<MicrophoneDevice>> get microphoneDevicesChanged =>
      _deviceController.stream;

  /// Returns the currently selected microphone, or `null` if none is selected.
  Future<MicrophoneDevice?> getSelectedMicrophone() async {
    try {
      return await _platform.getSelectedMicrophone();
    } on UnsupportedMicrophoneException {
      return null;
    }
  }

  /// Selects [microphone] as the preferred input device.
  ///
  /// Throws [MicrophoneNotFoundException] if the device no longer exists.
  /// Throws [MicrophoneSelectionException] if Android rejects the routing.
  Future<void> selectMicrophone(MicrophoneDevice microphone) async {
    await selectMicrophoneById(microphone.id);
  }

  /// Selects a microphone by its native device [deviceId].
  ///
  /// Throws [MicrophoneNotFoundException] if the device no longer exists.
  /// Throws [MicrophoneSelectionException] if Android rejects the routing.
  Future<void> selectMicrophoneById(String deviceId) async {
    try {
      await _platform.selectMicrophoneById(deviceId);
      _selectedDeviceId = deviceId;
      _updateDeviceList(_devices);
    } on MicrophoneNotFoundException {
      rethrow;
    } on UnsupportedMicrophoneException {
      rethrow;
    } on MicrophoneSelectionException {
      rethrow;
    } catch (e) {
      throw MicrophoneSelectionException(
        'Failed to select microphone $deviceId: $e',
        deviceId,
      );
    }
  }

  /// Clears the preferred microphone selection, restoring system default routing.
  Future<void> clearSelectedMicrophone() async {
    try {
      await _platform.clearSelectedMicrophone();
    } on UnsupportedMicrophoneException {
      // Not supported on non-Android platforms; ignore.
    }
    _selectedDeviceId = null;
    _updateDeviceList(_devices);
  }

  /// Checks whether the RECORD_AUDIO permission is granted.
  ///
  /// The plugin needs this permission to query and select audio devices.
  /// Permission UI must be handled by the consuming application.
  Future<bool> hasPermission() {
    return _platform.hasPermission();
  }

  /// Requests the RECORD_AUDIO permission.
  ///
  /// Returns `true` if the permission was granted.
  /// The consuming application should handle permission-denied flows.
  Future<bool> requestPermission() {
    return _platform.requestPermission();
  }

  /// Releases stream subscriptions held by this selector.
  @visibleForTesting
  Future<void> dispose() async {
    await _deviceSubscription?.cancel();
    await _deviceController.close();
  }

  // ---------------------------------------------------------------------------
  // Deprecated API wrappers
  // ---------------------------------------------------------------------------

  @Deprecated('Use getAvailableMicrophones instead.')
  Future<List<MicInputDevice>> getDevices() async {
    final devices = await getAvailableMicrophones();
    return devices.map(_toLegacy).toList(growable: false);
  }

  @Deprecated('Use microphoneDevicesChanged stream instead.')
  Stream<List<MicInputDevice>> watchDevices() {
    return _deviceController.stream.map(
      (devices) => devices.map(_toLegacy).toList(growable: false),
    );
  }

  @Deprecated('Use getSelectedMicrophone instead.')
  Future<MicInputDevice?> getSelectedDevice() async {
    final device = await getSelectedMicrophone();
    if (device == null) return null;
    return _toLegacy(device);
  }

  @Deprecated('Use selectMicrophone or selectMicrophoneById instead.')
  Future<void> selectDevice(String deviceId) {
    return selectMicrophoneById(deviceId);
  }

  @Deprecated('Use clearSelectedMicrophone instead.')
  Future<void> clearSelectedDevice() {
    return clearSelectedMicrophone();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _updateDeviceList(List<MicrophoneDevice> devices) {
    _devices = List<MicrophoneDevice>.unmodifiable(
      devices.map(
        (d) =>
            d.isSelected ==
                (_selectedDeviceId != null && d.id == _selectedDeviceId)
            ? d.copyWith(
                isSelected:
                    _selectedDeviceId != null && d.id == _selectedDeviceId,
              )
            : d,
      ),
    );
    if (!_deviceController.isClosed) {
      _deviceController.add(_devices);
    }
  }

  static MicInputDevice _toLegacy(MicrophoneDevice device) {
    return MicInputDevice(
      id: device.id,
      name: device.name,
      type: _typeToString(device.type),
      isDefault: device.isSelected,
    );
  }

  static String _typeToString(MicrophoneType type) {
    return switch (type) {
      MicrophoneType.builtIn => 'builtInMic',
      MicrophoneType.wiredHeadset => 'wiredHeadset',
      MicrophoneType.bluetooth => 'bluetoothSco',
      MicrophoneType.usb => 'usbDevice',
      MicrophoneType.telephony => 'telephony',
      MicrophoneType.unknown => 'unknown',
    };
  }
}

/// Backward-compatible alias for the main plugin entry point.
///
/// Deprecated: Use [FlutterMicSelector] instead.
@Deprecated('Use FlutterMicSelector instead.')
typedef MicSelector = FlutterMicSelector;

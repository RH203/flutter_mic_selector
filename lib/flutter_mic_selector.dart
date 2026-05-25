import 'dart:async';

import 'package:flutter/foundation.dart';

import 'flutter_mic_selector_platform_interface.dart';
import 'src/models/mic_input_device.dart';
import 'src/models/mic_input_level.dart';
import 'src/models/mic_permission_status.dart';
import 'src/models/mic_selector_state.dart';

export 'src/models/mic_error.dart';
export 'src/models/mic_input_device.dart';
export 'src/models/mic_input_level.dart';
export 'src/models/mic_permission_status.dart';
export 'src/models/mic_selector_state.dart';
export 'src/widgets/mic_selector_builder.dart';
export 'src/widgets/mic_selector_dropdown.dart';
export 'src/widgets/mic_selector_view.dart';

/// Public entry point for microphone input device selection.
///
/// The selected device is restored from native storage during initialization,
/// but the microphone remains inactive until [start] is called.
class MicSelector {
  MicSelector._({
    required FlutterMicSelectorPlatform platform,
  }) : _platform = platform {
    _initialization = _initialize();
  }

  static MicSelector? _instance;

  /// Singleton instance using the default platform implementation.
  static MicSelector get instance {
    return _instance ??= MicSelector._(
      platform: FlutterMicSelectorPlatform.instance,
    );
  }

  /// Creates an isolated selector for tests or advanced dependency injection.
  @visibleForTesting
  factory MicSelector.test({
    required FlutterMicSelectorPlatform platform,
  }) {
    return MicSelector._(platform: platform);
  }

  final FlutterMicSelectorPlatform _platform;
  final StreamController<MicSelectorState> _stateController =
      StreamController<MicSelectorState>.broadcast();

  late final Future<void> _initialization;
  StreamSubscription<List<MicInputDevice>>? _deviceSubscription;
  MicSelectorState _state = const MicSelectorState(devices: <MicInputDevice>[]);
  String? _selectedDeviceId;

  /// Whether the plugin currently owns an active microphone session.
  bool get isActive => _state.isActive;

  /// Returns available audio input devices.
  Future<List<MicInputDevice>> getDevices() async {
    await _initialization;
    final devices = await _platform.getDevices();
    _replaceDevices(devices);
    return devices;
  }

  /// Watches audio input device changes.
  Stream<List<MicInputDevice>> watchDevices() {
    return _platform.watchDevices();
  }

  /// Watches normalized microphone input levels while the session is active.
  ///
  /// Values are emitted by the native `AudioRecord` session used by [start].
  Stream<MicInputLevel> watchInputLevel() {
    return _platform.watchInputLevel();
  }

  /// Returns the restored or currently selected microphone input device.
  Future<MicInputDevice?> getSelectedDevice() async {
    await _initialization;
    return _state.selectedDevice;
  }

  /// Selects and persists the preferred microphone input device.
  Future<void> selectDevice(String deviceId) async {
    await _initialization;
    await _platform.selectDevice(deviceId);
    _selectedDeviceId = deviceId;
    _emit(_state.copyWith(selectedDevice: _deviceForId(deviceId)));
  }

  /// Clears the preferred microphone input device from native state.
  Future<void> clearSelectedDevice() async {
    await _initialization;
    await _platform.clearSelectedDevice();
    _selectedDeviceId = null;
    _emit(_state.copyWith(selectedDevice: null));
  }

  /// Starts an app-owned microphone activation session.
  ///
  /// This is the only API that activates the microphone. Restoring a saved
  /// device id never starts recording automatically.
  Future<void> start() async {
    await _initialization;
    await _platform.start(deviceId: _state.selectedDevice?.id);
    _emit(_state.copyWith(isActive: true));
  }

  /// Stops the app-owned microphone activation session.
  Future<void> stop() async {
    await _initialization;
    await _platform.stop();
    _emit(_state.copyWith(isActive: false));
  }

  /// Emits selector state changes for devices, selected device, and active flag.
  Stream<MicSelectorState> watchState() {
    late StreamController<MicSelectorState> controller;
    StreamSubscription<MicSelectorState>? subscription;

    controller = StreamController<MicSelectorState>(
      onListen: () {
        _initialization.then((_) {
          if (controller.isClosed) {
            return;
          }
          controller.add(_state);
          subscription = _stateController.stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
        }).catchError((Object error, StackTrace stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
          return null;
        });
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  /// Returns the current Android RECORD_AUDIO permission state.
  Future<MicPermissionStatus> hasPermission() {
    return _platform.hasPermission();
  }

  /// Requests Android RECORD_AUDIO permission.
  Future<MicPermissionStatus> requestPermission() {
    return _platform.requestPermission();
  }

  Future<void> _initialize() async {
    _selectedDeviceId = await _platform.getSelectedDeviceId();
    final devices = await _platform.getDevices();
    _replaceDevices(devices);
    if (_selectedDeviceId != null && _deviceForId(_selectedDeviceId!) != null) {
      await _platform.selectDevice(_selectedDeviceId!);
    }
    _deviceSubscription = _platform.watchDevices().listen(_replaceDevices);
  }

  void _replaceDevices(List<MicInputDevice> devices) {
    final nextDevices = List<MicInputDevice>.unmodifiable(devices);
    _emit(
      _state.copyWith(
        devices: nextDevices,
        selectedDevice: _selectedDeviceId == null
            ? null
            : _deviceForId(_selectedDeviceId!, nextDevices),
      ),
    );
  }

  MicInputDevice? _deviceForId(String id, [List<MicInputDevice>? devices]) {
    for (final device in devices ?? _state.devices) {
      if (device.id == id) {
        return device;
      }
    }
    return null;
  }

  void _emit(MicSelectorState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Releases stream subscriptions held by this selector.
  @visibleForTesting
  Future<void> dispose() async {
    await _deviceSubscription?.cancel();
    await _stateController.close();
  }
}

/// Backward-compatible alias for the main plugin entry point.
typedef FlutterMicSelector = MicSelector;

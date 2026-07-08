import 'dart:async';

import 'package:flutter_mic_selector/flutter_mic_selector.dart';
import 'package:flutter_mic_selector/flutter_mic_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ---------------------------------------------------------------------------
// Fake platform implementing the new interface
// ---------------------------------------------------------------------------

class FakeFlutterMicSelectorPlatform
    with MockPlatformInterfaceMixin
    implements FlutterMicSelectorPlatform {
  final StreamController<List<MicrophoneDevice>> deviceChanges =
      StreamController<List<MicrophoneDevice>>.broadcast();

  final List<String> calls = <String>[];
  List<MicrophoneDevice> devices = const <MicrophoneDevice>[
    MicrophoneDevice(
      id: '1',
      name: 'Built-in mic',
      type: MicrophoneType.builtIn,
    ),
    MicrophoneDevice(id: '2', name: 'USB mic', type: MicrophoneType.usb),
  ];
  String? nativeSelectedDeviceId;
  bool permissionGranted = true;

  @override
  Future<List<MicrophoneDevice>> getAvailableMicrophones() async {
    calls.add('getAvailableMicrophones');
    return devices;
  }

  @override
  Stream<List<MicrophoneDevice>> microphoneDevicesChanged() =>
      deviceChanges.stream;

  @override
  Future<MicrophoneDevice?> getSelectedMicrophone() async {
    calls.add('getSelectedMicrophone');
    if (nativeSelectedDeviceId == null) return null;
    try {
      return devices.firstWhere((d) => d.id == nativeSelectedDeviceId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> selectMicrophone(MicrophoneDevice device) {
    return selectMicrophoneById(device.id);
  }

  @override
  Future<void> selectMicrophoneById(String deviceId) async {
    calls.add('selectMicrophoneById:$deviceId');
    if (!devices.any((d) => d.id == deviceId)) {
      throw MicrophoneNotFoundException(
        'No input device exists for id $deviceId.',
        deviceId,
      );
    }
    nativeSelectedDeviceId = deviceId;
  }

  @override
  Future<void> clearSelectedMicrophone() async {
    calls.add('clearSelectedMicrophone');
    nativeSelectedDeviceId = null;
  }

  @override
  Future<bool> hasPermission() async {
    calls.add('hasPermission');
    return permissionGranted;
  }

  @override
  Future<bool> requestPermission() async {
    calls.add('requestPermission');
    return permissionGranted;
  }

  Future<void> close() async {
    await deviceChanges.close();
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FlutterMicSelector', () {
    late FakeFlutterMicSelectorPlatform platform;
    late FlutterMicSelector selector;

    setUp(() {
      platform = FakeFlutterMicSelectorPlatform();
      selector = FlutterMicSelector.test(platform: platform);
    });

    tearDown(() async {
      await selector.dispose();
      await platform.close();
    });

    test('getAvailableMicrophones returns device list', () async {
      final devices = await selector.getAvailableMicrophones();
      expect(devices, hasLength(2));
      expect(devices.first.id, '1');
      expect(devices.first.type, MicrophoneType.builtIn);
    });

    test('getAvailableMicrophones updates internal device list', () async {
      final devices = await selector.getAvailableMicrophones();
      expect(devices.length, 2);
    });

    test('getSelectedMicrophone returns null when nothing selected', () async {
      final device = await selector.getSelectedMicrophone();
      expect(device, isNull);
    });

    test('selectMicrophoneById selects device', () async {
      await selector.selectMicrophoneById('1');
      expect(platform.nativeSelectedDeviceId, '1');
      expect(platform.calls, contains('selectMicrophoneById:1'));
    });

    test('selectMicrophoneById throws for unknown id', () async {
      expect(
        () => selector.selectMicrophoneById('99'),
        throwsA(isA<MicrophoneNotFoundException>()),
      );
    });

    test('selectMicrophone delegates to selectMicrophoneById', () async {
      final device = MicrophoneDevice(
        id: '2',
        name: 'USB mic',
        type: MicrophoneType.usb,
      );
      await selector.selectMicrophone(device);
      expect(platform.nativeSelectedDeviceId, '2');
    });

    test('getSelectedMicrophone returns selected device', () async {
      await selector.selectMicrophoneById('2');
      final device = await selector.getSelectedMicrophone();
      expect(device, isNotNull);
      expect(device!.id, '2');
      expect(device.name, 'USB mic');
    });

    test('clearSelectedMicrophone clears selection', () async {
      await selector.selectMicrophoneById('1');
      await selector.clearSelectedMicrophone();
      expect(platform.nativeSelectedDeviceId, isNull);
      final device = await selector.getSelectedMicrophone();
      expect(device, isNull);
    });

    test('hasPermission delegates to platform', () async {
      final result = await selector.hasPermission();
      expect(result, isTrue);
      expect(platform.calls, contains('hasPermission'));
    });

    test('requestPermission delegates to platform', () async {
      final result = await selector.requestPermission();
      expect(result, isTrue);
      expect(platform.calls, contains('requestPermission'));
    });

    test('microphoneDevicesChanged emits device list', () async {
      final future = selector.microphoneDevicesChanged.first;
      platform.deviceChanges.add(platform.devices);
      final devices = await future;
      expect(devices, hasLength(2));
    });

    test('microphoneDevicesChanged emits updated devices', () async {
      final future = selector.microphoneDevicesChanged.first;
      platform.devices = const <MicrophoneDevice>[
        MicrophoneDevice(
          id: '3',
          name: 'New mic',
          type: MicrophoneType.bluetooth,
        ),
      ];
      platform.deviceChanges.add(platform.devices);
      final devices = await future;
      expect(devices, hasLength(1));
      expect(devices.first.id, '3');
    });

    test('successive selectMicrophoneById updates selection', () async {
      await selector.selectMicrophoneById('1');
      expect(platform.nativeSelectedDeviceId, '1');

      await selector.selectMicrophoneById('2');
      expect(platform.nativeSelectedDeviceId, '2');
    });
  });
}

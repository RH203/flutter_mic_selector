import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mic_selector/flutter_mic_selector.dart';
import 'package:flutter_mic_selector/flutter_mic_selector_method_channel.dart';
import 'package:flutter_mic_selector/flutter_mic_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ---------------------------------------------------------------------------
// Fake platform
// ---------------------------------------------------------------------------

class FakeMicSelectorPlatform
    with MockPlatformInterfaceMixin
    implements FlutterMicSelectorPlatform {
  final StreamController<List<MicInputDevice>> deviceChanges =
      StreamController<List<MicInputDevice>>.broadcast();
  final StreamController<MicInputLevel> levelChanges =
      StreamController<MicInputLevel>.broadcast();

  final List<String> calls = <String>[];
  List<MicInputDevice> devices = const <MicInputDevice>[
    MicInputDevice(id: '1', name: 'Built-in mic', type: 'builtInMic'),
    MicInputDevice(id: '2', name: 'USB mic', type: 'usbDevice'),
  ];
  String? nativeSelectedDeviceId;
  MicPermissionStatus permissionStatus = MicPermissionStatus.granted;

  @override
  Future<void> clearSelectedDevice() async {
    calls.add('clearSelectedDevice');
    nativeSelectedDeviceId = null;
  }

  @override
  Future<List<MicInputDevice>> getDevices() async {
    calls.add('getDevices');
    return devices;
  }

  @override
  Future<String?> getSelectedDeviceId() async {
    calls.add('getSelectedDeviceId');
    return nativeSelectedDeviceId;
  }

  @override
  Future<MicPermissionStatus> hasPermission() async {
    calls.add('hasPermission');
    return permissionStatus;
  }

  @override
  Future<MicPermissionStatus> requestPermission() async {
    calls.add('requestPermission');
    return permissionStatus;
  }

  @override
  Future<void> selectDevice(String deviceId) async {
    calls.add('selectDevice:$deviceId');
    if (!devices.any((device) => device.id == deviceId)) {
      throw MicException(
        MicError(
          code: MicErrorCode.deviceNotFound,
          message: 'No input device exists for id $deviceId.',
        ),
      );
    }
    nativeSelectedDeviceId = deviceId;
  }

  @override
  Future<void> start({String? deviceId}) async {
    calls.add('start:$deviceId');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Stream<List<MicInputDevice>> watchDevices() => deviceChanges.stream;

  @override
  Stream<MicInputLevel> watchInputLevel() => levelChanges.stream;

  Future<void> close() async {
    await deviceChanges.close();
    await levelChanges.close();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MicInputDevice _device({
  String id = '1',
  String name = 'Built-in mic',
  String type = 'builtInMic',
  bool isDefault = false,
}) {
  return MicInputDevice(id: id, name: name, type: type, isDefault: isDefault);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // --- Platform default -------------------------------------------------------

  test('$MethodChannelFlutterMicSelector is the default instance', () {
    expect(
      FlutterMicSelectorPlatform.instance,
      isInstanceOf<MethodChannelFlutterMicSelector>(),
    );
  });

  // --- MicInputDevice ---------------------------------------------------------

  group('MicInputDevice', () {
    test('fromMap / toMap round-trip preserves all fields', () {
      const device = MicInputDevice(
        id: '7',
        name: 'USB mic',
        type: 'usbDevice',
        typeId: 11,
        typeLabel: 'USB microphone',
        rawName: 'Blue Yeti',
        address: 'card0',
        isDefault: true,
      );
      final map = device.toMap();
      final restored = MicInputDevice.fromMap(map);
      expect(restored, equals(device));
    });

    test('fromMap handles missing optional fields gracefully', () {
      final device = MicInputDevice.fromMap(<Object?, Object?>{'id': '5'});
      expect(device.id, '5');
      expect(device.name, 'Microphone');
      expect(device.type, 'unknown');
      expect(device.typeId, isNull);
      expect(device.isDefault, isFalse);
    });

    test('displayName appends (default) when isDefault is true', () {
      final device = _device(name: 'Built-in', isDefault: true);
      expect(device.displayName, 'Built-in (default)');
    });

    test('effectiveTypeLabel falls back to MicInputDeviceTypes.labelFor', () {
      const device = MicInputDevice(
        id: '1',
        name: 'Headset',
        type: MicInputDeviceTypes.bluetoothSco,
      );
      expect(device.effectiveTypeLabel, 'Bluetooth headset microphone');
    });

    test('effectiveTypeLabel uses provided typeLabel over computed fallback',
        () {
      const device = MicInputDevice(
        id: '1',
        name: 'Headset',
        type: 'usbDevice',
        typeLabel: 'Custom label',
      );
      expect(device.effectiveTypeLabel, 'Custom label');
    });

    test('equality ignores object identity', () {
      const a = MicInputDevice(id: '1', name: 'Mic', type: 'builtInMic');
      const b = MicInputDevice(id: '1', name: 'Mic', type: 'builtInMic');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('MicInputDeviceTypes.labelFor returns known labels', () {
      expect(
        MicInputDeviceTypes.labelFor(MicInputDeviceTypes.usbDevice),
        'USB microphone',
      );
      expect(
        MicInputDeviceTypes.labelFor(MicInputDeviceTypes.hdmiEarc),
        'HDMI eARC audio input',
      );
    });

    test('MicInputDeviceTypes.labelFor returns fallback for unknown type', () {
      expect(MicInputDeviceTypes.labelFor('unmappedType'), 'Audio input');
    });
  });

  // --- MicInputLevel ----------------------------------------------------------

  group('MicInputLevel', () {
    test('fromMap parses valid values', () {
      final level = MicInputLevel.fromMap(<Object?, Object?>{
        'rms': 0.5,
        'peak': 0.8,
      });
      expect(level.rms, 0.5);
      expect(level.peak, 0.8);
    });

    test('fromMap clamps values above 1.0', () {
      final level = MicInputLevel.fromMap(<Object?, Object?>{
        'rms': 1.5,
        'peak': 3.0,
      });
      expect(level.rms, 1.0);
      expect(level.peak, 1.0);
    });

    test('fromMap clamps negative values to 0.0', () {
      final level = MicInputLevel.fromMap(<Object?, Object?>{
        'rms': -0.3,
        'peak': -1.0,
      });
      expect(level.rms, 0.0);
      expect(level.peak, 0.0);
    });

    test('fromMap returns 0 for non-numeric entries', () {
      final level = MicInputLevel.fromMap(<Object?, Object?>{
        'rms': 'bad',
        'peak': null,
      });
      expect(level.rms, 0.0);
      expect(level.peak, 0.0);
    });

    test('equality and hashCode', () {
      const a = MicInputLevel(rms: 0.3, peak: 0.7);
      const b = MicInputLevel(rms: 0.3, peak: 0.7);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  // --- MicSelectorState -------------------------------------------------------

  group('MicSelectorState', () {
    const device = MicInputDevice(id: '1', name: 'Built-in', type: 'builtInMic');
    const state = MicSelectorState(
      devices: <MicInputDevice>[device],
      selectedDevice: device,
      isActive: true,
    );

    test('copyWith replaces individual fields', () {
      final next = state.copyWith(isActive: false);
      expect(next.isActive, isFalse);
      expect(next.selectedDevice, device);
      expect(next.devices, <MicInputDevice>[device]);
    });

    test('copyWith with null selectedDevice clears the field via sentinel', () {
      final next = state.copyWith(selectedDevice: null);
      expect(next.selectedDevice, isNull);
      expect(next.isActive, isTrue);
    });

    test('copyWith without selectedDevice preserves existing value', () {
      final next = state.copyWith(isActive: false);
      expect(next.selectedDevice, device);
    });
  });

  // --- MicError / MicException ------------------------------------------------

  group('MicError', () {
    test('toString includes code and message', () {
      const error = MicError(
        code: MicErrorCode.permissionDenied,
        message: 'Permission was denied.',
      );
      expect(error.toString(), contains('permissionDenied'));
      expect(error.toString(), contains('Permission was denied.'));
    });

    test('MicException toString delegates to MicError', () {
      const exception = MicException(
        MicError(
          code: MicErrorCode.deviceNotFound,
          message: 'No device.',
        ),
      );
      expect(exception.toString(), contains('deviceNotFound'));
    });
  });

  // --- MicSelector (integration with fake platform) ---------------------------

  group('MicSelector', () {
    late FakeMicSelectorPlatform platform;
    late MicSelector selector;

    setUp(() {
      platform = FakeMicSelectorPlatform();
      selector = MicSelector.test(platform: platform);
    });

    tearDown(() async {
      await selector.dispose();
      await platform.close();
    });

    test('restores selected device without starting microphone', () async {
      platform.nativeSelectedDeviceId = '2';
      selector = MicSelector.test(platform: platform);

      expect(await selector.getSelectedDevice(), platform.devices[1]);
      expect(selector.isActive, isFalse);
      expect(platform.calls, contains('selectDevice:2'));
      expect(
        platform.calls.any((call) => call.startsWith('start')),
        isFalse,
      );
    });

    test('ignores unavailable restored device until it appears again', () async {
      platform.nativeSelectedDeviceId = '9';
      selector = MicSelector.test(platform: platform);

      expect(await selector.getSelectedDevice(), isNull);
      expect(platform.calls, isNot(contains('selectDevice:9')));

      await selector.start();
      expect(platform.calls, contains('start:null'));

      platform.devices = const <MicInputDevice>[
        MicInputDevice(
          id: '9',
          name: 'USB mic',
          type: MicInputDeviceTypes.usbDevice,
        ),
      ];
      platform.deviceChanges.add(platform.devices);

      final next = await selector.watchState().firstWhere(
            (state) => state.selectedDevice?.id == '9',
          );
      expect(next.selectedDevice?.effectiveTypeLabel, 'USB microphone');
    });

    test('selects, persists, starts, stops, and clears state', () async {
      await selector.selectDevice('1');
      await selector.start();
      await selector.stop();
      await selector.clearSelectedDevice();

      expect(platform.nativeSelectedDeviceId, isNull);
      expect(
        platform.calls,
        containsAll(<String>[
          'selectDevice:1',
          'start:1',
          'stop',
          'clearSelectedDevice',
        ]),
      );
      expect(selector.isActive, isFalse);
      expect(await selector.getSelectedDevice(), isNull);
    });

    test('selectDevice throws MicException for unknown id', () async {
      expect(
        () => selector.selectDevice('99'),
        throwsA(
          isA<MicException>().having(
            (e) => e.error.code,
            'code',
            MicErrorCode.deviceNotFound,
          ),
        ),
      );
    });

    test('device change updates selected device snapshot', () async {
      platform.nativeSelectedDeviceId = '2';
      selector = MicSelector.test(platform: platform);
      expect((await selector.watchState().first).selectedDevice?.id, '2');

      platform.devices = const <MicInputDevice>[
        MicInputDevice(id: '3', name: 'Bluetooth mic', type: 'bluetoothSco'),
      ];
      platform.deviceChanges.add(platform.devices);

      final next = await selector.watchState().firstWhere(
            (state) =>
                state.devices.isNotEmpty && state.devices.first.id == '3',
          );
      expect(next.selectedDevice, isNull);
    });

    test('watchState emits current state immediately on subscribe', () async {
      await selector.selectDevice('1');
      final state = await selector.watchState().first;
      expect(state.selectedDevice?.id, '1');
    });

    test('watchInputLevel forwards platform stream', () async {
      const expectedLevel = MicInputLevel(rms: 0.4, peak: 0.9);
      final future = selector.watchInputLevel().first;
      platform.levelChanges.add(expectedLevel);
      expect(await future, expectedLevel);
    });

    test('hasPermission delegates to platform', () async {
      await selector.hasPermission();
      expect(platform.calls, contains('hasPermission'));
    });

    test('requestPermission delegates to platform', () async {
      await selector.requestPermission();
      expect(platform.calls, contains('requestPermission'));
    });

    test('isActive reflects start/stop', () async {
      expect(selector.isActive, isFalse);
      await selector.start();
      expect(selector.isActive, isTrue);
      await selector.stop();
      expect(selector.isActive, isFalse);
    });
  });

  // --- Widget tests -----------------------------------------------------------

  group('Widgets', () {
    late FakeMicSelectorPlatform platform;
    late MicSelector selector;

    setUp(() {
      platform = FakeMicSelectorPlatform();
      selector = MicSelector.test(platform: platform);
    });

    tearDown(() async {
      await selector.dispose();
      await platform.close();
    });

    testWidgets('MicSelectorDropdown renders device list items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicSelectorDropdown(selector: selector),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'MicSelectorDropdown truncates long device names in narrow layouts',
      (tester) async {
        platform.devices = const <MicInputDevice>[
          MicInputDevice(
            id: '1',
            name: 'USB microphone with a very long product name that should '
                'not overflow the layout under any circumstances whatsoever',
            type: MicInputDeviceTypes.usbDevice,
          ),
        ];
        selector = MicSelector.test(platform: platform);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 140,
                child: MicSelectorDropdown(selector: selector),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      },
    );

    testWidgets('MicSelectorView shows Enable and Disable buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicSelectorView(selector: selector),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Enable'), findsOneWidget);
      expect(find.text('Disable'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MicSelectorBuilder rebuilds on state change', (tester) async {
      // Use an isolated platform + selector so setUp doesn't interfere.
      final localPlatform = FakeMicSelectorPlatform();
      final localSelector = MicSelector.test(platform: localPlatform);

      // Pre-await initialization so the first watchState() state-emission
      // fires before we start pumping — avoids the pumpAndSettle() infinite
      // loop caused by watchState() emitting asynchronously post-init.
      await localSelector.getSelectedDevice();

      final buildCount = <int>[0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicSelectorBuilder(
              selector: localSelector,
              builder: (context, state, _) {
                buildCount[0]++;
                return Text('devices:${state.devices.length}');
              },
            ),
          ),
        ),
      );
      // Drain the microtask queue (stream emission) then process the rebuild.
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.text('devices:2'), findsOneWidget,
          reason: 'Initial state should show 2 devices from FakeMicSelectorPlatform');
      final countAfterInit = buildCount[0];

      // Push a device-list update and let the StreamBuilder rebuild.
      localPlatform.devices = const <MicInputDevice>[
        MicInputDevice(id: '3', name: 'New mic', type: 'usbDevice'),
      ];
      localPlatform.deviceChanges.add(localPlatform.devices);
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(find.text('devices:1'), findsOneWidget);
      expect(buildCount[0], greaterThan(countAfterInit));

      await localSelector.dispose();
      await localPlatform.close();
    });

    testWidgets('MicSelectorView shows empty dropdown when no devices',
        (tester) async {
      platform.devices = const <MicInputDevice>[];
      selector = MicSelector.test(platform: platform);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicSelectorView(selector: selector),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

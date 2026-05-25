import 'package:flutter/services.dart';
import 'package:flutter_mic_selector/flutter_mic_selector.dart';
import 'package:flutter_mic_selector/flutter_mic_selector_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterMicSelector platform;
  const channel = MethodChannel('flutter_mic_selector');
  final calls = <MethodCall>[];

  setUp(() {
    platform = MethodChannelFlutterMicSelector();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      calls.add(methodCall);
      return switch (methodCall.method) {
        'getDevices' => <Map<String, Object?>>[
            <String, Object?>{
              'id': '7',
              'name': 'USB mic',
              'type': 'usbDevice',
              'typeId': 11,
              'typeLabel': 'USB microphone',
              'isDefault': false,
            },
          ],
        'getSelectedDeviceId' => '7',
        'hasPermission' => 'granted',
        'requestPermission' => 'denied',
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    calls.clear();
  });

  test('getDevices parses platform maps', () async {
    final devices = await platform.getDevices();

    expect(devices, hasLength(1));
    expect(devices.single.id, '7');
    expect(devices.single.type, 'usbDevice');
    expect(devices.single.typeId, 11);
    expect(devices.single.effectiveTypeLabel, 'USB microphone');
  });

  test('device type constants provide readable fallback labels', () {
    const device = MicInputDevice(
      id: '8',
      name: 'Headset',
      type: MicInputDeviceTypes.bluetoothSco,
    );

    expect(device.effectiveTypeLabel, 'Bluetooth headset microphone');
    expect(
      MicInputDeviceTypes.labelFor(MicInputDeviceTypes.hdmiEarc),
      'HDMI eARC audio input',
    );
  });

  test('commands use expected method names and arguments', () async {
    expect(await platform.getSelectedDeviceId(), '7');
    await platform.selectDevice('7');
    await platform.start(deviceId: '7');
    await platform.stop();
    await platform.clearSelectedDevice();

    expect(calls.map((call) => call.method), <String>[
      'getSelectedDeviceId',
      'selectDevice',
      'start',
      'stop',
      'clearSelectedDevice',
    ]);
    expect(calls[1].arguments, <String, Object?>{'deviceId': '7'});
  });

  test('start without a selected device omits stale null arguments', () async {
    await platform.start();

    expect(calls.single.method, 'start');
    expect(calls.single.arguments, isNull);
  });

  test('parses permission statuses', () async {
    expect(await platform.hasPermission(), MicPermissionStatus.granted);
    expect(await platform.requestPermission(), MicPermissionStatus.denied);
  });

  test('maps MissingPluginException to platformNotSupported', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    expect(
      platform.getDevices,
      throwsA(
        isA<MicException>().having(
          (error) => error.error.code,
          'code',
          MicErrorCode.platformNotSupported,
        ),
      ),
    );
  });
}

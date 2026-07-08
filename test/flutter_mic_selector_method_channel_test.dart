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
            'selectDevice' => null,
            'clearSelectedDevice' => null,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    calls.clear();
  });

  test('getAvailableMicrophones parses platform maps', () async {
    final devices = await platform.getAvailableMicrophones();

    expect(devices, hasLength(1));
    expect(devices.single.id, '7');
    expect(devices.single.type, MicrophoneType.usb);
  });

  test('commands use expected method names and arguments', () async {
    await platform.selectMicrophoneById('7');
    await platform.clearSelectedMicrophone();

    expect(calls.map((call) => call.method), <String>[
      'selectDevice',
      'clearSelectedDevice',
    ]);
    expect(calls[0].arguments, <String, Object?>{'deviceId': '7'});
  });

  test('getSelectedMicrophone resolves device from id', () async {
    final device = await platform.getSelectedMicrophone();
    expect(device, isNotNull);
    expect(device!.id, '7');
    expect(device.type, MicrophoneType.usb);
  });

  test('getSelectedMicrophone returns null when no id stored', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          return switch (methodCall.method) {
            'getSelectedDeviceId' => null,
            'getDevices' => <Map<String, Object?>>[],
            _ => null,
          };
        });

    final device = await platform.getSelectedMicrophone();
    expect(device, isNull);
  });

  test('hasPermission returns true when granted', () async {
    expect(await platform.hasPermission(), isTrue);
  });

  test('requestPermission returns false when denied', () async {
    expect(await platform.requestPermission(), isFalse);
  });

  test(
    'maps MissingPluginException to UnsupportedMicrophoneException',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      expect(
        platform.getAvailableMicrophones,
        throwsA(isA<UnsupportedMicrophoneException>()),
      );
    },
  );

  test(
    'maps deviceNotFound error code to MicrophoneNotFoundException',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            throw PlatformException(
              code: 'deviceNotFound',
              message: 'No input device exists for id 99.',
            );
          });

      expect(
        () => platform.selectMicrophoneById('99'),
        throwsA(isA<MicrophoneNotFoundException>()),
      );
    },
  );
}

import 'package:flutter_mic_selector/flutter_mic_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MicrophoneType', () {
    test('fromAndroidType maps built-in types', () {
      expect(
        MicrophoneType.fromAndroidType('builtInMic'),
        MicrophoneType.builtIn,
      );
      expect(
        MicrophoneType.fromAndroidType('builtInEarpiece'),
        MicrophoneType.builtIn,
      );
      expect(
        MicrophoneType.fromAndroidType('builtInSpeaker'),
        MicrophoneType.builtIn,
      );
    });

    test('fromAndroidType maps wired headset types', () {
      expect(
        MicrophoneType.fromAndroidType('wiredHeadset'),
        MicrophoneType.wiredHeadset,
      );
      expect(
        MicrophoneType.fromAndroidType('wiredHeadphones'),
        MicrophoneType.wiredHeadset,
      );
      expect(
        MicrophoneType.fromAndroidType('lineAnalog'),
        MicrophoneType.wiredHeadset,
      );
      expect(
        MicrophoneType.fromAndroidType('lineDigital'),
        MicrophoneType.wiredHeadset,
      );
    });

    test('fromAndroidType maps bluetooth types', () {
      expect(
        MicrophoneType.fromAndroidType('bluetoothSco'),
        MicrophoneType.bluetooth,
      );
      expect(
        MicrophoneType.fromAndroidType('bluetoothA2dp'),
        MicrophoneType.bluetooth,
      );
      expect(
        MicrophoneType.fromAndroidType('bleHeadset'),
        MicrophoneType.bluetooth,
      );
      expect(
        MicrophoneType.fromAndroidType('bleSpeaker'),
        MicrophoneType.bluetooth,
      );
      expect(
        MicrophoneType.fromAndroidType('bleBroadcast'),
        MicrophoneType.bluetooth,
      );
    });

    test('fromAndroidType maps usb types', () {
      expect(MicrophoneType.fromAndroidType('usbDevice'), MicrophoneType.usb);
      expect(MicrophoneType.fromAndroidType('usbHeadset'), MicrophoneType.usb);
      expect(
        MicrophoneType.fromAndroidType('usbAccessory'),
        MicrophoneType.usb,
      );
    });

    test('fromAndroidType maps telephony', () {
      expect(
        MicrophoneType.fromAndroidType('telephony'),
        MicrophoneType.telephony,
      );
    });

    test('fromAndroidType returns unknown for unmapped types', () {
      expect(MicrophoneType.fromAndroidType('hdmi'), MicrophoneType.unknown);
      expect(MicrophoneType.fromAndroidType('dock'), MicrophoneType.unknown);
      expect(MicrophoneType.fromAndroidType('fm'), MicrophoneType.unknown);
      expect(MicrophoneType.fromAndroidType(''), MicrophoneType.unknown);
    });

    test('label returns human-readable strings', () {
      expect(MicrophoneType.builtIn.label, 'Built-in microphone');
      expect(MicrophoneType.wiredHeadset.label, 'Wired headset microphone');
      expect(MicrophoneType.bluetooth.label, 'Bluetooth microphone');
      expect(MicrophoneType.usb.label, 'USB microphone');
      expect(MicrophoneType.telephony.label, 'Telephony microphone');
      expect(MicrophoneType.unknown.label, 'Unknown audio input');
    });
  });

  group('MicrophoneDevice', () {
    test('fromMap parses platform map correctly', () {
      final device = MicrophoneDevice.fromMap(<Object?, Object?>{
        'id': '7',
        'name': 'USB microphone',
        'type': 'usbDevice',
        'isDefault': true,
      });

      expect(device.id, '7');
      expect(device.name, 'USB microphone');
      expect(device.type, MicrophoneType.usb);
      expect(device.isInput, isTrue);
      expect(device.isSelected, isTrue);
    });

    test('fromMap handles missing optional fields', () {
      final device = MicrophoneDevice.fromMap(<Object?, Object?>{'id': '5'});

      expect(device.id, '5');
      expect(device.name, 'Microphone');
      expect(device.type, MicrophoneType.unknown);
      expect(device.isInput, isTrue);
      expect(device.isSelected, isFalse);
    });

    test('fromMap handles empty id', () {
      final device = MicrophoneDevice.fromMap(<Object?, Object?>{});

      expect(device.id, '');
      expect(device.isInput, isTrue);
      expect(device.isSelected, isFalse);
    });

    test('toMap / fromMap round-trip', () {
      const device = MicrophoneDevice(
        id: '3',
        name: 'Bluetooth headset',
        type: MicrophoneType.bluetooth,
        isInput: true,
        isSelected: true,
      );

      final map = device.toMap();
      final restored = MicrophoneDevice.fromMap(map);

      expect(restored.id, device.id);
      expect(restored.name, device.name);
      expect(restored.type, MicrophoneType.bluetooth);
      expect(restored.isInput, isTrue);
      expect(restored.isSelected, isTrue);
    });

    test('copyWith replaces fields', () {
      const device = MicrophoneDevice(
        id: '1',
        name: 'Built-in mic',
        type: MicrophoneType.builtIn,
      );

      final copied = device.copyWith(
        name: 'External mic',
        type: MicrophoneType.usb,
        isSelected: true,
      );

      expect(copied.id, '1');
      expect(copied.name, 'External mic');
      expect(copied.type, MicrophoneType.usb);
      expect(copied.isSelected, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      const device = MicrophoneDevice(
        id: '1',
        name: 'Built-in mic',
        type: MicrophoneType.builtIn,
      );

      final copied = device.copyWith(name: 'Updated');

      expect(copied.id, '1');
      expect(copied.type, MicrophoneType.builtIn);
      expect(copied.isInput, isTrue);
      expect(copied.isSelected, isFalse);
    });

    test('equality compares all fields', () {
      const a = MicrophoneDevice(
        id: '1',
        name: 'Mic',
        type: MicrophoneType.builtIn,
      );
      const b = MicrophoneDevice(
        id: '1',
        name: 'Mic',
        type: MicrophoneType.builtIn,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality detects field differences', () {
      const a = MicrophoneDevice(
        id: '1',
        name: 'Mic',
        type: MicrophoneType.builtIn,
      );
      const b = MicrophoneDevice(
        id: '2',
        name: 'Mic',
        type: MicrophoneType.builtIn,
      );

      expect(a, isNot(equals(b)));
    });

    test('toString includes id and name', () {
      const device = MicrophoneDevice(
        id: '3',
        name: 'Test mic',
        type: MicrophoneType.usb,
      );

      final str = device.toString();
      expect(str, contains('3'));
      expect(str, contains('Test mic'));
      expect(str, contains('usb'));
    });
  });

  group('Typed exceptions', () {
    test('MicrophoneNotFoundException includes message and deviceId', () {
      final e = MicrophoneNotFoundException('Not found.', '42');
      expect(e.message, 'Not found.');
      expect(e.deviceId, '42');
      expect(e.toString(), contains('42'));
    });

    test('MicrophoneSelectionException includes message and deviceId', () {
      final e = MicrophoneSelectionException('Failed.', '7');
      expect(e.message, 'Failed.');
      expect(e.deviceId, '7');
    });

    test('MicrophonePermissionException includes message', () {
      final e = MicrophonePermissionException('Permission required.');
      expect(e.message, 'Permission required.');
    });

    test('UnsupportedMicrophoneException includes message', () {
      final e = UnsupportedMicrophoneException('Not supported.');
      expect(e.message, 'Not supported.');
    });
  });
}

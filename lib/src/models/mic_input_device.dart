/// Describes an audio input device that Android can expose to the app.
class MicInputDevice {
  /// Creates an immutable microphone input device description.
  const MicInputDevice({
    required this.id,
    required this.name,
    required this.type,
    this.typeId,
    this.typeLabel,
    this.rawName,
    this.address,
    this.isDefault = false,
  });

  /// Stable Android audio device id represented as a string.
  final String id;

  /// User-facing display name reported by the platform.
  final String name;

  /// Platform device type, such as `builtInMic`, `wiredHeadset`, or `usbDevice`.
  ///
  /// Compare this with [MicInputDeviceTypes] constants instead of hard-coded
  /// strings.
  final String type;

  /// Native Android `AudioDeviceInfo.TYPE_*` value, when available.
  final int? typeId;

  /// Human-friendly label for [type], suitable for showing in client UI.
  final String? typeLabel;

  /// Raw platform product name, when Android exposes one.
  final String? rawName;

  /// Platform device address, when Android exposes one.
  final String? address;

  /// Whether this entry represents the current default input route.
  final bool isDefault;

  /// Creates a device from a platform map.
  factory MicInputDevice.fromMap(Map<Object?, Object?> map) {
    return MicInputDevice(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Microphone',
      type: map['type']?.toString() ?? 'unknown',
      typeId: map['typeId'] is int ? map['typeId'] as int : null,
      typeLabel: map['typeLabel']?.toString(),
      rawName: map['rawName']?.toString(),
      address: map['address']?.toString(),
      isDefault: map['isDefault'] == true,
    );
  }

  /// Converts this device to a serializable map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'type': type,
      'typeId': typeId,
      'typeLabel': effectiveTypeLabel,
      'rawName': rawName,
      'address': address,
      'isDefault': isDefault,
    };
  }

  /// Best label for this device type.
  String get effectiveTypeLabel =>
      typeLabel ?? MicInputDeviceTypes.labelFor(type);

  /// Best single-line text for selectors and settings screens.
  String get displayName {
    if (isDefault) {
      return '$name (default)';
    }
    return name;
  }

  @override
  bool operator ==(Object other) {
    return other is MicInputDevice &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.typeId == typeId &&
        other.typeLabel == typeLabel &&
        other.rawName == rawName &&
        other.address == address &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        typeId,
        typeLabel,
        rawName,
        address,
        isDefault,
      );
}

/// Stable microphone input type values returned by [MicInputDevice.type].
abstract final class MicInputDeviceTypes {
  /// Unknown or unsupported input type.
  static const String unknown = 'unknown';

  /// Android `AudioDeviceInfo.TYPE_BUILTIN_MIC`.
  static const String builtInMic = 'builtInMic';

  /// Android `AudioDeviceInfo.TYPE_BUILTIN_EARPIECE`.
  static const String builtInEarpiece = 'builtInEarpiece';

  /// Android `AudioDeviceInfo.TYPE_BUILTIN_SPEAKER`.
  static const String builtInSpeaker = 'builtInSpeaker';

  /// Android `AudioDeviceInfo.TYPE_WIRED_HEADSET`.
  static const String wiredHeadset = 'wiredHeadset';

  /// Android `AudioDeviceInfo.TYPE_WIRED_HEADPHONES`.
  static const String wiredHeadphones = 'wiredHeadphones';

  /// Android `AudioDeviceInfo.TYPE_LINE_ANALOG`.
  static const String lineAnalog = 'lineAnalog';

  /// Android `AudioDeviceInfo.TYPE_LINE_DIGITAL`.
  static const String lineDigital = 'lineDigital';

  /// Android `AudioDeviceInfo.TYPE_USB_DEVICE`.
  static const String usbDevice = 'usbDevice';

  /// Android `AudioDeviceInfo.TYPE_USB_HEADSET`.
  static const String usbHeadset = 'usbHeadset';

  /// Android `AudioDeviceInfo.TYPE_USB_ACCESSORY`.
  static const String usbAccessory = 'usbAccessory';

  /// Android `AudioDeviceInfo.TYPE_BLUETOOTH_SCO`.
  static const String bluetoothSco = 'bluetoothSco';

  /// Android `AudioDeviceInfo.TYPE_BLUETOOTH_A2DP`.
  static const String bluetoothA2dp = 'bluetoothA2dp';

  /// Android `AudioDeviceInfo.TYPE_TELEPHONY`.
  static const String telephony = 'telephony';

  /// Android `AudioDeviceInfo.TYPE_HDMI`.
  static const String hdmi = 'hdmi';

  /// Android `AudioDeviceInfo.TYPE_HDMI_ARC`.
  static const String hdmiArc = 'hdmiArc';

  /// Android `AudioDeviceInfo.TYPE_HDMI_EARC`.
  static const String hdmiEarc = 'hdmiEarc';

  /// Android `AudioDeviceInfo.TYPE_AUX_LINE`.
  static const String auxLine = 'auxLine';

  /// Android `AudioDeviceInfo.TYPE_IP`.
  static const String ip = 'ip';

  /// Android `AudioDeviceInfo.TYPE_BUS`.
  static const String bus = 'bus';

  /// Android `AudioDeviceInfo.TYPE_DOCK`.
  static const String dock = 'dock';

  /// Android `AudioDeviceInfo.TYPE_FM`.
  static const String fm = 'fm';

  /// Android `AudioDeviceInfo.TYPE_FM_TUNER`.
  static const String fmTuner = 'fmTuner';

  /// Android `AudioDeviceInfo.TYPE_TV_TUNER`.
  static const String tvTuner = 'tvTuner';

  /// Android `AudioDeviceInfo.TYPE_HEARING_AID`.
  static const String hearingAid = 'hearingAid';

  /// Android `AudioDeviceInfo.TYPE_REMOTE_SUBMIX`.
  static const String remoteSubmix = 'remoteSubmix';

  /// Android `AudioDeviceInfo.TYPE_BLE_HEADSET`.
  static const String bleHeadset = 'bleHeadset';

  /// Android `AudioDeviceInfo.TYPE_BLE_SPEAKER`.
  static const String bleSpeaker = 'bleSpeaker';

  /// Android `AudioDeviceInfo.TYPE_BLE_BROADCAST`.
  static const String bleBroadcast = 'bleBroadcast';

  /// Returns a human-friendly label for a stable microphone type value.
  static String labelFor(String type) {
    return switch (type) {
      unknown => 'Unknown audio input',
      builtInMic => 'Built-in microphone',
      builtInEarpiece => 'Built-in earpiece',
      builtInSpeaker => 'Built-in speaker',
      wiredHeadset => 'Wired headset microphone',
      wiredHeadphones => 'Wired headphones',
      lineAnalog => 'Analog line input',
      lineDigital => 'Digital line input',
      usbDevice => 'USB microphone',
      usbHeadset => 'USB headset microphone',
      usbAccessory => 'USB accessory microphone',
      bluetoothSco => 'Bluetooth headset microphone',
      bluetoothA2dp => 'Bluetooth audio device',
      telephony => 'Telephony microphone',
      hdmi => 'HDMI audio input',
      hdmiArc => 'HDMI ARC audio input',
      hdmiEarc => 'HDMI eARC audio input',
      auxLine => 'Aux line input',
      ip => 'Network audio input',
      bus => 'Audio bus input',
      dock => 'Dock audio input',
      fm => 'FM audio input',
      fmTuner => 'FM tuner input',
      tvTuner => 'TV tuner input',
      hearingAid => 'Hearing aid microphone',
      remoteSubmix => 'Remote submix input',
      bleHeadset => 'Bluetooth LE headset microphone',
      bleSpeaker => 'Bluetooth LE speaker microphone',
      bleBroadcast => 'Bluetooth LE broadcast microphone',
      _ => 'Audio input',
    };
  }
}

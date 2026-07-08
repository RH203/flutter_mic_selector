/// Categorizes a microphone's physical or logical connection type.
enum MicrophoneType {
  /// Built-in microphone (earpiece, speaker, or mic).
  builtIn,

  /// Wired headset, headphones, or line input.
  wiredHeadset,

  /// Bluetooth or BLE headset microphone.
  bluetooth,

  /// USB microphone, headset, or accessory.
  usb,

  /// Telephony microphone.
  telephony,

  /// Unknown or unsupported input type.
  unknown;

  /// Maps an Android `AudioDeviceInfo.TYPE_*` string (as returned by
  /// [MicDeviceMapper.deviceTypeValue]) to a [MicrophoneType].
  static MicrophoneType fromAndroidType(String type) {
    return switch (type) {
      'builtInMic' || 'builtInEarpiece' || 'builtInSpeaker' => builtIn,
      'wiredHeadset' ||
      'wiredHeadphones' ||
      'lineAnalog' ||
      'lineDigital' => wiredHeadset,
      'bluetoothSco' ||
      'bluetoothA2dp' ||
      'bleHeadset' ||
      'bleSpeaker' ||
      'bleBroadcast' => bluetooth,
      'usbDevice' || 'usbHeadset' || 'usbAccessory' => usb,
      'telephony' => telephony,
      _ => unknown,
    };
  }

  /// Human-readable label for this type.
  String get label => switch (this) {
    builtIn => 'Built-in microphone',
    wiredHeadset => 'Wired headset microphone',
    bluetooth => 'Bluetooth microphone',
    usb => 'USB microphone',
    telephony => 'Telephony microphone',
    unknown => 'Unknown audio input',
  };
}

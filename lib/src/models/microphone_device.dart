import 'microphone_type.dart';

/// Describes a microphone input device available on the platform.
class MicrophoneDevice {
  /// Creates an immutable microphone device description.
  const MicrophoneDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isInput = true,
    this.isSelected = false,
  });

  /// Stable Android audio device id represented as a string.
  final String id;

  /// User-facing display name reported by the platform.
  final String name;

  /// Categorized device type.
  final MicrophoneType type;

  /// Whether this device is an input-capable device.
  ///
  /// Always `true` for microphones returned by this plugin.
  final bool isInput;

  /// Whether this device is the currently selected microphone.
  final bool isSelected;

  /// Creates a device from a platform map.
  ///
  /// Parses the same key format emitted by the native Android implementation
  /// (keys: `id`, `name`, `type`, `isDefault`). Also accepts [toMap] output
  /// where `type` is stored as an enum name string.
  factory MicrophoneDevice.fromMap(Map<Object?, Object?> map) {
    final typeValue = map['type']?.toString() ?? '';
    return MicrophoneDevice(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Microphone',
      type: _parseType(typeValue),
      isInput: true,
      isSelected: map['isDefault'] == true || map['isSelected'] == true,
    );
  }

  /// Parses [value] as a [MicrophoneType], accepting both Android type strings
  /// (e.g. `"usbDevice"`) and enum name strings (e.g. `"usb"`).
  static MicrophoneType _parseType(String value) {
    if (value.isEmpty) return MicrophoneType.unknown;
    // Try Android type string first.
    final fromAndroid = MicrophoneType.fromAndroidType(value);
    if (fromAndroid != MicrophoneType.unknown) return fromAndroid;
    // Fall back to enum name parsing.
    return MicrophoneType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => MicrophoneType.unknown,
    );
  }

  /// Converts this device to a serializable map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'type': type.name,
      'isInput': isInput,
      'isSelected': isSelected,
    };
  }

  /// Returns a copy with the given fields replaced.
  MicrophoneDevice copyWith({
    String? id,
    String? name,
    MicrophoneType? type,
    bool? isInput,
    bool? isSelected,
  }) {
    return MicrophoneDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isInput: isInput ?? this.isInput,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MicrophoneDevice &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.isInput == isInput &&
        other.isSelected == isSelected;
  }

  @override
  int get hashCode => Object.hash(id, name, type, isInput, isSelected);

  @override
  String toString() {
    return 'MicrophoneDevice(id: $id, name: $name, type: ${type.name}, '
        'isSelected: $isSelected)';
  }
}

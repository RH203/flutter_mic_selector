/// Current microphone input level emitted by the native recording session.
class MicInputLevel {
  /// Creates an immutable microphone input level snapshot.
  const MicInputLevel({
    required this.rms,
    required this.peak,
  });

  /// Root-mean-square level normalized from 0.0 to 1.0.
  final double rms;

  /// Peak sample level normalized from 0.0 to 1.0.
  final double peak;

  /// Creates a level snapshot from a platform map.
  factory MicInputLevel.fromMap(Map<Object?, Object?> map) {
    return MicInputLevel(
      rms: _normalizedDouble(map['rms']),
      peak: _normalizedDouble(map['peak']),
    );
  }

  /// Converts this level to a serializable map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'rms': rms,
      'peak': peak,
    };
  }

  static double _normalizedDouble(Object? value) {
    final number = value is num ? value.toDouble() : 0;
    return number.clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is MicInputLevel && other.rms == rms && other.peak == peak;
  }

  @override
  int get hashCode => Object.hash(rms, peak);
}

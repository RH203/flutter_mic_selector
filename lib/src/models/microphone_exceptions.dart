/// Exception thrown when a requested microphone device could not be found.
class MicrophoneNotFoundException implements Exception {
  /// Creates a microphone not found exception.
  const MicrophoneNotFoundException([
    this.message = 'The requested microphone device was not found.',
    this.deviceId,
  ]);

  /// Human-readable description of the error.
  final String message;

  /// The device ID that was not found, if available.
  final String? deviceId;

  @override
  String toString() {
    final info = deviceId != null ? ' (deviceId: $deviceId)' : '';
    return 'MicrophoneNotFoundException: $message$info';
  }
}

/// Exception thrown when a microphone selection operation fails.
class MicrophoneSelectionException implements Exception {
  /// Creates a microphone selection exception.
  const MicrophoneSelectionException([
    this.message = 'Failed to select the microphone device.',
    this.deviceId,
  ]);

  /// Human-readable description of the error.
  final String message;

  /// The device ID that could not be selected, if available.
  final String? deviceId;

  @override
  String toString() {
    final info = deviceId != null ? ' (deviceId: $deviceId)' : '';
    return 'MicrophoneSelectionException: $message$info';
  }
}

/// Exception thrown when microphone permission is missing.
class MicrophonePermissionException implements Exception {
  /// Creates a microphone permission exception.
  const MicrophonePermissionException([
    this.message = 'Microphone permission (RECORD_AUDIO) is required.',
  ]);

  /// Human-readable description of the error.
  final String message;

  @override
  String toString() => 'MicrophonePermissionException: $message';
}

/// Exception thrown when the requested operation is not supported.
class UnsupportedMicrophoneException implements Exception {
  /// Creates an unsupported microphone exception.
  const UnsupportedMicrophoneException([
    this.message = 'This operation is not supported on the current platform.',
  ]);

  /// Human-readable description of the error.
  final String message;

  @override
  String toString() => 'UnsupportedMicrophoneException: $message';
}

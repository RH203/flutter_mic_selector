/// Machine-readable error codes returned by the microphone selector.
enum MicErrorCode {
  /// The requested API is not implemented on the current platform.
  platformNotSupported,

  /// The app does not have Android RECORD_AUDIO permission.
  permissionDenied,

  /// The requested microphone device could not be found.
  deviceNotFound,

  /// The microphone session could not be started.
  activationFailed,

  /// An unexpected platform or plugin error occurred.
  unknown,
}

/// Structured microphone selector error information.
class MicError {
  /// Creates an immutable microphone selector error.
  const MicError({
    required this.code,
    required this.message,
    this.details,
  });

  /// Machine-readable code for the error.
  final MicErrorCode code;

  /// Human-readable diagnostic message.
  final String message;

  /// Optional platform-specific details.
  final Object? details;

  @override
  String toString() => 'MicError($code, $message)';
}

/// Exception thrown by the public Dart API when a platform operation fails.
class MicException implements Exception {
  /// Creates an exception from a structured [MicError].
  const MicException(this.error);

  /// Structured error payload.
  final MicError error;

  @override
  String toString() => error.toString();
}

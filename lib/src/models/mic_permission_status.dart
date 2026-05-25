/// Permission state for Android RECORD_AUDIO access.
enum MicPermissionStatus {
  /// The permission is granted and microphone activation can be attempted.
  granted,

  /// The permission is denied or has not been requested yet.
  denied,

  /// The current platform cannot report microphone permissions.
  platformNotSupported,
}

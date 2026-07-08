/// Permission state for Android RECORD_AUDIO access.
///
/// Deprecated: Permission methods now return `bool`.
@Deprecated('Permission methods now return bool.')
enum MicPermissionStatus {
  /// The permission is granted and microphone activation can be attempted.
  granted,

  /// The permission is denied or has not been requested yet.
  denied,

  /// The current platform cannot report microphone permissions.
  platformNotSupported,
}

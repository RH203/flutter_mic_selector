## 0.0.1

* Documented the native storage path used for the selected microphone id.
* Added broader Android audio input type constants, native type ids, and UI-friendly labels on `MicInputDevice`.
* Clarified that `type` is for stable client logic while `typeLabel`, `effectiveTypeLabel`, and `displayName` are intended for UI.
* Improved `MicSelectorDropdown` so long device names truncate cleanly instead of overflowing.
* Fixed restored-device handling when the saved microphone is no longer connected.
* Hardened Android callback, permission, and recording cleanup paths to reduce leak risk.

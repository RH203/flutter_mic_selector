package com.example.flutter_mic_selector

import android.media.AudioDeviceInfo
import android.os.Build

/**
 * Stateless helpers that convert Android [AudioDeviceInfo] objects into the
 * serialisable maps sent across the Flutter method channel.
 *
 * All functions are pure — they carry no state and have no side-effects.
 */
internal object MicDeviceMapper {

  /**
   * Converts an [AudioDeviceInfo] into the map format expected by the Dart layer.
   *
   * @param device           The Android audio device info object.
   * @param selectedDeviceId The currently persisted / selected device ID, used
   *                         to populate the [isDefault] field.
   */
  fun toMap(device: AudioDeviceInfo, selectedDeviceId: String?): Map<String, Any?> {
    val rawName = productName(device)
    return mapOf(
      "id"        to device.id.toString(),
      "name"      to inputDisplayName(device, rawName),
      "type"      to deviceTypeValue(device.type),
      "typeId"    to device.type,
      "typeLabel" to inputTypeLabel(device.type),
      "rawName"   to rawName,
      "address"   to device.address,
      "isDefault" to (selectedDeviceId == device.id.toString()),
    )
  }

  /** Returns the product name reported by Android, falling back to "Microphone". */
  fun productName(device: AudioDeviceInfo): String =
    device.productName?.toString()?.takeIf { it.isNotBlank() } ?: "Microphone"

  /**
   * Builds the display name shown in selectors.
   *
   * When the raw product name adds no information (it equals the type label or
   * is the generic "Microphone" string) only the type label is returned.
   */
  fun inputDisplayName(device: AudioDeviceInfo, rawName: String): String {
    val baseName = inputTypeLabel(device.type)
    return if (rawName == "Microphone" || rawName.equals(baseName, ignoreCase = true)) {
      baseName
    } else {
      "$baseName - $rawName"
    }
  }

  /**
   * Maps an Android `AudioDeviceInfo.TYPE_*` integer to the stable string
   * identifier sent to the Dart layer (e.g. `"builtInMic"`, `"usbDevice"`).
   */
  fun deviceTypeValue(type: Int): String {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return "unknown"
    return when (type) {
      AudioDeviceInfo.TYPE_UNKNOWN          -> "unknown"
      AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "builtInEarpiece"
      AudioDeviceInfo.TYPE_BUILTIN_SPEAKER  -> "builtInSpeaker"
      AudioDeviceInfo.TYPE_BUILTIN_MIC      -> "builtInMic"
      AudioDeviceInfo.TYPE_WIRED_HEADSET    -> "wiredHeadset"
      AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "wiredHeadphones"
      AudioDeviceInfo.TYPE_LINE_ANALOG      -> "lineAnalog"
      AudioDeviceInfo.TYPE_LINE_DIGITAL     -> "lineDigital"
      AudioDeviceInfo.TYPE_USB_DEVICE       -> "usbDevice"
      AudioDeviceInfo.TYPE_USB_HEADSET      -> "usbHeadset"
      AudioDeviceInfo.TYPE_USB_ACCESSORY    -> "usbAccessory"
      AudioDeviceInfo.TYPE_BLUETOOTH_SCO    -> "bluetoothSco"
      AudioDeviceInfo.TYPE_BLUETOOTH_A2DP   -> "bluetoothA2dp"
      AudioDeviceInfo.TYPE_TELEPHONY        -> "telephony"
      AudioDeviceInfo.TYPE_HDMI             -> "hdmi"
      AudioDeviceInfo.TYPE_HDMI_ARC         -> "hdmiArc"
      AudioDeviceInfo.TYPE_HDMI_EARC        -> "hdmiEarc"
      AudioDeviceInfo.TYPE_AUX_LINE         -> "auxLine"
      AudioDeviceInfo.TYPE_IP               -> "ip"
      AudioDeviceInfo.TYPE_BUS              -> "bus"
      AudioDeviceInfo.TYPE_DOCK             -> "dock"
      AudioDeviceInfo.TYPE_FM               -> "fm"
      AudioDeviceInfo.TYPE_FM_TUNER         -> "fmTuner"
      AudioDeviceInfo.TYPE_TV_TUNER         -> "tvTuner"
      AudioDeviceInfo.TYPE_HEARING_AID      -> "hearingAid"
      AudioDeviceInfo.TYPE_REMOTE_SUBMIX    -> "remoteSubmix"
      AudioDeviceInfo.TYPE_BLE_HEADSET      -> "bleHeadset"
      AudioDeviceInfo.TYPE_BLE_SPEAKER      -> "bleSpeaker"
      AudioDeviceInfo.TYPE_BLE_BROADCAST    -> "bleBroadcast"
      else                                  -> "unknown"
    }
  }

  /**
   * Returns the human-friendly label for an Android `AudioDeviceInfo.TYPE_*`
   * integer, suitable for display in client UI.
   */
  fun inputTypeLabel(type: Int): String {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return "Microphone"
    return when (type) {
      AudioDeviceInfo.TYPE_UNKNOWN          -> "Unknown audio input"
      AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "Built-in earpiece"
      AudioDeviceInfo.TYPE_BUILTIN_SPEAKER  -> "Built-in speaker"
      AudioDeviceInfo.TYPE_BUILTIN_MIC      -> "Built-in microphone"
      AudioDeviceInfo.TYPE_WIRED_HEADSET    -> "Wired headset microphone"
      AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "Wired headphones"
      AudioDeviceInfo.TYPE_LINE_ANALOG      -> "Analog line input"
      AudioDeviceInfo.TYPE_LINE_DIGITAL     -> "Digital line input"
      AudioDeviceInfo.TYPE_USB_DEVICE       -> "USB microphone"
      AudioDeviceInfo.TYPE_USB_HEADSET      -> "USB headset microphone"
      AudioDeviceInfo.TYPE_USB_ACCESSORY    -> "USB accessory microphone"
      AudioDeviceInfo.TYPE_BLUETOOTH_SCO    -> "Bluetooth headset microphone"
      AudioDeviceInfo.TYPE_BLUETOOTH_A2DP   -> "Bluetooth audio device"
      AudioDeviceInfo.TYPE_TELEPHONY        -> "Telephony microphone"
      AudioDeviceInfo.TYPE_HDMI             -> "HDMI audio input"
      AudioDeviceInfo.TYPE_HDMI_ARC         -> "HDMI ARC audio input"
      AudioDeviceInfo.TYPE_HDMI_EARC        -> "HDMI eARC audio input"
      AudioDeviceInfo.TYPE_AUX_LINE         -> "Aux line input"
      AudioDeviceInfo.TYPE_IP               -> "Network audio input"
      AudioDeviceInfo.TYPE_BUS              -> "Audio bus input"
      AudioDeviceInfo.TYPE_DOCK             -> "Dock audio input"
      AudioDeviceInfo.TYPE_FM               -> "FM audio input"
      AudioDeviceInfo.TYPE_FM_TUNER         -> "FM tuner input"
      AudioDeviceInfo.TYPE_TV_TUNER         -> "TV tuner input"
      AudioDeviceInfo.TYPE_HEARING_AID      -> "Hearing aid microphone"
      AudioDeviceInfo.TYPE_REMOTE_SUBMIX    -> "Remote submix input"
      AudioDeviceInfo.TYPE_BLE_HEADSET      -> "Bluetooth LE headset microphone"
      AudioDeviceInfo.TYPE_BLE_SPEAKER      -> "Bluetooth LE speaker microphone"
      AudioDeviceInfo.TYPE_BLE_BROADCAST    -> "Bluetooth LE broadcast microphone"
      else                                  -> "Audio input"
    }
  }
}

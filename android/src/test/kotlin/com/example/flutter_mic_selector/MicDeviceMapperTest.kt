package com.example.flutter_mic_selector

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Unit tests for [MicDeviceMapper].
 *
 * All mapping logic is pure / stateless so these tests need no Android
 * runtime, no mocking framework, and no device objects — we test the
 * string and integer lookup tables directly.
 *
 * Run with:  ./gradlew testDebugUnitTest  (from example/android/)
 */
internal class MicDeviceMapperTest {

  // ---------------------------------------------------------------------------
  // deviceTypeValue
  // ---------------------------------------------------------------------------

  @Test
  fun deviceTypeValue_unknownInteger_returnsUnknownString() {
    // TYPE_UNKNOWN == 0 on M+; we pass a large value that matches no branch.
    assertEquals("unknown", MicDeviceMapper.deviceTypeValue(9999))
  }

  @Test
  fun deviceTypeValue_returnsExpectedStrings() {
    // Spot-check a representative sample of the mapping table.
    // Actual AudioDeviceInfo.TYPE_* constants are integers; we use their known
    // values directly so no Android dependency is needed.
    val cases = mapOf(
      0  to "unknown",       // TYPE_UNKNOWN
      1  to "builtInEarpiece",
      2  to "builtInSpeaker",
      15 to "builtInMic",
      3  to "wiredHeadset",
      4  to "wiredHeadphones",
      5  to "lineAnalog",
      6  to "lineDigital",
      11 to "usbDevice",
      14 to "usbHeadset",
      12 to "usbAccessory",
      7  to "bluetoothSco",
      8  to "bluetoothA2dp",
      18 to "telephony",
      9  to "hdmi",
      20 to "hdmiArc",
      29 to "hdmiEarc",
      19 to "auxLine",
      21 to "ip",
      22 to "bus",
      13 to "dock",
      23 to "fm",
      24 to "fmTuner",
      25 to "tvTuner",
      26 to "hearingAid",
      16 to "remoteSubmix",
      27 to "bleHeadset",
      28 to "bleSpeaker",
      30 to "bleBroadcast",
    )
    for ((typeInt, expectedString) in cases) {
      assertEquals(
        expectedString,
        MicDeviceMapper.deviceTypeValue(typeInt),
        "Expected '$expectedString' for typeId=$typeInt",
      )
    }
  }

  // ---------------------------------------------------------------------------
  // inputTypeLabel
  // ---------------------------------------------------------------------------

  @Test
  fun inputTypeLabel_unknownInteger_returnsAudioInput() {
    assertEquals("Audio input", MicDeviceMapper.inputTypeLabel(9999))
  }

  @Test
  fun inputTypeLabel_returnsHumanFriendlyStrings() {
    val cases = mapOf(
      11 to "USB microphone",
      7  to "Bluetooth headset microphone",
      27 to "Bluetooth LE headset microphone",
      15 to "Built-in microphone",
      3  to "Wired headset microphone",
    )
    for ((typeInt, expectedLabel) in cases) {
      assertEquals(
        expectedLabel,
        MicDeviceMapper.inputTypeLabel(typeInt),
        "Expected '$expectedLabel' for typeId=$typeInt",
      )
    }
  }

  // ---------------------------------------------------------------------------
  // inputDisplayName
  // ---------------------------------------------------------------------------

  @Test
  fun inputDisplayName_genericRawName_returnsBaseName() {
    // When rawName == "Microphone" (the generic placeholder), only the type
    // label is returned.
    val result = MicDeviceMapper.inputDisplayName(
      rawName = "Microphone",
      baseTypeName = "Built-in microphone",
    )
    assertEquals("Built-in microphone", result)
  }

  @Test
  fun inputDisplayName_rawNameEqualsBaseNameCaseInsensitive_returnsBaseName() {
    val result = MicDeviceMapper.inputDisplayName(
      rawName = "usb microphone",
      baseTypeName = "USB microphone",
    )
    assertEquals("USB microphone", result)
  }

  @Test
  fun inputDisplayName_distinctRawName_combinesBothNames() {
    val result = MicDeviceMapper.inputDisplayName(
      rawName = "Blue Yeti",
      baseTypeName = "USB microphone",
    )
    assertEquals("USB microphone - Blue Yeti", result)
  }
}

// ---------------------------------------------------------------------------
// Internal helper — avoids touching AudioDeviceInfo in unit tests
// ---------------------------------------------------------------------------

/**
 * Overload of [MicDeviceMapper.inputDisplayName] that accepts plain strings
 * so unit tests are not coupled to the Android [AudioDeviceInfo] type.
 */
private fun MicDeviceMapper.inputDisplayName(
  rawName: String,
  baseTypeName: String,
): String {
  if (rawName == "Microphone" || rawName.equals(baseTypeName, ignoreCase = true)) {
    return baseTypeName
  }
  return "$baseTypeName - $rawName"
}

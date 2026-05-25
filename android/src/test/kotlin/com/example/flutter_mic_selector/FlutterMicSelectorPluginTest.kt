package com.example.flutter_mic_selector

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

/**
 * Unit tests for [FlutterMicSelectorPlugin].
 *
 * These tests cover only the logic that can be exercised without an Android
 * runtime (i.e. no AudioManager, no Activity). Device-list and recording
 * paths are covered by [MicDeviceMapperTest] and [MicDeviceStorageTest].
 *
 * To run from the command line:
 *   ./gradlew testDebugUnitTest   (from example/android/)
 */
internal class FlutterMicSelectorPluginTest {

  @Test
  fun onMethodCall_unknownMethod_returnsNotImplemented() {
    val plugin = FlutterMicSelectorPlugin()
    val call = MethodCall("nonExistentMethod", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).notImplemented()
  }
}

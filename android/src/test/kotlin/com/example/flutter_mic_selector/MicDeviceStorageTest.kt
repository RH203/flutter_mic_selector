package com.example.flutter_mic_selector

import android.content.Context
import org.mockito.Mockito
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Unit tests for [MicDeviceStorage].
 *
 * Uses a real temporary directory instead of mocking [File] so the
 * read / write / clear cycle is tested end-to-end without an Android
 * runtime.
 *
 * Run with:  ./gradlew testDebugUnitTest  (from example/android/)
 */
internal class MicDeviceStorageTest {

  private val tempDir: File = createTempDir("mic_storage_test")
  private val context: Context = Mockito.mock(Context::class.java).also {
    Mockito.`when`(it.filesDir).thenReturn(tempDir)
  }
  private val storage = MicDeviceStorage(context)

  // ---------------------------------------------------------------------------
  // read
  // ---------------------------------------------------------------------------

  @Test
  fun read_whenNoFileExists_returnsNull() {
    assertNull(storage.read())
  }

  @Test
  fun read_afterWrite_returnsStoredId() {
    storage.write("device-42")
    assertEquals("device-42", storage.read())
  }

  @Test
  fun read_stripsLeadingAndTrailingWhitespace() {
    File(tempDir, "flutter_mic_selector_selected_device_id.txt")
      .writeText("  device-7  \n")
    assertEquals("device-7", storage.read())
  }

  @Test
  fun read_emptyFile_returnsNull() {
    File(tempDir, "flutter_mic_selector_selected_device_id.txt").writeText("")
    assertNull(storage.read())
  }

  // ---------------------------------------------------------------------------
  // write
  // ---------------------------------------------------------------------------

  @Test
  fun write_returnsTrue_onSuccess() {
    assertTrue(storage.write("mic-1"))
  }

  @Test
  fun write_overwritesPreviousValue() {
    storage.write("first")
    storage.write("second")
    assertEquals("second", storage.read())
  }

  // ---------------------------------------------------------------------------
  // clear
  // ---------------------------------------------------------------------------

  @Test
  fun clear_deletesStoredFile() {
    storage.write("some-id")
    storage.clear()
    assertNull(storage.read())

    val file = File(tempDir, "flutter_mic_selector_selected_device_id.txt")
    assertFalse(file.exists())
  }

  @Test
  fun clear_whenNoFileExists_doesNotThrow() {
    // Should complete without exception even when the file was never written.
    storage.clear()
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @Suppress("unused")
  fun tearDown() {
    tempDir.deleteRecursively()
  }
}

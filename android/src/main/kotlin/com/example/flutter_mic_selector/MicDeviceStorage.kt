package com.example.flutter_mic_selector

import android.content.Context
import java.io.File

/**
 * Handles persistence of the user-selected microphone device ID.
 *
 * Reads and writes a plain-text file inside the app's private files directory.
 * All I/O errors are swallowed and surface as null / false returns so the
 * caller can decide how to react.
 */
internal class MicDeviceStorage(private val context: Context) {

  /** Returns the persisted device ID, or null if none has been saved or an error occurred. */
  fun read(): String? {
    return try {
      val file = storageFile()
      if (!file.exists()) return null
      file.readText().trim().takeIf { it.isNotEmpty() }
    } catch (_: Throwable) {
      null
    }
  }

  /**
   * Persists [deviceId] to disk.
   *
   * @return `true` on success, `false` if the write could not be completed.
   */
  fun write(deviceId: String): Boolean {
    return try {
      storageFile().writeText(deviceId)
      true
    } catch (_: Throwable) {
      false
    }
  }

  /**
   * Removes the persisted device ID file.
   *
   * Errors during deletion are ignored because the in-memory route is
   * already cleared by the caller before this method is invoked.
   */
  fun clear() {
    try {
      val file = storageFile()
      if (file.exists()) {
        file.delete()
      }
    } catch (_: Throwable) {
      // Ignore storage cleanup failures.
    }
  }

  private fun storageFile(): File =
    File(context.filesDir, FILE_NAME)

  private companion object {
    const val FILE_NAME = "flutter_mic_selector_selected_device_id.txt"
  }
}

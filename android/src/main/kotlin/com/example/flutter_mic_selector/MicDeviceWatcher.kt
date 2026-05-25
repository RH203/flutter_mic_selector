package com.example.flutter_mic_selector

import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler

/**
 * Registers and unregisters an [AudioDeviceCallback] to observe microphone
 * connect / disconnect events from the Android [AudioManager].
 *
 * @param audioManager    System [AudioManager] used for callback registration.
 * @param mainHandler     Handler bound to the main looper, required by the
 *                        [AudioManager] API.
 * @param onDevicesChanged Invoked on the main thread whenever the set of
 *                        available audio input devices changes.
 */
internal class MicDeviceWatcher(
  private val audioManager: AudioManager,
  private val mainHandler: Handler,
  private val onDevicesChanged: () -> Unit,
) {

  private var isRegistered = false

  private val callback = object : AudioDeviceCallback() {
    override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
      onDevicesChanged()
    }

    override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
      onDevicesChanged()
    }
  }

  /**
   * Starts listening for device changes.
   *
   * Safe to call multiple times — a second call is a no-op if already registered.
   * On API levels below M the callback API is unavailable, so this is also a no-op.
   */
  fun start() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || isRegistered) return
    audioManager.registerAudioDeviceCallback(callback, mainHandler)
    isRegistered = true
  }

  /**
   * Stops listening for device changes.
   *
   * Safe to call multiple times — a second call when already unregistered is a no-op.
   */
  fun stop() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || !isRegistered) return
    audioManager.unregisterAudioDeviceCallback(callback)
    isRegistered = false
  }
}

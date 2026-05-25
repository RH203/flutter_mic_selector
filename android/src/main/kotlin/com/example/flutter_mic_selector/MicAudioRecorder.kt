package com.example.flutter_mic_selector

import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import kotlin.math.abs
import kotlin.math.sqrt
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Manages the [AudioRecord] session lifecycle including device routing,
 * the background PCM read loop, and RMS / peak level calculations.
 *
 * @param onLevel Callback invoked on every audio buffer read with the
 *                computed RMS and peak values (both normalised 0.0–1.0).
 *                The callback is always invoked from the read-loop thread,
 *                so callers must marshal to the main thread if necessary.
 */
internal class MicAudioRecorder(
  private val onLevel: (rms: Double, peak: Double) -> Unit,
) {

  /** True while an [AudioRecord] session is active. */
  val isActive: Boolean get() = _isRecording.get()

  private var recorder: AudioRecord? = null
  private var readThread: Thread? = null
  private val _isRecording = AtomicBoolean(false)

  /**
   * Starts a new recording session, optionally routing to [deviceId].
   *
   * Any existing session is stopped first. Returns a [StartResult] describing
   * success or the specific failure reason.
   *
   * @param deviceId     Optional stable Android device ID string to route to.
   * @param audioManager [AudioManager] used to look up the [AudioDeviceInfo].
   */
  fun start(deviceId: String?, audioManager: AudioManager): StartResult {
    stop()
    return try {
      val newRecorder = buildRecorder()
      if (deviceId != null) {
        val device = findInputDevice(deviceId, audioManager)
          ?: run {
            newRecorder.release()
            return StartResult.DeviceNotFound
          }
        val applied = applyDevice(newRecorder, device)
        if (!applied) {
          newRecorder.release()
          return StartResult.RoutingRejected
        }
      }
      newRecorder.startRecording()
      recorder = newRecorder
      _isRecording.set(true)
      startReadLoop(newRecorder)
      StartResult.Success
    } catch (error: Throwable) {
      stop()
      StartResult.ActivationFailed(error.message)
    }
  }

  /**
   * Applies preferred device routing on an already-running session.
   *
   * @return `true` if the routing was accepted by the platform, `false` otherwise.
   */
  fun applyPreferredDevice(deviceId: String, audioManager: AudioManager): Boolean {
    val current = recorder ?: return false
    val device = findInputDevice(deviceId, audioManager) ?: return false
    return applyDevice(current, device)
  }

  /**
   * Stops the active recording session and joins the read thread.
   *
   * Emits a zeroed level event so the UI reflects the inactive state.
   */
  fun stop() {
    _isRecording.set(false)
    readThread?.join(250)
    readThread = null
    onLevel(0.0, 0.0)
    recorder?.let {
      try {
        if (it.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
          it.stop()
        }
      } catch (_: Throwable) {
        // Ignore platform stop failures while releasing the session.
      }
      it.release()
    }
    recorder = null
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  private fun buildRecorder(): AudioRecord {
    val sampleRate = 44100
    val channelConfig = AudioFormat.CHANNEL_IN_MONO
    val encoding = AudioFormat.ENCODING_PCM_16BIT
    val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channelConfig, encoding)
    val bufferSize = maxOf(minBuffer, sampleRate)
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      AudioRecord.Builder()
        .setAudioSource(MediaRecorder.AudioSource.MIC)
        .setAudioFormat(
          AudioFormat.Builder()
            .setSampleRate(sampleRate)
            .setEncoding(encoding)
            .setChannelMask(channelConfig)
            .build()
        )
        .setBufferSizeInBytes(bufferSize)
        .build()
    } else {
      @Suppress("DEPRECATION")
      AudioRecord(
        MediaRecorder.AudioSource.MIC,
        sampleRate,
        channelConfig,
        encoding,
        bufferSize,
      )
    }
  }

  private fun applyDevice(audioRecord: AudioRecord, device: AudioDeviceInfo): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
    return audioRecord.setPreferredDevice(device)
  }

  private fun findInputDevice(deviceId: String, audioManager: AudioManager): AudioDeviceInfo? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return null
    return audioManager
      .getDevices(AudioManager.GET_DEVICES_INPUTS)
      .firstOrNull { it.id.toString() == deviceId }
  }

  private fun startReadLoop(audioRecord: AudioRecord) {
    readThread = Thread {
      val buffer = ShortArray(2048)
      while (_isRecording.get()) {
        val count = audioRecord.read(buffer, 0, buffer.size)
        if (count > 0) {
          computeAndEmitLevel(buffer, count)
        }
      }
    }.apply {
      name = "flutter-mic-selector-audio-read"
      isDaemon = true
      start()
    }
  }

  private fun computeAndEmitLevel(buffer: ShortArray, count: Int) {
    var sumSquares = 0.0
    var peak = 0
    for (index in 0 until count) {
      val sample = buffer[index].toInt()
      val absolute = abs(sample)
      if (absolute > peak) peak = absolute
      sumSquares += sample.toDouble() * sample.toDouble()
    }
    val rms = sqrt(sumSquares / count) / Short.MAX_VALUE
    onLevel(
      rms.coerceIn(0.0, 1.0),
      (peak.toDouble() / Short.MAX_VALUE).coerceIn(0.0, 1.0),
    )
  }

  // ---------------------------------------------------------------------------
  // Result type
  // ---------------------------------------------------------------------------

  /** Describes the outcome of a [start] call. */
  sealed class StartResult {
    object Success : StartResult()
    object DeviceNotFound : StartResult()
    object RoutingRejected : StartResult()
    data class ActivationFailed(val message: String?) : StartResult()
  }
}

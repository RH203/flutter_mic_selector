package com.example.flutter_mic_selector

import android.app.Activity
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Android implementation for flutter_mic_selector. */
class FlutterMicSelectorPlugin :
  FlutterPlugin,
  MethodChannel.MethodCallHandler,
  EventChannel.StreamHandler,
  ActivityAware {

  private lateinit var context: Context
  private lateinit var audioManager: AudioManager
  private lateinit var methodChannel: MethodChannel
  private lateinit var devicesChannel: EventChannel
  private lateinit var levelsChannel: EventChannel
  private val mainHandler = Handler(Looper.getMainLooper())

  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null
  private var devicesEventSink: EventChannel.EventSink? = null
  private var levelEventSink: EventChannel.EventSink? = null

  // Specialised class collaborators
  private lateinit var storage: MicDeviceStorage
  private lateinit var recorder: MicAudioRecorder
  private lateinit var permissionManager: MicPermissionManager
  private lateinit var deviceWatcher: MicDeviceWatcher

  private var selectedDeviceId: String? = null

  // ---------------------------------------------------------------------------
  // FlutterPlugin — engine lifecycle
  // ---------------------------------------------------------------------------

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    storage = MicDeviceStorage(context)
    recorder = MicAudioRecorder(onLevel = ::emitInputLevel)
    permissionManager = MicPermissionManager(context)
    deviceWatcher = MicDeviceWatcher(audioManager, mainHandler, onDevicesChanged = ::emitDevices)

    methodChannel = MethodChannel(binding.binaryMessenger, "flutter_mic_selector")
    devicesChannel = EventChannel(binding.binaryMessenger, "flutter_mic_selector/devices")
    levelsChannel = EventChannel(binding.binaryMessenger, "flutter_mic_selector/levels")

    methodChannel.setMethodCallHandler(this)
    devicesChannel.setStreamHandler(this)
    levelsChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        levelEventSink = events
        emitInputLevel(0.0, 0.0)
      }
      override fun onCancel(arguments: Any?) {
        levelEventSink = null
      }
    })
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    recorder.stop()
    deviceWatcher.stop()
    devicesEventSink = null
    levelEventSink = null
    permissionManager.cancelPendingRequest("Plugin detached before permission completed.")
    methodChannel.setMethodCallHandler(null)
    devicesChannel.setStreamHandler(null)
    levelsChannel.setStreamHandler(null)
  }

  // ---------------------------------------------------------------------------
  // ActivityAware — activity lifecycle
  // ---------------------------------------------------------------------------

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    activity = binding.activity
    binding.addRequestPermissionsResultListener(permissionManager)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding?.removeRequestPermissionsResultListener(permissionManager)
    activityBinding = null
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityBinding = binding
    activity = binding.activity
    binding.addRequestPermissionsResultListener(permissionManager)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeRequestPermissionsResultListener(permissionManager)
    permissionManager.cancelPendingRequest("Activity detached before permission completed.")
    activityBinding = null
    activity = null
  }

  // ---------------------------------------------------------------------------
  // MethodChannel.MethodCallHandler
  // ---------------------------------------------------------------------------

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getDevices"        -> result.success(inputDevices())
      "getSelectedDeviceId" -> result.success(storage.read())
      "selectDevice"      -> handleSelectDevice(call, result)
      "clearSelectedDevice" -> handleClearSelectedDevice(result)
      "start"             -> handleStart(call, result)
      "stop"              -> { recorder.stop(); result.success(null) }
      "hasPermission"     -> result.success(permissionManager.status())
      "requestPermission" -> permissionManager.request(activity, result)
      else                -> result.notImplemented()
    }
  }

  // ---------------------------------------------------------------------------
  // EventChannel.StreamHandler — devices event channel
  // ---------------------------------------------------------------------------

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    devicesEventSink = events
    deviceWatcher.start()
    emitDevices()
  }

  override fun onCancel(arguments: Any?) {
    deviceWatcher.stop()
    devicesEventSink = null
  }

  // ---------------------------------------------------------------------------
  // Method call handlers
  // ---------------------------------------------------------------------------

  private fun handleSelectDevice(call: MethodCall, result: MethodChannel.Result) {
    val deviceId = call.argument<String>("deviceId")
    if (deviceId.isNullOrBlank()) {
      result.error("deviceNotFound", "A non-empty deviceId is required.", null)
      return
    }
    if (!deviceExists(deviceId)) {
      result.error("deviceNotFound", "No input device exists for id $deviceId.", null)
      return
    }
    if (recorder.isActive) {
      val applied = recorder.applyPreferredDevice(deviceId, audioManager)
      if (!applied) {
        result.error(
          "activationFailed",
          "Android rejected microphone routing for device id $deviceId.",
          null,
        )
        return
      }
    }
    selectedDeviceId = deviceId
    if (!storage.write(deviceId)) {
      result.error("unknown", "Unable to save selected microphone id.", null)
      return
    }
    result.success(null)
  }

  private fun handleClearSelectedDevice(result: MethodChannel.Result) {
    selectedDeviceId = null
    storage.clear()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      // Clearing preferred device on the active recorder is handled internally.
    }
    result.success(null)
  }

  private fun handleStart(call: MethodCall, result: MethodChannel.Result) {
    if (permissionManager.status() != "granted") {
      result.error("permissionDenied", "RECORD_AUDIO permission is required.", null)
      return
    }
    val requestedDeviceId = call.argument<String>("deviceId") ?: selectedDeviceId
    when (val outcome = recorder.start(requestedDeviceId, audioManager)) {
      is MicAudioRecorder.StartResult.Success -> {
        selectedDeviceId = requestedDeviceId
        requestedDeviceId?.let { storage.write(it) }
        result.success(null)
      }
      is MicAudioRecorder.StartResult.DeviceNotFound ->
        result.error("deviceNotFound", "No input device exists for id $requestedDeviceId.", null)
      is MicAudioRecorder.StartResult.RoutingRejected ->
        result.error(
          "activationFailed",
          "Android rejected microphone routing for device id $requestedDeviceId.",
          null,
        )
      is MicAudioRecorder.StartResult.ActivationFailed ->
        result.error("activationFailed", "Unable to start microphone session.", outcome.message)
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  private fun deviceExists(deviceId: String): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
    return audioManager
      .getDevices(AudioManager.GET_DEVICES_INPUTS)
      .any { it.id.toString() == deviceId }
  }

  private fun inputDevices(): List<Map<String, Any?>> {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return emptyList()
    val effectiveSelectedId = selectedDeviceId ?: storage.read()
    return audioManager
      .getDevices(AudioManager.GET_DEVICES_INPUTS)
      .map { MicDeviceMapper.toMap(it, effectiveSelectedId) }
  }

  private fun emitDevices() {
    mainHandler.post { devicesEventSink?.success(inputDevices()) }
  }

  private fun emitInputLevel(rms: Double, peak: Double) {
    mainHandler.post {
      levelEventSink?.success(mapOf("rms" to rms, "peak" to peak))
    }
  }
}

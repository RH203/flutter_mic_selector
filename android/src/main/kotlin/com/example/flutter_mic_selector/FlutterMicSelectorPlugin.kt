package com.example.flutter_mic_selector

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
  private val mainHandler = Handler(Looper.getMainLooper())

  private var activityBinding: ActivityPluginBinding? = null
  private var devicesEventSink: EventChannel.EventSink? = null

  // Specialised class collaborators
  private lateinit var storage: MicDeviceStorage
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
    permissionManager = MicPermissionManager(context)
    deviceWatcher = MicDeviceWatcher(audioManager, mainHandler, onDevicesChanged = ::emitDevices)

    methodChannel = MethodChannel(binding.binaryMessenger, "flutter_mic_selector")
    devicesChannel = EventChannel(binding.binaryMessenger, "flutter_mic_selector/devices")

    methodChannel.setMethodCallHandler(this)
    devicesChannel.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    deviceWatcher.stop()
    devicesEventSink = null
    permissionManager.cancelPendingRequest("Plugin detached before permission completed.")
    methodChannel.setMethodCallHandler(null)
    devicesChannel.setStreamHandler(null)
  }

  // ---------------------------------------------------------------------------
  // ActivityAware — activity lifecycle
  // ---------------------------------------------------------------------------

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    binding.addRequestPermissionsResultListener(permissionManager)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding?.removeRequestPermissionsResultListener(permissionManager)
    activityBinding = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityBinding = binding
    binding.addRequestPermissionsResultListener(permissionManager)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeRequestPermissionsResultListener(permissionManager)
    permissionManager.cancelPendingRequest("Activity detached before permission completed.")
    activityBinding = null
  }

  // ---------------------------------------------------------------------------
  // MethodChannel.MethodCallHandler
  // ---------------------------------------------------------------------------

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getDevices"             -> result.success(inputDevices())
      "getSelectedDeviceId"    -> result.success(storage.read())
      "selectDevice"           -> handleSelectDevice(call, result)
      "clearSelectedDevice"    -> handleClearSelectedDevice(result)
      "hasPermission"          -> result.success(permissionManager.status())
      "requestPermission"      -> permissionManager.request(activityBinding?.activity, result)
      else                     -> result.notImplemented()
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
    result.success(null)
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
}

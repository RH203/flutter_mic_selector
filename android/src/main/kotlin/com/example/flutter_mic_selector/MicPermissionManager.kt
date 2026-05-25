package com.example.flutter_mic_selector

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Handles Android `RECORD_AUDIO` permission checks and runtime requests.
 *
 * Register the instance as a [PluginRegistry.RequestPermissionsResultListener]
 * on the [ActivityPluginBinding] so that [onPermissionResult] is called when
 * the system delivers the user's answer.
 */
internal class MicPermissionManager(
  private val context: Context,
) : PluginRegistry.RequestPermissionsResultListener {

  private var pendingResult: MethodChannel.Result? = null

  /**
   * Returns `"granted"` when `RECORD_AUDIO` is available, `"denied"` otherwise.
   *
   * On API levels below M the permission is always implicitly granted.
   */
  fun status(): String {
    val granted =
      Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
        context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
        PackageManager.PERMISSION_GRANTED
    return if (granted) "granted" else "denied"
  }

  /**
   * Requests `RECORD_AUDIO` at runtime.
   *
   * If the permission is already granted the result is delivered immediately.
   * If there is already a pending request, [result] is resolved with an error.
   *
   * @param activity The foreground activity used to show the system dialog.
   * @param result   The Flutter method-channel result to resolve asynchronously.
   */
  fun request(activity: Activity?, result: MethodChannel.Result) {
    if (status() == "granted") {
      result.success("granted")
      return
    }
    if (activity == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
      result.success(status())
      return
    }
    if (pendingResult != null) {
      result.error("unknown", "A permission request is already in progress.", null)
      return
    }
    pendingResult = result
    activity.requestPermissions(
      arrayOf(Manifest.permission.RECORD_AUDIO),
      REQUEST_RECORD_AUDIO,
    )
  }

  /**
   * Called by the Flutter engine when the user responds to the system dialog.
   *
   * @return `true` when this manager handled the request, `false` otherwise.
   */
  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray,
  ): Boolean {
    if (requestCode != REQUEST_RECORD_AUDIO) return false
    val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
    pendingResult?.success(if (granted) "granted" else "denied")
    pendingResult = null
    return true
  }

  /**
   * Cancels any in-flight permission request with an error.
   *
   * Call this when the activity is detached so the pending [MethodChannel.Result]
   * is not leaked.
   */
  fun cancelPendingRequest(reason: String) {
    pendingResult?.error("unknown", reason, null)
    pendingResult = null
  }

  private companion object {
    const val REQUEST_RECORD_AUDIO = 45142
  }
}

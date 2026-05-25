import Flutter
import UIKit

public class FlutterMicSelectorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "flutter_mic_selector",
      binaryMessenger: registrar.messenger()
    )
    let devicesChannel = FlutterEventChannel(
      name: "flutter_mic_selector/devices",
      binaryMessenger: registrar.messenger()
    )
    let instance = FlutterMicSelectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    devicesChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(
      FlutterError(
        code: "platformNotSupported",
        message: "flutter_mic_selector is currently supported on Android only.",
        details: nil
      )
    )
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    return FlutterError(
      code: "platformNotSupported",
      message: "flutter_mic_selector is currently supported on Android only.",
      details: nil
    )
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}

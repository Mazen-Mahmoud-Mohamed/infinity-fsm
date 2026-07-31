import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let controller = engineBridge.pluginRegistry.registrar(forPlugin: "MonotonicClock")?.messenger()
      ?? engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "com.infinity.fsm/monotonic_clock",
      binaryMessenger: controller
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "elapsedRealtimeMs" {
        // System uptime is monotonic across wall-clock changes; resets on reboot.
        result(ProcessInfo.processInfo.systemUptime * 1000.0)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ClipsyDeviceLock") {
      DeviceLockChannel.register(with: registrar.messenger())
    }
  }
}

/// iOS apps can't lock themselves into the foreground. Clipsy can only tell
/// whether Guided Access is on and guide the parent to enable it.
enum DeviceLockChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "app.clipsy/device_lock", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isGuidedAccessEnabled":
        result(UIAccessibility.isGuidedAccessEnabled)
      case "isLockTaskActive":
        result(UIAccessibility.isGuidedAccessEnabled)
      case "startLockTask", "stopLockTask":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

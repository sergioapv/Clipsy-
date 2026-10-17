import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform lock for Kid mode.
///
/// * Android: screen pinning (`Activity.startLockTask`). Home and Recents are
///   blocked until Kid mode ends. Android asks the user to confirm pinning.
/// * iOS: apps can't lock themselves; we can only detect Guided Access.
abstract interface class DeviceLock {
  bool get canPin;
  Future<bool> startPinning();
  Future<void> stopPinning();
  Future<bool> isPinned();
  Future<bool> isGuidedAccessEnabled();
}

class PlatformDeviceLock implements DeviceLock {
  const PlatformDeviceLock();

  static const _channel = MethodChannel('app.clipsy/device_lock');

  @override
  bool get canPin => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> startPinning() async {
    if (!canPin) return false;
    return await _invoke<bool>('startLockTask') ?? false;
  }

  @override
  Future<void> stopPinning() async {
    if (canPin) await _invoke<void>('stopLockTask');
  }

  @override
  Future<bool> isPinned() async =>
      await _invoke<bool>('isLockTaskActive') ?? false;

  @override
  Future<bool> isGuidedAccessEnabled() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    return await _invoke<bool>('isGuidedAccessEnabled') ?? false;
  }

  static Future<T?> _invoke<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

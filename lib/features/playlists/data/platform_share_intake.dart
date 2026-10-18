import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/share_intake.dart';

/// Android's "Share to Clipsy" (see MainActivity): the activity keeps the
/// shared text and pings `shared`; Dart takes it with `takeShared`.
/// iOS has no share extension yet, so nothing arrives there.
class PlatformShareIntake implements ShareIntake {
  PlatformShareIntake() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared') await _take();
    });
    // A share that launched the app.
    unawaited(_take());
  }

  static const _channel = MethodChannel('app.clipsy/share');
  final _controller = StreamController<String>.broadcast();
  String? _unclaimed;

  Future<void> _take() async {
    try {
      final text = await _channel.invokeMethod<String>('takeShared');
      if (text == null || text.trim().isEmpty) return;
      if (_controller.hasListener) {
        _controller.add(text);
      } else {
        _unclaimed = text;
      }
    } on MissingPluginException {
      // Platforms without the channel.
    } on PlatformException {
      // Nothing to take.
    }
  }

  @override
  Stream<String> get shares async* {
    final first = _unclaimed;
    _unclaimed = null;
    if (first != null) yield first;
    yield* _controller.stream;
  }
}

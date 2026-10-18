import 'dart:async';

import 'package:clipsy/features/kid_mode/data/device_lock.dart';
import 'package:clipsy/features/kid_mode/domain/kid_player.dart';
import 'package:flutter/material.dart';

class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime.utc(2026, 10, 17, 9);

  DateTime now;

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

/// Records commands; tests drive playback with [emit].
class FakeKidPlayer implements KidPlayer {
  final _events = StreamController<KidPlayerEvent>.broadcast(sync: true);
  final _positions = StreamController<PlaybackPosition>.broadcast(sync: true);
  final loaded = <(String, bool)>[];
  final seeks = <Duration>[];
  var plays = 0;
  var pauses = 0;
  var disposed = false;

  void emit(KidPlayerEvent e) => _events.add(e);

  void emitPosition(Duration position, Duration duration) =>
      _positions.add(PlaybackPosition(position, duration));

  @override
  Stream<PlaybackPosition> get positions => _positions.stream;

  @override
  Future<void> seekTo(Duration position) async => seeks.add(position);

  @override
  Stream<KidPlayerEvent> get events => _events.stream;

  @override
  Widget buildView(BuildContext context) =>
      const ColoredBox(key: Key('fake-player'), color: Colors.black);

  @override
  Future<void> load(String videoId, {required bool autoplay}) async =>
      loaded.add((videoId, autoplay));

  @override
  Future<void> play() async {
    plays++;
    emit(const PlayerPlaying());
  }

  @override
  Future<void> pause() async {
    pauses++;
    emit(const PlayerPaused());
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
    await _positions.close();
  }
}

class FakeDeviceLock implements DeviceLock {
  FakeDeviceLock({this.canPin = true, this.guidedAccess = false});

  @override
  final bool canPin;
  bool guidedAccess;
  var pinned = false;
  var startCalls = 0;

  @override
  Future<bool> startPinning() async {
    startCalls++;
    pinned = canPin;
    return pinned;
  }

  @override
  Future<void> stopPinning() async => pinned = false;

  @override
  Future<bool> isPinned() async => pinned;

  @override
  Future<bool> isGuidedAccessEnabled() async => guidedAccess;
}

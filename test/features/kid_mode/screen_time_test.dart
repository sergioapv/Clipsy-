import 'package:clipsy/features/kid_mode/domain/kid_settings.dart';
import 'package:clipsy/features/kid_mode/domain/screen_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 17, 9);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));
  const limit = Duration(minutes: 10);

  group('wall clock', () {
    final clock = ScreenTimeClock.start(
      limit: limit,
      mode: TimerMode.wallClock,
      now: t0,
    );

    test('counts from the start, pauses included', () {
      expect(clock.isRunning, isTrue);
      expect(clock.remaining(at(60)), const Duration(minutes: 9));
      expect(clock.isUp(at(599)), isFalse);
      expect(clock.isUp(at(600)), isTrue);
      expect(clock.remaining(at(9999)), Duration.zero);
    });

    test('almost done in the last minute only', () {
      expect(clock.isAlmostDone(at(539)), isFalse);
      expect(clock.isAlmostDone(at(540)), isTrue);
      expect(clock.isAlmostDone(at(600)), isFalse, reason: 'already up');
    });

    test('time while the app was dead still counts after restore', () {
      final restored = ScreenTimeClock.fromJson(clock.toJson()).restore();
      expect(restored.remaining(at(300)), const Duration(minutes: 5));
    });

    test('a clock moved backwards never adds time', () {
      expect(clock.remaining(at(-3600)), limit);
    });
  });

  group('playback', () {
    final clock = ScreenTimeClock.start(
      limit: limit,
      mode: TimerMode.playback,
      now: t0,
    );

    test('starts stopped and only counts while running', () {
      expect(clock.isRunning, isFalse);
      expect(clock.remaining(at(300)), limit);
      final played = clock.resume(at(0)).pause(at(120));
      expect(played.remaining(at(9999)), const Duration(minutes: 8));
      final more = played.resume(at(500)).pause(at(560));
      expect(more.used(at(9999)), const Duration(minutes: 3));
    });

    test('resume/pause are idempotent', () {
      final running = clock.resume(at(0));
      expect(running.resume(at(50)).runningSince, at(0));
      expect(clock.pause(at(50)), same(clock));
    });

    test('restore drops time after the last checkpoint', () {
      final checkpointed = clock.resume(at(0)).checkpoint(at(100));
      expect(checkpointed.banked, const Duration(seconds: 100));
      expect(checkpointed.runningSince, at(100));
      final restored = ScreenTimeClock.fromJson(checkpointed.toJson())
          .restore();
      expect(restored.isRunning, isFalse);
      expect(restored.used(at(5000)), const Duration(seconds: 100));
    });
  });

  group('time up and extensions', () {
    test('extension after time up starts from zero, however long the wait', () {
      final up = ScreenTimeClock.start(
        limit: limit,
        mode: TimerMode.wallClock,
        now: t0,
      ).pause(at(900)).stopAtLimit();
      expect(up.isUp(at(5000)), isTrue);
      final extended = up.extend(const Duration(minutes: 5)).resume(at(5000));
      expect(extended.remaining(at(5000)), const Duration(minutes: 5));
      expect(extended.remaining(at(5060)), const Duration(minutes: 4));
    });

    test('overrun measures time past the limit', () {
      final clock = ScreenTimeClock.start(
        limit: limit,
        mode: TimerMode.wallClock,
        now: t0,
      );
      expect(clock.overrun(at(500)), Duration.zero);
      expect(clock.overrun(at(660)), const Duration(minutes: 1));
    });

    test('extending a running clock just raises the limit', () {
      final clock = ScreenTimeClock.start(
        limit: limit,
        mode: TimerMode.wallClock,
        now: t0,
      ).extend(const Duration(minutes: 5));
      expect(clock.remaining(at(0)), const Duration(minutes: 15));
    });
  });

  test('JSON round trip', () {
    final clock = ScreenTimeClock(
      limit: limit,
      mode: TimerMode.playback,
      banked: const Duration(seconds: 42),
      runningSince: at(10),
    );
    final copy = ScreenTimeClock.fromJson(clock.toJson());
    expect(copy.limit, clock.limit);
    expect(copy.mode, clock.mode);
    expect(copy.banked, clock.banked);
    expect(copy.runningSince, clock.runningSince);
  });
}

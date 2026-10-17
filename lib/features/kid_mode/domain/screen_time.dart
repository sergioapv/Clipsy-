import 'package:flutter/foundation.dart';

import 'kid_settings.dart';

/// Immutable screen-time accounting.
///
/// Time is [banked] while stopped and accrues from [runningSince] while
/// running. Persisting both lets the session survive the app being killed:
/// in [TimerMode.wallClock] the time the app was dead still counts, so
/// killing the app is never a way to get more time; in [TimerMode.playback]
/// it doesn't count, because nothing was playing.
@immutable
class ScreenTimeClock {
  const ScreenTimeClock({
    required this.limit,
    required this.mode,
    this.banked = Duration.zero,
    this.runningSince,
  });

  /// A new clock. Wall-clock mode starts counting immediately.
  factory ScreenTimeClock.start({
    required Duration limit,
    required TimerMode mode,
    required DateTime now,
  }) => ScreenTimeClock(
    limit: limit,
    mode: mode,
    runningSince: mode == TimerMode.wallClock ? now : null,
  );

  factory ScreenTimeClock.fromJson(Map<String, Object?> json) =>
      ScreenTimeClock(
        limit: Duration(milliseconds: (json['limitMs']! as num).toInt()),
        mode: TimerMode.values.byName(json['mode']! as String),
        banked: Duration(milliseconds: (json['bankedMs']! as num).toInt()),
        runningSince: json['runningSince'] == null
            ? null
            : DateTime.parse(json['runningSince']! as String),
      );

  static const almostDoneAt = Duration(minutes: 1);

  final Duration limit;
  final TimerMode mode;
  final Duration banked;
  final DateTime? runningSince;

  bool get isRunning => runningSince != null;

  Duration used(DateTime now) {
    final since = runningSince;
    if (since == null) return banked;
    final delta = now.difference(since);
    // A clock moved backwards never gives time back.
    return banked + (delta.isNegative ? Duration.zero : delta);
  }

  Duration remaining(DateTime now) {
    final left = limit - used(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isUp(DateTime now) => remaining(now) == Duration.zero;

  bool isAlmostDone(DateTime now) {
    final left = remaining(now);
    return left > Duration.zero && left <= almostDoneAt;
  }

  /// How far past the limit the session has run (for "finish the video").
  Duration overrun(DateTime now) {
    final over = used(now) - limit;
    return over.isNegative ? Duration.zero : over;
  }

  ScreenTimeClock resume(DateTime now) => isRunning
      ? this
      : ScreenTimeClock(
          limit: limit,
          mode: mode,
          banked: banked,
          runningSince: now,
        );

  ScreenTimeClock pause(DateTime now) => isRunning
      ? ScreenTimeClock(limit: limit, mode: mode, banked: used(now))
      : this;

  /// Banks time so far, keeping the clock running. Called periodically so
  /// a crash in playback mode loses at most one checkpoint interval.
  ScreenTimeClock checkpoint(DateTime now) => isRunning
      ? ScreenTimeClock(
          limit: limit,
          mode: mode,
          banked: used(now),
          runningSince: now,
        )
      : this;

  /// Stops at exactly the limit, so later extensions start from zero
  /// regardless of how long the time's-up screen was shown.
  ScreenTimeClock stopAtLimit() => ScreenTimeClock(
    limit: limit,
    mode: mode,
    banked: banked > limit ? banked : limit,
  );

  /// Adds [extra] time. When stopped past the limit (time's up), the extra
  /// time starts from what was already used.
  ScreenTimeClock extend(Duration extra) => ScreenTimeClock(
    limit: (!isRunning && banked > limit ? banked : limit) + extra,
    mode: mode,
    banked: banked,
    runningSince: runningSince,
  );

  /// After an app restart: wall-clock time kept running while the app was
  /// dead; playback time did not (the video wasn't playing).
  ScreenTimeClock restore() => mode == TimerMode.playback && isRunning
      ? ScreenTimeClock(limit: limit, mode: mode, banked: banked)
      : this;

  Map<String, Object?> toJson() => {
    'limitMs': limit.inMilliseconds,
    'mode': mode.name,
    'bankedMs': banked.inMilliseconds,
    'runningSince': runningSince?.toUtc().toIso8601String(),
  };
}

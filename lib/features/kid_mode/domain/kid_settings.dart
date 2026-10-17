import 'package:flutter/foundation.dart';

/// What counts towards the time limit.
enum TimerMode {
  /// Real time since Kid mode started, including pauses (default).
  wallClock,

  /// Only time a video is actually playing.
  playback,
}

/// What happens when the time limit is reached.
enum EndBehaviour {
  /// Pause immediately (default).
  hardStop,

  /// Let the current video finish, then stop (capped by
  /// [KidModeSettings.maxOverrun]).
  finishVideo,
}

/// Parent preferences for Kid mode, stored on the device.
@immutable
class KidModeSettings {
  const KidModeSettings({
    this.defaultLimit = const Duration(minutes: 20),
    this.timerMode = TimerMode.wallClock,
    this.endBehaviour = EndBehaviour.hardStop,
    this.exitHold = const Duration(seconds: 3),
  });

  static const limitPresets = [10, 15, 20, 30, 45, 60];
  static const exitHoldPresets = [3, 5, 8];
  static const minLimit = Duration(minutes: 1);
  static const maxLimit = Duration(hours: 4);

  /// "Finish the current video" never runs longer than this past the limit.
  static const maxOverrun = Duration(minutes: 10);

  final Duration defaultLimit;
  final TimerMode timerMode;
  final EndBehaviour endBehaviour;

  /// How long the exit button must be held before the PIN is asked.
  final Duration exitHold;

  KidModeSettings copyWith({
    Duration? defaultLimit,
    TimerMode? timerMode,
    EndBehaviour? endBehaviour,
    Duration? exitHold,
  }) => KidModeSettings(
    defaultLimit: defaultLimit ?? this.defaultLimit,
    timerMode: timerMode ?? this.timerMode,
    endBehaviour: endBehaviour ?? this.endBehaviour,
    exitHold: exitHold ?? this.exitHold,
  );

  @override
  bool operator ==(Object other) =>
      other is KidModeSettings &&
      other.defaultLimit == defaultLimit &&
      other.timerMode == timerMode &&
      other.endBehaviour == endBehaviour &&
      other.exitHold == exitHold;

  @override
  int get hashCode =>
      Object.hash(defaultLimit, timerMode, endBehaviour, exitHold);
}

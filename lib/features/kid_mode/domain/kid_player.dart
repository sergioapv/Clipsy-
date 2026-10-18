import 'package:flutter/widgets.dart';

/// What the Kid mode screen hears from the video player.
sealed class KidPlayerEvent {
  const KidPlayerEvent();
}

final class PlayerPlaying extends KidPlayerEvent {
  const PlayerPlaying();
}

final class PlayerPaused extends KidPlayerEvent {
  const PlayerPaused();
}

final class PlayerEnded extends KidPlayerEvent {
  const PlayerEnded();
}

/// The current video can't be played (removed, private, not embeddable).
final class PlayerFailed extends KidPlayerEvent {
  const PlayerFailed(this.code);

  final int code;
}

final class PlayerDurationKnown extends KidPlayerEvent {
  const PlayerDurationKnown(this.seconds);

  final int seconds;
}

/// Where playback is in the current video.
@immutable
class PlaybackPosition {
  const PlaybackPosition(this.position, this.duration);

  static const zero = PlaybackPosition(Duration.zero, Duration.zero);

  final Duration position;

  /// [Duration.zero] until the player knows the video's length.
  final Duration duration;

  bool get hasDuration => duration > Duration.zero;

  /// 0–1, or 0 while the length is unknown.
  double get fraction => hasDuration
      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
      : 0;

  /// [position] moved by [delta], kept inside the video (and short of its
  /// very end, so a skip forward never ends the video by itself).
  Duration movedBy(Duration delta) {
    final target = position + delta;
    if (target < Duration.zero) return Duration.zero;
    if (!hasDuration) return target;
    final last = duration - const Duration(seconds: 1);
    return target > last
        ? (last < Duration.zero ? Duration.zero : last)
        : target;
  }

  @override
  bool operator ==(Object other) =>
      other is PlaybackPosition &&
      other.position == position &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(position, duration);
}

/// Thin seam over the YouTube IFrame player, so Kid mode logic and widgets
/// can be tested without a web view.
abstract interface class KidPlayer {
  Stream<KidPlayerEvent> get events;

  /// Playback position updates (a few per second while playing, and after
  /// every seek).
  Stream<PlaybackPosition> get positions;

  Widget buildView(BuildContext context);

  Future<void> load(String videoId, {required bool autoplay});
  Future<void> play();
  Future<void> pause();

  /// Jumps to [position] in the current video.
  Future<void> seekTo(Duration position);

  Future<void> dispose();
}

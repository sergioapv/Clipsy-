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

/// Thin seam over the YouTube IFrame player, so Kid mode logic and widgets
/// can be tested without a web view.
abstract interface class KidPlayer {
  Stream<KidPlayerEvent> get events;

  Widget buildView(BuildContext context);

  Future<void> load(String videoId, {required bool autoplay});
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

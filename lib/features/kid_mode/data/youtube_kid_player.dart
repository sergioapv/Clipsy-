import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../domain/kid_navigation_policy.dart';
import '../domain/kid_player.dart';

/// [KidPlayer] backed by the official YouTube IFrame player.
///
/// YouTube terms: playback only through the IFrame player, no downloading,
/// no background audio, ads and YouTube branding are never covered or hidden.
/// To stop children leaving the app, the web view ignores touches (our own
/// big controls drive the player) and every navigation away from the embed is
/// blocked rather than opened externally.
class YoutubeKidPlayer implements KidPlayer {
  YoutubeKidPlayer() {
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        // rel=0: end-of-video suggestions come from the same channel only.
        strictRelatedVideos: true,
        showVideoAnnotations: false,
        enableKeyboard: false,
        // Taps never reach the iframe, so logo/title/end-screen links and
        // "Watch on YouTube" can't be activated.
        pointerEvents: PointerEvents.none,
        playsInline: true,
        privacyEnhancedMode: true,
      ),
    );
    final base = Uri.parse(_controller.params.host);
    // Replaces the package's delegate, which would open some links in the
    // YouTube app and load related videos that aren't in the playlist.
    unawaited(
      _controller.webViewController.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              KidNavigationPolicy.allows(
                Uri.tryParse(request.url),
                playerBaseUrl: base,
              )
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      ),
    );
    _subscription = _controller.stream.listen(_onValue);
  }

  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _subscription;
  final _events = StreamController<KidPlayerEvent>.broadcast();
  PlayerState? _lastState;
  YoutubeError _lastError = YoutubeError.none;
  int? _lastDuration;

  void _onValue(YoutubePlayerValue v) {
    if (v.error != YoutubeError.none && v.error != _lastError) {
      _events.add(PlayerFailed(v.error.code));
    }
    _lastError = v.error;

    final seconds = v.metaData.duration.inSeconds;
    if (seconds > 0 && seconds != _lastDuration) {
      _lastDuration = seconds;
      _events.add(PlayerDurationKnown(seconds));
    }

    if (v.playerState == _lastState) return;
    _lastState = v.playerState;
    switch (v.playerState) {
      case PlayerState.playing:
        _events.add(const PlayerPlaying());
      case PlayerState.paused:
        _events.add(const PlayerPaused());
      case PlayerState.ended:
        _events.add(const PlayerEnded());
      case PlayerState.unknown ||
          PlayerState.unStarted ||
          PlayerState.buffering ||
          PlayerState.cued:
        break;
    }
  }

  @override
  Stream<KidPlayerEvent> get events => _events.stream;

  @override
  Widget buildView(BuildContext context) => YoutubePlayer(
    controller: _controller,
    enableFullScreenOnVerticalDrag: false,
    autoFullScreen: false,
  );

  @override
  Future<void> load(String videoId, {required bool autoplay}) {
    _lastDuration = null;
    return autoplay
        ? _controller.loadVideoById(videoId: videoId)
        : _controller.cueVideoById(videoId: videoId);
  }

  @override
  Future<void> play() => _controller.playVideo();

  @override
  Future<void> pause() => _controller.pauseVideo();

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _events.close();
    await _controller.close();
  }
}

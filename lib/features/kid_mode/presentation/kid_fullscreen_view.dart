import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/kid_session.dart';
import 'kid_mode_controller.dart';
import 'widgets/kid_round_button.dart';
import 'widgets/time_badge.dart';

/// Full-screen playback in Kid mode (landscape).
///
/// Controls never sit on the video while it plays if they can avoid it:
/// on wide screens they live in the black bars beside the 16:9 video; on
/// narrower screens they appear on tap and hide again after a few seconds,
/// so YouTube's ads and branding stay visible.
class KidFullscreenView extends StatefulWidget {
  const KidFullscreenView({
    required this.state,
    required this.player,
    required this.exitButton,
    required this.onPlayPause,
    required this.onExitFullscreen,
    super.key,
  });

  final KidModeState state;
  final Widget player;
  final Widget exitButton;
  final VoidCallback onPlayPause;
  final VoidCallback onExitFullscreen;

  /// Black bars at least this wide hold the controls.
  static const sideBarMinWidth = 96.0;

  /// How long tap-revealed controls stay visible.
  static const controlsTimeout = Duration(seconds: 4);

  @override
  State<KidFullscreenView> createState() => _KidFullscreenViewState();
}

class _KidFullscreenViewState extends State<KidFullscreenView> {
  bool _controlsVisible = true;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(KidFullscreenView.controlsTimeout, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = widget.state;
    final badge = FittedBox(
      fit: BoxFit.scaleDown,
      child: TimeBadge(
        remaining: s.remaining,
        limit: s.session.clock.limit,
        almostDone: s.isAlmostDone,
        lastVideo: s.session.status == KidSessionStatus.finishingVideo,
      ),
    );
    final playPause = KidRoundButton(
      key: const Key('kid-play-pause'),
      icon: s.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      label: s.isPlaying ? l10n.kidPause : l10n.kidPlay,
      onPressed: () {
        widget.onPlayPause();
        _scheduleHide();
      },
      size: 72,
      dark: true,
    );
    final exitFullscreen = KidRoundButton(
      key: const Key('kid-exit-fullscreen'),
      icon: Icons.fullscreen_exit_rounded,
      label: l10n.kidExitFullscreen,
      onPressed: widget.onExitFullscreen,
      dark: true,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, c) {
          final videoWidth = c.maxWidth.clamp(0.0, c.maxHeight * 16 / 9);
          final sideBar = (c.maxWidth - videoWidth) / 2;
          final video = Center(
            child: SizedBox(
              width: videoWidth,
              height: videoWidth * 9 / 16,
              child: widget.player,
            ),
          );

          if (sideBar >= KidFullscreenView.sideBarMinWidth) {
            // Controls live in the black bars; nothing covers the video.
            return SafeArea(
              child: Row(
                children: [
                  SizedBox(
                    width: sideBar,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        widget.exitButton,
                        const Spacer(),
                        Padding(padding: const EdgeInsets.all(8), child: badge),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Expanded(child: video),
                  SizedBox(
                    width: sideBar,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        playPause,
                        const SizedBox(height: 24),
                        exitFullscreen,
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Narrow screens: controls over the video, revealed by a tap and
          // hidden again shortly after.
          return Stack(
            children: [
              video,
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('kid-fullscreen-tap'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _showControls,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: AnimatedOpacity(
                    opacity: _controlsVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                badge,
                                const Spacer(),
                                widget.exitButton,
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                playPause,
                                const SizedBox(width: 24),
                                exitFullscreen,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

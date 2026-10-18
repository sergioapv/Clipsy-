import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/kid_session.dart';
import 'kid_mode_controller.dart';
import 'widgets/kid_round_button.dart';
import 'widgets/kid_thumbnail_strip.dart';
import 'widgets/time_badge.dart';

/// Full-screen playback in Kid mode (landscape).
///
/// Controls: play/pause, next video, a video picker, and exit full screen,
/// plus the timer and the parent lock. On most phones they live in the black
/// bars beside the 16:9 video, so nothing covers it. On screens without room
/// for that they appear on tap and hide again after a few seconds, so ads and
/// YouTube branding stay visible. System back leaves full screen (handled by
/// the Kid mode screen), never Kid mode.
class KidFullscreenView extends StatefulWidget {
  const KidFullscreenView({
    required this.state,
    required this.player,
    required this.exitButton,
    required this.onPlayPause,
    required this.onNext,
    required this.onSelect,
    required this.onExitFullscreen,
    super.key,
  });

  final KidModeState state;
  final Widget player;
  final Widget exitButton;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final ValueChanged<int> onSelect;
  final VoidCallback onExitFullscreen;

  /// Black bars at least this wide hold the controls.
  static const sideBarMinWidth = 72.0;

  /// How long tap-revealed controls stay visible.
  static const controlsTimeout = Duration(seconds: 4);

  @override
  State<KidFullscreenView> createState() => _KidFullscreenViewState();
}

class _KidFullscreenViewState extends State<KidFullscreenView> {
  bool _controlsVisible = true;
  bool _pickerOpen = false;
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
      // Never hide while the child is choosing a video.
      if (mounted && !_pickerOpen) setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _togglePicker() {
    setState(() {
      _pickerOpen = !_pickerOpen;
      _controlsVisible = true;
    });
    _scheduleHide();
  }

  void _pick(int index) {
    widget.onSelect(index);
    setState(() => _pickerOpen = false);
    _scheduleHide();
  }

  /// Wraps a control so using it also keeps the controls on screen.
  VoidCallback _keepAlive(VoidCallback action) => () {
    action();
    _scheduleHide();
  };

  List<Widget> _buttons(double size) {
    final l10n = context.l10n;
    final s = widget.state;
    final watching = s.session.status == KidSessionStatus.watching;
    final multiple = s.session.videos.length > 1;
    return [
      KidRoundButton(
        key: const Key('kid-play-pause'),
        icon: s.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        label: s.isPlaying ? l10n.kidPause : l10n.kidPlay,
        onPressed: _keepAlive(widget.onPlayPause),
        size: size,
        dark: true,
      ),
      if (watching && multiple) ...[
        KidRoundButton(
          key: const Key('kid-next'),
          icon: Icons.skip_next_rounded,
          label: l10n.kidNextVideo,
          onPressed: _keepAlive(widget.onNext),
          size: size,
          dark: true,
        ),
        KidRoundButton(
          key: const Key('kid-pick-video'),
          icon: Icons.video_library_rounded,
          label: l10n.kidPickVideo,
          onPressed: _togglePicker,
          size: size,
          dark: true,
        ),
      ],
      KidRoundButton(
        key: const Key('kid-exit-fullscreen'),
        icon: Icons.fullscreen_exit_rounded,
        label: l10n.kidExitFullscreen,
        onPressed: widget.onExitFullscreen,
        size: size,
        dark: true,
      ),
    ];
  }

  Widget _picker() => Container(
    key: const Key('kid-video-picker'),
    height: 150,
    color: Colors.black87,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: KidThumbnailStrip(
      videos: widget.state.session.videos,
      currentIndex: widget.state.session.currentIndex,
      onSelect: _pick,
    ),
  );

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final videoWidth = math.min(c.maxWidth, c.maxHeight * 16 / 9);
            final sideBar = (c.maxWidth - videoWidth) / 2;
            final video = Center(
              child: SizedBox(
                width: videoWidth,
                height: videoWidth * 9 / 16,
                child: widget.player,
              ),
            );
            final picker = Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _picker(),
            );

            if (sideBar >= KidFullscreenView.sideBarMinWidth) {
              // Controls live in the black bars; nothing covers the video
              // unless the child opens the video picker.
              final size = math.min(64.0, sideBar - 16);
              final buttons = _buttons(size);
              return Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: sideBar,
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            widget.exitButton,
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: badge,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      Expanded(child: video),
                      SizedBox(
                        width: sideBar,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: buttons,
                        ),
                      ),
                    ],
                  ),
                  if (_pickerOpen) picker,
                ],
              );
            }

            // No room beside the video: controls over it, shown on tap.
            final buttons = _buttons(64);
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
                                for (final (i, b) in buttons.indexed) ...[
                                  if (i > 0) const SizedBox(width: 20),
                                  b,
                                ],
                              ],
                            ),
                            // Keep the buttons above the open picker.
                            if (_pickerOpen) const SizedBox(height: 150),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_pickerOpen) picker,
              ],
            );
          },
        ),
      ),
    );
  }
}

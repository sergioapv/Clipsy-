import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/kid_session.dart';
import 'kid_mode_controller.dart';
import 'widgets/compact_time_badge.dart';
import 'widgets/kid_round_button.dart';
import 'widgets/kid_thumbnail_strip.dart';

/// Full-screen playback in Kid mode (landscape).
///
/// The video sits on the left; one panel on the right holds everything,
/// always visible: the countdown and parent lock, pause/play and next video,
/// the video picker and exit full screen. Choosing a video turns the panel
/// into a list of thumbnails.
///
/// Nothing is ever drawn over the YouTube player: it's a native web view, and
/// overlays on it are unreliable on some Android devices (and could cover
/// ads or branding). When the screen's spare width is too narrow for the
/// panel, the video shrinks to make room. System back leaves full screen
/// (handled by the Kid mode screen), never Kid mode.
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

  /// The control panel is at least this wide.
  static const panelMinWidth = 160.0;

  @override
  State<KidFullscreenView> createState() => _KidFullscreenViewState();
}

class _KidFullscreenViewState extends State<KidFullscreenView> {
  bool _pickerOpen = false;

  void _pick(int index) {
    widget.onSelect(index);
    setState(() => _pickerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.kidNight(),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final panel = math.max(
                KidFullscreenView.panelMinWidth,
                c.maxWidth - c.maxHeight * 16 / 9,
              );
              final videoWidth = math.max(0.0, c.maxWidth - panel);
              final videoHeight = math.min(c.maxHeight, videoWidth * 9 / 16);
              return Row(
                children: [
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: videoWidth,
                        height: videoHeight,
                        child: widget.player,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: panel,
                    height: c.maxHeight,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _pickerOpen
                          ? _picker(panel)
                          : _controls(panel, c.maxHeight),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Three rows of two: countdown + lock, pause/play + next,
  /// choose a video + exit full screen.
  Widget _controls(double width, double height) {
    final l10n = context.l10n;
    final s = widget.state;
    final watching = s.session.status == KidSessionStatus.watching;
    final multiple = s.session.videos.length > 1;
    final size = math.min(64.0, math.min((width - 36) / 2, (height - 48) / 3));

    Widget button(
      String key,
      IconData icon,
      String label,
      VoidCallback onPressed, {
      bool primary = false,
    }) => KidRoundButton(
      key: Key(key),
      icon: icon,
      label: label,
      onPressed: onPressed,
      size: size,
      primary: primary,
    );

    Widget row(Widget a, Widget? b) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: size,
          child: Center(child: a),
        ),
        SizedBox(
          width: size,
          child: b == null ? null : Center(child: b),
        ),
      ],
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        row(
          CompactTimeBadge(
            remaining: s.remaining,
            limit: s.session.clock.limit,
            almostDone: s.isAlmostDone,
            lastVideo: s.session.status == KidSessionStatus.finishingVideo,
            size: size,
          ),
          widget.exitButton,
        ),
        row(
          button(
            'kid-play-pause',
            s.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            s.isPlaying ? l10n.kidPause : l10n.kidPlay,
            widget.onPlayPause,
            primary: true,
          ),
          watching && multiple
              ? button(
                  'kid-next',
                  Icons.skip_next_rounded,
                  l10n.kidNextVideo,
                  widget.onNext,
                )
              : null,
        ),
        row(
          watching && multiple
              ? button(
                  'kid-pick-video',
                  Icons.video_library_rounded,
                  l10n.kidPickVideo,
                  () => setState(() => _pickerOpen = true),
                )
              : const SizedBox.shrink(),
          button(
            'kid-exit-fullscreen',
            Icons.fullscreen_exit_rounded,
            l10n.kidExitFullscreen,
            widget.onExitFullscreen,
          ),
        ),
      ],
    );
  }

  /// The panel as a scrolling list of thumbnails, with a close button.
  Widget _picker(double width) {
    final l10n = context.l10n;
    return Column(
      key: const Key('kid-video-picker'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 10, 8),
          child: KidRoundButton(
            key: const Key('kid-close-picker'),
            icon: Icons.close_rounded,
            label: l10n.close,
            onPressed: () => setState(() => _pickerOpen = false),
            size: 48,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: KidThumbnailStrip(
              videos: widget.state.session.videos,
              currentIndex: widget.state.session.currentIndex,
              onSelect: _pick,
              axis: Axis.vertical,
            ),
          ),
        ),
      ],
    );
  }
}

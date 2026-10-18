import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/kid_player.dart';
import '../domain/kid_session.dart';
import 'kid_mode_controller.dart';
import 'widgets/compact_time_badge.dart';
import 'widgets/kid_round_button.dart';
import 'widgets/kid_seek_bar.dart';
import 'widgets/kid_thumbnail_strip.dart';

/// Full-screen playback in Kid mode (landscape).
///
/// The video sits on the left; one panel on the right holds everything,
/// always visible: the countdown, pause/play and next video, a button that
/// shows or hides the seek strip (back 10 s, a bar to drag, forward 10 s,
/// under the video), the video picker and exit full screen. The parent lock
/// isn't here: a parent leaves full screen first, then holds the lock. Choosing a video turns the panel
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
    required this.onPlayPause,
    required this.onNext,
    required this.onSelect,
    required this.onSkip,
    required this.position,
    required this.onSeek,
    required this.onExitFullscreen,
    super.key,
  });

  final KidModeState state;
  final Widget player;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final ValueChanged<int> onSelect;

  /// Seconds to move through the video by (negative: back).
  final ValueChanged<int> onSkip;
  final ValueListenable<PlaybackPosition> position;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onExitFullscreen;

  /// The control panel is at least this wide.
  static const panelMinWidth = 160.0;

  /// Height of the seek strip under the video, when it's open.
  static const seekStripHeight = 76.0;

  @override
  State<KidFullscreenView> createState() => _KidFullscreenViewState();
}

class _KidFullscreenViewState extends State<KidFullscreenView> {
  bool _pickerOpen = false;
  bool _seekOpen = false;

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
              // The seek strip takes room from the video rather than sitting
              // on top of it.
              final seeking = _seekOpen && _canSeek;
              final videoArea = math.max(
                0.0,
                c.maxHeight - (seeking ? KidFullscreenView.seekStripHeight : 0),
              );
              final videoWidth = math.min(
                math.max(0.0, c.maxWidth - panel),
                videoArea * 16 / 9,
              );
              final videoHeight = math.min(videoArea, videoWidth * 9 / 16);
              return Row(
                children: [
                  Expanded(
                    child: Column(
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
                        if (seeking) _seekStrip(),
                      ],
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

  bool get _canSeek => widget.state.session.status == KidSessionStatus.watching;

  /// Under the video: back 10 s, a bar to drag, forward 10 s.
  Widget _seekStrip() {
    final l10n = context.l10n;
    return SizedBox(
      key: const Key('kid-seek-strip'),
      height: KidFullscreenView.seekStripHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 14),
        child: Row(
          children: [
            KidRoundButton(
              key: const Key('kid-seek-back'),
              icon: Icons.replay_10_rounded,
              label: l10n.kidSeekBack,
              onPressed: () => widget.onSkip(-10),
              size: 56,
            ),
            Expanded(
              child: KidSeekBar(
                position: widget.position,
                onSeek: widget.onSeek,
              ),
            ),
            KidRoundButton(
              key: const Key('kid-seek-forward'),
              icon: Icons.forward_10_rounded,
              label: l10n.kidSeekForward,
              onPressed: () => widget.onSkip(10),
              size: 56,
            ),
          ],
        ),
      ),
    );
  }

  /// Symmetric about the panel's centre line: the countdown on top,
  /// pause/play + next and seek + choose a video in the middle, exit full
  /// screen at the bottom. A row with one button centres it.
  Widget _controls(double width, double height) {
    final l10n = context.l10n;
    final s = widget.state;
    final watching = s.session.status == KidSessionStatus.watching;
    final multiple = s.session.videos.length > 1;
    final size = math.min(64.0, math.min((width - 36) / 2, (height - 64) / 4));

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

    Widget row(List<Widget> buttons) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CompactTimeBadge(
          remaining: s.remaining,
          limit: s.session.clock.limit,
          almostDone: s.isAlmostDone,
          lastVideo: s.session.status == KidSessionStatus.finishingVideo,
          size: size,
        ),
        row([
          button(
            'kid-play-pause',
            s.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            s.isPlaying ? l10n.kidPause : l10n.kidPlay,
            widget.onPlayPause,
            primary: true,
          ),
          if (watching && multiple)
            button(
              'kid-next',
              Icons.skip_next_rounded,
              l10n.kidNextVideo,
              widget.onNext,
            ),
        ]),
        if (watching)
          row([
            KidRoundButton(
              key: const Key('kid-seek-toggle'),
              icon: Icons.linear_scale_rounded,
              label: _seekOpen ? l10n.kidSeekHide : l10n.kidSeekShow,
              onPressed: () => setState(() => _seekOpen = !_seekOpen),
              size: size,
              selected: _seekOpen,
            ),
            if (multiple)
              button(
                'kid-pick-video',
                Icons.video_library_rounded,
                l10n.kidPickVideo,
                () => setState(() => _pickerOpen = true),
              ),
          ]),
        button(
          'kid-exit-fullscreen',
          Icons.fullscreen_exit_rounded,
          l10n.kidExitFullscreen,
          widget.onExitFullscreen,
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/kid_session.dart';
import 'kid_mode_controller.dart';
import 'widgets/compact_time_badge.dart';
import 'widgets/kid_round_button.dart';
import 'widgets/kid_thumbnail_strip.dart';

/// Full-screen playback in Kid mode (landscape).
///
/// Everything stays visible, on every phone: a column on each side of the
/// video holds the countdown and the parent lock (left) and pause/play, next
/// video, the video picker and exit full screen (right). When the screen's
/// own black bars are too narrow, the video shrinks a little to make room,
/// so controls never sit on the video, its ads or YouTube's branding.
/// System back also leaves full screen (handled by the Kid mode screen),
/// never Kid mode.
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

  /// Each side column is at least this wide.
  static const columnWidth = 88.0;

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
    final l10n = context.l10n;
    final s = widget.state;
    final watching = s.session.status == KidSessionStatus.watching;
    final multiple = s.session.videos.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final column = math.max(
              KidFullscreenView.columnWidth,
              (c.maxWidth - c.maxHeight * 16 / 9) / 2,
            );
            final videoWidth = math.max(0.0, c.maxWidth - 2 * column);
            final videoHeight = math.min(c.maxHeight, videoWidth * 9 / 16);
            // Four buttons stacked in the right column must fit the height.
            final buttonSize = math.min(
              60.0,
              math.min(column - 16, (c.maxHeight - 48) / 4.4),
            );

            Widget button(
              String key,
              IconData icon,
              String label,
              VoidCallback onPressed,
            ) => KidRoundButton(
              key: Key(key),
              icon: icon,
              label: label,
              onPressed: onPressed,
              size: buttonSize,
              dark: true,
            );

            return Row(
              children: [
                SizedBox(
                  width: column,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      widget.exitButton,
                      const Spacer(),
                      CompactTimeBadge(
                        remaining: s.remaining,
                        limit: s.session.clock.limit,
                        almostDone: s.isAlmostDone,
                        lastVideo:
                            s.session.status == KidSessionStatus.finishingVideo,
                        size: math.min(72, column - 12),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: videoWidth,
                          height: videoHeight,
                          child: widget.player,
                        ),
                      ),
                      if (_pickerOpen)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            key: const Key('kid-video-picker'),
                            height: math.min(150, c.maxHeight * 0.45),
                            color: Colors.black87,
                            padding: const EdgeInsets.all(12),
                            child: LayoutBuilder(
                              // Fit 16:9 thumbnails (plus their highlight
                              // border) to the strip's height.
                              builder: (context, strip) => KidThumbnailStrip(
                                videos: s.session.videos,
                                currentIndex: s.session.currentIndex,
                                onSelect: _pick,
                                tileWidth: (strip.maxHeight - 10) * 16 / 9,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: column,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      button(
                        'kid-play-pause',
                        s.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        s.isPlaying ? l10n.kidPause : l10n.kidPlay,
                        widget.onPlayPause,
                      ),
                      if (watching && multiple) ...[
                        button(
                          'kid-next',
                          Icons.skip_next_rounded,
                          l10n.kidNextVideo,
                          widget.onNext,
                        ),
                        button(
                          'kid-pick-video',
                          _pickerOpen
                              ? Icons.close_rounded
                              : Icons.video_library_rounded,
                          l10n.kidPickVideo,
                          () => setState(() => _pickerOpen = !_pickerOpen),
                        ),
                      ],
                      button(
                        'kid-exit-fullscreen',
                        Icons.fullscreen_exit_rounded,
                        l10n.kidExitFullscreen,
                        widget.onExitFullscreen,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

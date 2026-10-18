import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/kid_player.dart';

/// A thick, finger-sized progress bar the child can drag to move through
/// the video. The player itself ignores touches (see YoutubeKidPlayer), so
/// this replaces YouTube's own seek bar.
class KidSeekBar extends StatefulWidget {
  const KidSeekBar({
    required this.position,
    required this.onSeek,
    this.enabled = true,
    super.key,
  });

  final ValueListenable<PlaybackPosition> position;
  final ValueChanged<Duration> onSeek;
  final bool enabled;

  @override
  State<KidSeekBar> createState() => _KidSeekBarState();
}

class _KidSeekBarState extends State<KidSeekBar> {
  /// While dragging: where the finger is, in milliseconds.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<PlaybackPosition>(
      valueListenable: widget.position,
      builder: (context, p, _) {
        final max = p.duration.inMilliseconds.toDouble();
        final value = (_dragging ?? p.position.inMilliseconds.toDouble()).clamp(
          0.0,
          max > 0 ? max : 0.0,
        );
        return Semantics(
          label: context.l10n.kidSeekBar,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 14,
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.surfaceContainer,
              thumbColor: scheme.primary,
              overlayColor: scheme.primary.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 16,
                elevation: 0,
                pressedElevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 30),
              trackShape: const RoundedRectSliderTrackShape(),
              showValueIndicator: ShowValueIndicator.never,
              disabledActiveTrackColor: scheme.onSurfaceVariant,
              disabledInactiveTrackColor: scheme.surfaceContainer,
              disabledThumbColor: scheme.onSurfaceVariant,
            ),
            child: Slider(
              key: const Key('kid-seek-bar'),
              max: max > 0 ? max : 1,
              value: max > 0 ? value : 0,
              onChanged: widget.enabled && max > 0
                  ? (v) => setState(() => _dragging = v)
                  : null,
              onChangeEnd: (v) {
                setState(() => _dragging = null);
                widget.onSeek(Duration(milliseconds: v.round()));
              },
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';

/// Countdown for full screen: a ring that empties as time runs out, with the
/// minutes left inside (and a m:ss countdown in the last minute). Sized for
/// the narrow side column.
class CompactTimeBadge extends StatelessWidget {
  const CompactTimeBadge({
    required this.remaining,
    required this.limit,
    required this.almostDone,
    required this.lastVideo,
    this.size = 68,
    super.key,
  });

  final Duration remaining;
  final Duration limit;
  final bool almostDone;
  final bool lastVideo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fraction = limit.inMilliseconds == 0
        ? 0.0
        : (remaining.inMilliseconds / limit.inMilliseconds).clamp(0.0, 1.0);
    final seconds = remaining.inSeconds;
    final minutes = (seconds / 60).ceil();
    final lastMinute = seconds <= 60;
    final highlight = almostDone || lastVideo;
    final color = highlight ? BrandColors.coral : BrandColors.mint;
    final big = lastMinute
        ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '$minutes';

    return Semantics(
      key: const Key('kid-countdown'),
      label: lastVideo
          ? l10n.kidLastVideo
          : almostDone
          ? l10n.kidAlmostDone
          : l10n.minutesLeft(minutes),
      liveRegion: highlight,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: size * 0.1,
                  color: color,
                  backgroundColor: Colors.white24,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    big,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: size * (lastMinute ? 0.26 : 0.34),
                      height: 1,
                    ),
                  ),
                  if (!lastMinute)
                    Text(
                      l10n.minutesUnit,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: size * 0.16,
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

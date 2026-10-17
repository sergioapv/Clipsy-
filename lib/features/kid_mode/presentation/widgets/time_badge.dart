import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';

/// A ring that empties as time runs out, readable without reading.
/// Turns into a gentle "Almost done!" pill in the last minute.
class TimeBadge extends StatelessWidget {
  const TimeBadge({
    required this.remaining,
    required this.limit,
    required this.almostDone,
    required this.lastVideo,
    super.key,
  });

  final Duration remaining;
  final Duration limit;
  final bool almostDone;
  final bool lastVideo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fraction = limit.inMilliseconds == 0
        ? 0.0
        : (remaining.inMilliseconds / limit.inMilliseconds).clamp(0.0, 1.0);
    final minutes = (remaining.inSeconds / 60).ceil();
    final highlight = almostDone || lastVideo;
    final color = highlight ? BrandColors.coral : BrandColors.mint;
    return Semantics(
      label: lastVideo
          ? l10n.kidLastVideo
          : almostDone
          ? l10n.kidAlmostDone
          : l10n.minutesLeft(minutes),
      liveRegion: highlight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFFFE3DA) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 40,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 7,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.2),
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                lastVideo
                    ? l10n.kidLastVideo
                    : almostDone
                    ? l10n.kidAlmostDone
                    : l10n.minutesShort(minutes),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2340),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

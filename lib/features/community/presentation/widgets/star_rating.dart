import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';

/// "4.6" in the current locale ("4,6" in Portuguese).
String formatRating(BuildContext context, double value) => NumberFormat(
  '0.0',
  Localizations.localeOf(context).toLanguageTag(),
).format(value);

/// Compact, read-only rating: a star, the average and the number of ratings.
class RatingSummary extends StatelessWidget {
  const RatingSummary({
    required this.average,
    required this.count,
    this.style,
    super.key,
  });

  final double? average;
  final int count;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodySmall;
    final avg = average;
    if (avg == null || count == 0) {
      return Text(l10n.ratingNone, style: base);
    }
    final value = formatRating(context, avg);
    return Semantics(
      label: '${l10n.ratingAverage(value)}, ${l10n.ratingCount(count)}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: (base?.fontSize ?? 13) * 1.3,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 3),
            Text(
              value,
              style: base?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' (${NumberFormat.decimalPattern().format(count)})',
              style: base,
            ),
          ],
        ),
      ),
    );
  }
}

/// Five tappable stars. [value] is 1–5, or `null` when not rated yet.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final current = value ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i == current,
            label: l10n.ratingStars(i),
            child: IconButton(
              key: Key('rate-star-$i'),
              onPressed: enabled ? () => onChanged(i) : null,
              iconSize: 36,
              visualDensity: VisualDensity.compact,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: Icon(
                  i <= current
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  key: ValueKey(i <= current),
                  color: i <= current
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

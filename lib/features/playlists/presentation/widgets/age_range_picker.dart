import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/playlist.dart';
import '../playlist_l10n.dart';

/// Preset age chips plus a slider for a custom range.
class AgeRangePicker extends StatelessWidget {
  const AgeRangePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final AgeRange value;
  final ValueChanged<AgeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final preset in AgeRange.presets)
              ChoiceChip(
                label: Text(l10n.ageRangeLabel(preset)),
                selected: value == preset,
                onSelected: (_) => onChanged(preset),
              ),
          ],
        ),
        RangeSlider(
          values: RangeValues(value.min.toDouble(), value.max.toDouble()),
          min: AgeRange.minAge.toDouble(),
          max: AgeRange.maxAge.toDouble(),
          divisions: AgeRange.maxAge - AgeRange.minAge,
          labels: RangeLabels('${value.min}', '${value.max}'),
          semanticFormatterCallback: (v) => l10n.ageYears(v.round()),
          onChanged: (r) => onChanged(AgeRange(r.start.round(), r.end.round())),
        ),
        Center(
          child: Text(
            l10n.ageRangeLabel(value),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

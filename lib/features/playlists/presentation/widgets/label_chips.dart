import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/label.dart';
import '../../domain/playlist.dart';
import '../playlist_l10n.dart';
import '../playlist_providers.dart';

/// Read-only tags for a playlist's labels, given by id or (for community
/// playlists) by slug.
class LabelChips extends ConsumerWidget {
  const LabelChips({
    this.labelIds = const [],
    this.labelSlugs = const [],
    super.key,
  });

  final List<int> labelIds;
  final List<String> labelSlugs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (labelIds.isEmpty && labelSlugs.isEmpty) return const SizedBox.shrink();
    final all = ref.watch(labelsProvider).value ?? const <Label>[];
    final l10n = context.l10n;
    final labels = [
      for (final l in all)
        if (labelIds.contains(l.id) || labelSlugs.contains(l.slug)) l,
    ];
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final l in labels)
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                l10n.labelName(l),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pick up to [PlaylistDraft.maxLabels] labels.
class LabelPicker extends ConsumerWidget {
  const LabelPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final labels = ref.watch(labelsProvider);
    return labels.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => TextButton.icon(
        onPressed: () => ref.invalidate(labelsProvider),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(l10n.retry),
      ),
      data: (all) {
        final full = selected.length >= PlaylistDraft.maxLabels;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in all)
              FilterChip(
                label: Text(l10n.labelName(label)),
                selected: selected.contains(label.id),
                onSelected: !selected.contains(label.id) && full
                    ? null
                    : (on) => onChanged(
                        on
                            ? [...selected, label.id]
                            : [...selected.where((id) => id != label.id)],
                      ),
              ),
          ],
        );
      },
    );
  }
}

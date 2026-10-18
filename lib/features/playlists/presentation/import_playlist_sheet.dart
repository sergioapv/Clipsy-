import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/imported_playlist.dart';
import '../domain/playlist.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';
import 'widgets/video_thumbnail.dart';

/// Shows what a YouTube playlist would add to [playlistId] and adds it.
/// Resolves to the number of videos added (0 if cancelled).
Future<int> showImportPlaylistSheet(
  BuildContext context, {
  required String playlistId,
  required String youtubePlaylistId,
}) async {
  final added = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => ImportPlaylistSheet(
      playlistId: playlistId,
      youtubePlaylistId: youtubePlaylistId,
    ),
  );
  return added ?? 0;
}

class ImportPlaylistSheet extends ConsumerStatefulWidget {
  const ImportPlaylistSheet({
    required this.playlistId,
    required this.youtubePlaylistId,
    super.key,
  });

  final String playlistId;
  final String youtubePlaylistId;

  @override
  ConsumerState<ImportPlaylistSheet> createState() =>
      _ImportPlaylistSheetState();
}

class _ImportPlaylistSheetState extends ConsumerState<ImportPlaylistSheet> {
  late Future<ImportedPlaylist> _load = _fetch();
  bool _adding = false;

  Future<ImportedPlaylist> _fetch() => ref
      .read(youTubePlaylistRepositoryProvider)
      .fetch(widget.youtubePlaylistId);

  Future<void> _add(ImportPlan plan) async {
    final l10n = context.l10n;
    setState(() => _adding = true);
    try {
      final added = await ref
          .read(playlistDetailControllerProvider(widget.playlistId).notifier)
          .addMany([for (final v in plan.toAdd) v.toMetadata()]);
      if (mounted) Navigator.pop(context, added);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _adding = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.playlistError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.watch(
      playlistDetailControllerProvider(widget.playlistId).notifier,
    );
    // Rebuild when the target playlist changes.
    ref.watch(playlistDetailControllerProvider(widget.playlistId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: FutureBuilder<ImportedPlaylist>(
        future: _load,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final error = snap.error;
          if (error != null) {
            final message = error is PlaylistImportException
                ? l10n.playlistImportError(error.error)
                : l10n.errorGeneric;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.importPlaylistTitle,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(message, key: const Key('import-error')),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => setState(() => _load = _fetch()),
                  child: Text(l10n.retry),
                ),
              ],
            );
          }
          final playlist = snap.requireData;
          final plan = ImportPlan.from(
            playlist,
            existingIds: controller.youtubeIds,
            capacity: controller.remainingCapacity,
          );
          final first = playlist.videos.where((v) => v.playable).firstOrNull;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.importPlaylistTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (first != null)
                    VideoThumbnail(
                      url: first.toMetadata().thumbnailUrl,
                      width: 112,
                      borderRadius: 8,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (playlist.channelName != null)
                          Text(
                            playlist.channelName!,
                            style: theme.textTheme.bodySmall,
                          ),
                        Text(
                          l10n.videoCount(playlist.videos.length),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (plan.alreadyThere > 0)
                _Note(l10n.importAlreadyThere(plan.alreadyThere)),
              if (plan.unavailable > 0)
                _Note(l10n.importUnavailable(plan.unavailable)),
              if (plan.overLimit > 0 || playlist.truncated)
                _Note(l10n.importOverLimit(PlaylistDraft.maxVideos)),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('import-add'),
                onPressed: plan.toAdd.isEmpty || _adding
                    ? null
                    : () => unawaited(_add(plan)),
                icon: _adding
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.playlist_add),
                label: Text(
                  plan.toAdd.isEmpty
                      ? l10n.importNothingToAdd
                      : l10n.importAddVideos(plan.toAdd.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

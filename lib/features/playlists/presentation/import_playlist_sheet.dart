import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../data/youtube_playlist_repository.dart';
import '../domain/imported_playlist.dart';
import '../domain/playlist.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';

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
  // Holding the subscription keeps the importer (and its hidden player)
  // alive while the sheet is open.
  late final ProviderSubscription<YouTubePlaylistRepository> _repoSub = ref
      .listenManual(youTubePlaylistRepositoryProvider, (_, _) {});
  late Future<ImportedPlaylist> _load = _fetch();
  bool _adding = false;
  ({int checked, int total})? _progress;

  @override
  void dispose() {
    _repoSub.close();
    super.dispose();
  }

  Future<ImportedPlaylist> _fetch() {
    _progress = null;
    return _repoSub.read().fetch(
      widget.youtubePlaylistId,
      onProgress: (checked, total) {
        if (mounted) {
          setState(() => _progress = (checked: checked, total: total));
        }
      },
    );
  }

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.importPlaylistTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          // The YouTube player that lists the playlist's videos, shown as a
          // preview. It must stay on screen until the list is read.
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              // Small enough that the add button stays on screen.
              width: 280,
              child: ClipRRect(
                key: const Key('import-preview'),
                borderRadius: BorderRadius.circular(16),
                child: _repoSub.read().buildHost(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _content(context, l10n, theme, controller),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    PlaylistDetailController controller,
  ) {
    return FutureBuilder<ImportedPlaylist>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          final p = _progress;
          return SizedBox(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    value: p == null || p.total == 0
                        ? null
                        : p.checked / p.total,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  p == null
                      ? l10n.importFindingVideos
                      : l10n.importCheckingVideos(p.checked, p.total),
                  key: const Key('import-progress'),
                ),
              ],
            ),
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              playlist.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              [
                ?playlist.channelName,
                l10n.videoCount(playlist.videos.length),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
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
                  : const Icon(Icons.playlist_add_rounded),
              label: Text(
                plan.toAdd.isEmpty
                    ? l10n.importNothingToAdd
                    : l10n.importAddVideos(plan.toAdd.length),
              ),
            ),
          ],
        );
      },
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
          Icons.info_outline_rounded,
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

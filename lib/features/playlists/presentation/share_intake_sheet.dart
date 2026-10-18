import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../domain/playlist.dart';
import '../domain/youtube_url_parser.dart';
import 'add_video_sheet.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';
import 'widgets/video_thumbnail.dart';

/// Handles a link shared to Clipsy: pick a playlist, then the usual add-video
/// sheet opens with the link already checked.
Future<void> handleSharedLink(
  BuildContext context,
  WidgetRef ref,
  String text,
) async {
  final l10n = context.l10n;
  ref.read(pendingShareProvider.notifier).clear();
  if (YouTubeUrlParser.extractVideoId(text) == null &&
      YouTubeUrlParser.extractPlaylistId(text) == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.shareIntakeNotYouTube)));
    return;
  }
  final playlistId = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const _PickPlaylistSheet(),
  );
  if (playlistId == null || !context.mounted) return;
  await showAddVideoSheet(context, playlistId, initialLink: text);
}

class _PickPlaylistSheet extends ConsumerWidget {
  const _PickPlaylistSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final playlists = ref.watch(myPlaylistsProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        key: const Key('share-intake-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              l10n.shareIntakeTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              l10n.shareIntakeBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: playlists.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.playlistError(e)),
              ),
              data: (items) => items.isEmpty
                  ? _NoPlaylists()
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      children: [
                        for (final Playlist p in items)
                          ListTile(
                            key: Key('share-to-${p.id}'),
                            leading: VideoThumbnail(
                              url: p.coverUrl,
                              width: 72,
                              borderRadius: 8,
                            ),
                            title: Text(
                              p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(l10n.videoCount(p.videoCount)),
                            onTap: () => Navigator.pop(context, p.id),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPlaylists extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.shareIntakeNoPlaylists),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.pop(context);
              unawaited(router.push(Routes.newPlaylist));
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.newPlaylist),
          ),
        ],
      ),
    );
  }
}

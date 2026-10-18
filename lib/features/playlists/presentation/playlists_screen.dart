import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/skeleton.dart';
import '../domain/playlist.dart';
import 'playlist_dialogs.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';
import 'widgets/label_chips.dart';
import 'widgets/video_thumbnail.dart';

/// Parent home: the library of playlists, drag to reorder.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await ref.read(myPlaylistsProvider.notifier).reorder(oldIndex, newIndex);
    } on Exception catch (e) {
      if (context.mounted) showPlaylistError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playlists = ref.watch(myPlaylistsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navPlaylists)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newPlaylist),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newPlaylist),
      ),
      body: playlists.when(
        skipLoadingOnReload: true,
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorView(
          message: l10n.playlistError(e),
          onRetry: () => ref.invalidate(myPlaylistsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.video_library_rounded,
              title: l10n.playlistsEmptyTitle,
              message: l10n.playlistsEmptyBody,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myPlaylistsProvider.future),
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) =>
                  unawaited(_reorder(context, ref, oldIndex, newIndex)),
              itemBuilder: (context, i) => _PlaylistCard(
                key: ValueKey(items[i].id),
                playlist: items[i],
                index: i,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  const _PlaylistCard({required this.playlist, required this.index, super.key});

  final Playlist playlist;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        child: Card(
          child: InkWell(
            onTap: () => context.push(Routes.playlist(playlist.id)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 2, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VideoThumbnail(
                    url: playlist.coverUrl,
                    width: 128,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.videoCount(playlist.videoCount)} · '
                            '${l10n.ageRangeLabel(playlist.ageRange)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                          if (playlist.labelIds.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            LabelChips(labelIds: playlist.labelIds),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      PopupMenuButton<_Action>(
                        tooltip: l10n.moreOptions,
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (a) => switch (a) {
                          _Action.edit => context.push(
                            Routes.editPlaylist(playlist.id),
                          ),
                          _Action.delete => confirmDeletePlaylist(
                            context,
                            ref,
                            playlist,
                          ),
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _Action.edit,
                            child: Text(l10n.editDetails),
                          ),
                          PopupMenuItem(
                            value: _Action.delete,
                            child: Text(l10n.deletePlaylist),
                          ),
                        ],
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Semantics(
                          label: l10n.dragToReorder,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Action { edit, delete }

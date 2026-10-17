import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/playlist.dart';
import 'add_video_sheet.dart';
import 'playlist_dialogs.dart';
import 'playlist_l10n.dart';
import 'playlist_providers.dart';
import 'widgets/label_chips.dart';
import 'widgets/video_thumbnail.dart';

/// One playlist: drag to reorder videos, swipe to remove, add by URL.
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({required this.playlistId, super.key});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = playlistDetailControllerProvider(playlistId);
    final detail = ref.watch(provider);
    final playlist = detail.value?.playlist;

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist?.title ?? ''),
        actions: [
          if (playlist != null)
            PopupMenuButton<_Action>(
              tooltip: l10n.moreOptions,
              onSelected: (a) async {
                switch (a) {
                  case _Action.edit:
                    await context.push(Routes.editPlaylist(playlistId));
                  case _Action.delete:
                    if (await confirmDeletePlaylist(context, ref, playlist) &&
                        context.mounted) {
                      context.pop();
                    }
                }
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
        ],
      ),
      floatingActionButton: detail.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => showAddVideoSheet(context, playlistId),
              icon: const Icon(Icons.add_link),
              label: Text(l10n.addVideo),
            )
          : null,
      body: detail.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: l10n.playlistError(e),
          onRetry: () => ref.invalidate(provider),
        ),
        data: (d) => _VideoList(detail: d),
      ),
    );
  }
}

enum _Action { edit, delete }

class _VideoList extends ConsumerWidget {
  const _VideoList({required this.detail});

  final PlaylistDetail detail;

  PlaylistDetailController _controller(WidgetRef ref) =>
      ref.read(playlistDetailControllerProvider(detail.playlist.id).notifier);

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    PlaylistVideo video,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = _controller(ref);
    try {
      final index = await controller.removeVideo(video);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.videoRemoved),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () => unawaited(
                controller.restoreVideo(video, index).catchError((Object e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.playlistError(e))),
                  );
                }),
              ),
            ),
          ),
        );
    } on Exception catch (e) {
      if (context.mounted) showPlaylistError(context, e);
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await _controller(ref).reorder(oldIndex, newIndex);
    } on Exception catch (e) {
      if (context.mounted) showPlaylistError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final videos = detail.videos;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(playlist: detail.playlist)),
        if (videos.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.add_link,
              title: l10n.playlistEmptyTitle,
              message: l10n.playlistEmptyBody,
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                l10n.reorderHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          SliverReorderableList(
            itemCount: videos.length,
            onReorderItem: (oldIndex, newIndex) =>
                unawaited(_reorder(context, ref, oldIndex, newIndex)),
            itemBuilder: (context, i) {
              final video = videos[i];
              return Dismissible(
                key: ValueKey(video.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: AlignmentDirectional.centerEnd,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                onDismissed: (_) => unawaited(_remove(context, ref, video)),
                child: _VideoTile(
                  video: video,
                  index: i,
                  onRemove: () => unawaited(_remove(context, ref, video)),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final description = playlist.description;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.videoCount(playlist.videoCount)} · '
            '${l10n.ageRangeLabel(playlist.ageRange)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description),
          ],
          if (playlist.labelIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            LabelChips(labelIds: playlist.labelIds),
          ],
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.video,
    required this.index,
    required this.onRemove,
  });

  final PlaylistVideo video;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.removeVideo): onRemove,
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              VideoThumbnail(
                url: video.thumbnailUrl,
                width: 112,
                borderRadius: 8,
                dimmed: !video.isAvailable,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (video.channelName != null)
                      Text(
                        video.channelName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (!video.isAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.videoUnavailable,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: l10n.dragToReorder,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

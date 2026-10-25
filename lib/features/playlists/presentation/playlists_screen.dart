import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/languages.dart';
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
import 'widgets/language_picker.dart';
import 'widgets/video_thumbnail.dart';

/// Parent home: the library of playlists, drag to reorder, filter by
/// language.
class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  LanguageFilter? _language;

  Future<void> _pickLanguage(List<Playlist> items) async {
    final pick = await showLanguageFilterPicker(
      context,
      current: _language,
      available: {for (final p in items) ...p.languages},
    );
    if (pick != null && mounted) setState(() => _language = pick.filter);
  }

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
  Widget build(BuildContext context) {
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
          final language = _language;
          final hasLanguages = items.any((p) => p.languages.isNotEmpty);
          // Reordering a filtered list would scramble the full order.
          final shown = language == null
              ? items
              : [
                  for (final p in items)
                    if (language.matches(p.languages)) p,
                ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasLanguages || language != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: LanguageFilterChip(
                    key: const Key('library-language-filter'),
                    filter: language,
                    onPressed: () => unawaited(_pickLanguage(items)),
                    onClear: () => setState(() => _language = null),
                  ),
                ),
              Expanded(
                child: shown.isEmpty
                    ? EmptyState(
                        icon: Icons.translate_rounded,
                        title: l10n.playlistsNoneInLanguageTitle,
                        message: l10n.playlistsNoneInLanguageBody,
                        action: TextButton(
                          onPressed: () => setState(() => _language = null),
                          child: Text(l10n.languageAny),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.refresh(myPlaylistsProvider.future),
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: shown.length,
                          buildDefaultDragHandles: false,
                          onReorderItem: (oldIndex, newIndex) => unawaited(
                            _reorder(context, ref, oldIndex, newIndex),
                          ),
                          itemBuilder: (context, i) => _PlaylistCard(
                            key: ValueKey(shown[i].id),
                            playlist: shown[i],
                            index: i,
                            reorderable: language == null,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.index,
    this.reorderable = true,
    super.key,
  });

  final Playlist playlist;
  final int index;
  final bool reorderable;

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
                            [
                              l10n.videoCount(playlist.videoCount),
                              l10n.ageRangeLabel(playlist.ageRange),
                              if (playlist.languages.isNotEmpty)
                                languagesLabel(playlist.languages),
                            ].join(' · '),
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
                      if (reorderable)
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

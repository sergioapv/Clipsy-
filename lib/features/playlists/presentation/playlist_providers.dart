import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/http_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/oembed_client.dart';
import '../data/playlist_repository.dart';
import '../data/webview_in_app_browser.dart';
import '../data/youtube_playlist_repository.dart';
import '../domain/in_app_browser.dart';
import '../domain/label.dart';
import '../domain/playlist.dart';
import '../domain/video_metadata.dart';
import '../domain/youtube_url_parser.dart';

part 'playlist_providers.g.dart';

@Riverpod(keepAlive: true)
PlaylistRepository playlistRepository(Ref ref) =>
    SupabasePlaylistRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
LabelRepository labelRepository(Ref ref) =>
    SupabaseLabelRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
VideoLookupRepository videoLookupRepository(Ref ref) =>
    VideoLookupRepository(OEmbedClient(ref.watch(httpClientProvider)));

/// The parent-mode YouTube browser; disposed with its screen.
@riverpod
InAppBrowser inAppBrowser(Ref ref) {
  final browser = WebViewInAppBrowser();
  ref.onDispose(browser.dispose);
  return browser;
}

/// Playlist import; holds a hidden player, so it lives with the import sheet.
@riverpod
YouTubePlaylistRepository youTubePlaylistRepository(Ref ref) {
  final ids = PlayerPlaylistIdsSource();
  ref.onDispose(ids.dispose);
  return PlaylistImporter(
    ids: ids,
    oembed: OEmbedClient(ref.watch(httpClientProvider)),
    maxVideos: PlaylistDraft.maxVideos,
  );
}

/// All labels, in display order. Rarely changes, so kept for the session.
@Riverpod(keepAlive: true)
Future<List<Label>> labels(Ref ref) =>
    ref.watch(labelRepositoryProvider).fetchAll();

/// The parent's library.
@riverpod
class MyPlaylists extends _$MyPlaylists {
  @override
  Future<List<Playlist>> build() =>
      ref.watch(playlistRepositoryProvider).fetchMine();

  Future<String> create(PlaylistDraft draft) async {
    final id = await ref.read(playlistRepositoryProvider).create(draft);
    ref.invalidateSelf();
    return id;
  }

  Future<void> delete(String id) async {
    final previous = state.value;
    if (previous != null) {
      state = AsyncData([...previous.where((p) => p.id != id)]);
    }
    try {
      await ref.read(playlistRepositoryProvider).delete(id);
    } catch (_) {
      if (ref.mounted) ref.invalidateSelf();
      rethrow;
    }
  }

  /// Moves a playlist, with [newIndex] as reported by `ReorderableListView`
  /// (already adjusted for the removed item).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.value;
    if (current == null || oldIndex == newIndex) return;
    final updated = [...current];
    updated.insert(newIndex, updated.removeAt(oldIndex));
    state = AsyncData(updated);
    try {
      await ref.read(playlistRepositoryProvider).reorderMine([
        for (final p in updated) p.id,
      ]);
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
  }
}

/// One playlist with its videos, plus the edits made on its screen.
@riverpod
class PlaylistDetailController extends _$PlaylistDetailController {
  @override
  Future<PlaylistDetail> build(String playlistId) =>
      ref.watch(playlistRepositoryProvider).fetchDetail(playlistId);

  PlaylistRepository get _repo => ref.read(playlistRepositoryProvider);

  /// Library cards show counts and covers, so refresh them after edits.
  void _libraryChanged() => ref.invalidate(myPlaylistsProvider);

  bool contains(String youtubeVideoId) =>
      state.value?.videos.any((v) => v.youtubeVideoId == youtubeVideoId) ??
      false;

  int _nextPosition(PlaylistDetail d) => d.videos.isEmpty
      ? 0
      : d.videos.map((v) => v.position).reduce((a, b) => a > b ? a : b) + 1;

  /// How many more videos this playlist can hold.
  int get remainingCapacity =>
      PlaylistDraft.maxVideos - (state.value?.videos.length ?? 0);

  Set<String> get youtubeIds => {
    for (final v in state.value?.videos ?? const <PlaylistVideo>[])
      v.youtubeVideoId,
  };

  /// Adds [videos] in one request, skipping ones already in the playlist.
  /// Returns how many were added.
  Future<int> addMany(List<VideoMetadata> videos) async {
    final current = state.requireValue;
    final existing = youtubeIds;
    final fresh = <VideoMetadata>[
      for (final v in videos)
        if (existing.add(v.videoId)) v,
    ];
    if (fresh.isEmpty) return 0;
    final added = await _repo.addVideos(
      playlistId,
      fresh,
      startPosition: _nextPosition(current),
    );
    _libraryChanged();
    if (ref.mounted) {
      final latest = state.requireValue;
      state = AsyncData(latest.copyWith(videos: [...latest.videos, ...added]));
    }
    return added.length;
  }

  Future<void> addVideo(VideoMetadata video) async {
    final current = state.requireValue;
    final position = _nextPosition(current);
    final added = await _repo.addVideo(playlistId, video, position: position);
    _libraryChanged();
    if (!ref.mounted) return;
    final latest = state.requireValue;
    state = AsyncData(latest.copyWith(videos: [...latest.videos, added]));
  }

  /// Optimistically removes [video]; returns its index for [restoreVideo].
  Future<int> removeVideo(PlaylistVideo video) async {
    final current = state.requireValue;
    final index = current.videos.indexWhere((v) => v.id == video.id);
    if (index < 0) return -1;
    state = AsyncData(
      current.copyWith(videos: [...current.videos]..removeAt(index)),
    );
    try {
      await _repo.removeVideo(video.id);
      _libraryChanged();
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
    return index;
  }

  /// Undo for [removeVideo]: adds the video back at [index].
  Future<void> restoreVideo(PlaylistVideo video, int index) async {
    await addVideo(
      VideoMetadata(
        videoId: video.youtubeVideoId,
        title: video.title,
        channelName: video.channelName,
        thumbnailUrl:
            video.thumbnailUrl ??
            YouTubeUrlParser.thumbnailUrl(video.youtubeVideoId),
        durationSeconds: video.durationSeconds,
      ),
    );
    if (!ref.mounted) return;
    final videos = state.requireValue.videos;
    final restoredAt = videos.length - 1;
    final target = index.clamp(0, restoredAt);
    if (target != restoredAt) await reorder(restoredAt, target);
  }

  /// Moves a video, with [newIndex] already adjusted for the removed item.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.requireValue;
    if (oldIndex == newIndex) return;
    final videos = [...current.videos];
    videos.insert(newIndex, videos.removeAt(oldIndex));
    state = AsyncData(current.copyWith(videos: videos));
    try {
      await _repo.reorderVideos(playlistId, [for (final v in videos) v.id]);
      _libraryChanged();
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> updateDetails(PlaylistDraft draft) async {
    await _repo.update(playlistId, draft);
    _libraryChanged();
    if (!ref.mounted) return;
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        playlist: current.playlist.copyWith(
          title: draft.trimmedTitle,
          description: draft.trimmedDescription ?? '',
          ageRange: draft.ageRange,
          labelIds: draft.labelIds.toSet().toList(),
        ),
      ),
    );
  }
}

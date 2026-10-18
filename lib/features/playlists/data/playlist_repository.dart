import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/label.dart';
import '../domain/playlist.dart';
import '../domain/playlist_exception.dart';
import '../domain/video_metadata.dart';

/// The signed-in parent's playlists. All failures surface as
/// [PlaylistException].
abstract interface class PlaylistRepository {
  /// The caller's own playlists, in their chosen order.
  Future<List<Playlist>> fetchMine();
  Future<PlaylistDetail> fetchDetail(String id);

  /// Creates a private playlist and returns its id.
  Future<String> create(PlaylistDraft draft);
  Future<void> update(String id, PlaylistDraft draft);
  Future<void> delete(String id);
  Future<void> reorderMine(List<String> playlistIds);

  Future<PlaylistVideo> addVideo(
    String playlistId,
    VideoMetadata video, {
    required int position,
  });

  /// Adds several videos in one request, positioned from [startPosition].
  Future<List<PlaylistVideo>> addVideos(
    String playlistId,
    List<VideoMetadata> videos, {
    required int startPosition,
  });
  Future<void> removeVideo(String videoId);
  Future<void> reorderVideos(String playlistId, List<String> videoIds);

  /// Stores a video's length the first time the player learns it.
  Future<void> recordDuration(String videoId, int seconds);
}

abstract interface class LabelRepository {
  Future<List<Label>> fetchAll();
}

class SupabasePlaylistRepository implements PlaylistRepository {
  SupabasePlaylistRepository(this._client, {String? Function()? currentUserId})
    : _currentUserId = currentUserId ?? (() => _client.auth.currentUser?.id);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  static const _summarySelect =
      '*, playlist_labels(label_id), playlist_videos(count)';
  static const _detailSelect =
      '*, playlist_labels(label_id), playlist_videos(*)';

  String get _uid {
    final id = _currentUserId();
    if (id == null) throw const PlaylistException(PlaylistError.notFound);
    return id;
  }

  @override
  Future<List<Playlist>> fetchMine() => guardPlaylistCall(() async {
    // RLS also returns other parents' public playlists, so filter by owner.
    final rows = await _client
        .from('playlists')
        .select(_summarySelect)
        .eq('owner_id', _uid)
        .order('sort_index', ascending: true)
        .order('created_at', ascending: false);
    return [for (final r in rows) Playlist.fromJson(r)];
  });

  @override
  Future<PlaylistDetail> fetchDetail(String id) => guardPlaylistCall(() async {
    final row = await _client
        .from('playlists')
        .select(_detailSelect)
        .eq('id', id)
        .order('position', ascending: true, referencedTable: 'playlist_videos')
        .maybeSingle();
    if (row == null) throw const PlaylistException(PlaylistError.notFound);
    return PlaylistDetail.fromJson(row);
  });

  @override
  Future<String> create(PlaylistDraft draft) => guardPlaylistCall(() async {
    final row = await _client
        .from('playlists')
        .insert(_fields(draft))
        .select('id')
        .single();
    final id = row['id']! as String;
    if (draft.labelIds.isNotEmpty) await _setLabels(id, draft.labelIds);
    return id;
  });

  @override
  Future<void> update(String id, PlaylistDraft draft) =>
      guardPlaylistCall(() async {
        // Each call commits on its own, and the database checks a public
        // playlist has labels at every commit. So when publishing, set the
        // labels first; otherwise unpublish first, then change the labels.
        if (draft.isPublic) {
          await _setLabels(id, draft.labelIds);
          await _client.from('playlists').update(_fields(draft)).eq('id', id);
        } else {
          await _client.from('playlists').update(_fields(draft)).eq('id', id);
          await _setLabels(id, draft.labelIds);
        }
      });

  @override
  Future<void> delete(String id) =>
      guardPlaylistCall(() => _client.from('playlists').delete().eq('id', id));

  @override
  Future<void> reorderMine(List<String> playlistIds) => guardPlaylistCall(
    () => _client.rpc<void>(
      'reorder_my_playlists',
      params: {'p_playlist_ids': playlistIds},
    ),
  );

  @override
  Future<PlaylistVideo> addVideo(
    String playlistId,
    VideoMetadata video, {
    required int position,
  }) => guardPlaylistCall(() async {
    final row = await _client
        .from('playlist_videos')
        .insert({
          'playlist_id': playlistId,
          'youtube_video_id': video.videoId,
          'title': video.title,
          'channel_name': video.channelName,
          'thumbnail_url': video.thumbnailUrl,
          'duration_seconds': video.durationSeconds,
          'position': position,
        })
        .select()
        .single();
    return PlaylistVideo.fromJson(row);
  });

  @override
  Future<List<PlaylistVideo>> addVideos(
    String playlistId,
    List<VideoMetadata> videos, {
    required int startPosition,
  }) => guardPlaylistCall(() async {
    if (videos.isEmpty) return const <PlaylistVideo>[];
    final rows = await _client.from('playlist_videos').insert([
      for (final (i, v) in videos.indexed)
        {
          'playlist_id': playlistId,
          'youtube_video_id': v.videoId,
          'title': v.title,
          'channel_name': v.channelName,
          'thumbnail_url': v.thumbnailUrl,
          'duration_seconds': v.durationSeconds,
          'position': startPosition + i,
        },
    ]).select();
    return [for (final r in rows) PlaylistVideo.fromJson(r)];
  });

  @override
  Future<void> removeVideo(String videoId) => guardPlaylistCall(
    () => _client.from('playlist_videos').delete().eq('id', videoId),
  );

  @override
  Future<void> reorderVideos(String playlistId, List<String> videoIds) =>
      guardPlaylistCall(
        () => _client.rpc<void>(
          'reorder_playlist_videos',
          params: {'p_playlist_id': playlistId, 'p_video_ids': videoIds},
        ),
      );

  @override
  Future<void> recordDuration(String videoId, int seconds) => guardPlaylistCall(
    () => _client
        .from('playlist_videos')
        .update({'duration_seconds': seconds})
        .eq('id', videoId)
        .isFilter('duration_seconds', null),
  );

  Future<void> _setLabels(String id, List<int> labelIds) => _client.rpc<void>(
    'set_playlist_labels',
    params: {'p_playlist_id': id, 'p_label_ids': labelIds.toSet().toList()},
  );

  static Map<String, Object?> _fields(PlaylistDraft d) => {
    'title': d.trimmedTitle,
    'description': d.trimmedDescription,
    'age_min': d.ageRange.min,
    'age_max': d.ageRange.max,
    'visibility': d.visibility.name,
  };
}

class SupabaseLabelRepository implements LabelRepository {
  const SupabaseLabelRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Label>> fetchAll() => guardPlaylistCall(() async {
    final rows = await _client
        .from('labels')
        .select('id, slug, name')
        .order('sort_order', ascending: true);
    return [for (final r in rows) Label.fromJson(r)];
  });
}

/// Maps transport and database errors to [PlaylistException].
Future<T> guardPlaylistCall<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on PlaylistException {
    rethrow;
  } on PostgrestException catch (e) {
    throw PlaylistException(mapPostgrestError(e), e);
  } on SocketException catch (e) {
    throw PlaylistException(PlaylistError.network, e);
  } on http.ClientException catch (e) {
    throw PlaylistException(PlaylistError.network, e);
  } on TimeoutException catch (e) {
    throw PlaylistException(PlaylistError.network, e);
  }
}

/// Database error → domain error. The migrations raise stable message keys.
PlaylistError mapPostgrestError(PostgrestException e) {
  final message = e.message;
  if (e.code == '23505' && message.contains('playlist_videos_unique_video')) {
    return PlaylistError.duplicateVideo;
  }
  if (message.contains('too_many_videos')) return PlaylistError.tooManyVideos;
  if (message.contains('too_many_labels')) return PlaylistError.tooManyLabels;
  if (message.contains('public_playlist_needs_label')) {
    return PlaylistError.needsLabel;
  }
  if (message.contains('public_playlist_needs_video')) {
    return PlaylistError.needsVideo;
  }
  if (e.code == '23505' && message.contains('reports_one_per_parent')) {
    return PlaylistError.alreadyReported;
  }
  if (message.contains('cannot_rate_own_playlist') ||
      (e.code == '42501' && message.contains('row-level security'))) {
    // RLS only refuses ratings and reports on the caller's own (or a
    // hidden) playlist.
    return PlaylistError.ownPlaylist;
  }
  if (message.contains('playlist_not_found') || e.code == 'PGRST116') {
    return PlaylistError.notFound;
  }
  return PlaylistError.unknown;
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../playlists/data/playlist_repository.dart';
import '../../playlists/domain/playlist.dart';
import '../../playlists/domain/playlist_exception.dart';
import '../domain/community_playlist.dart';

/// The community library: published playlists, ratings, reports and forks.
/// Errors are [PlaylistException]s.
abstract interface class CommunityRepository {
  /// One page of published playlists matching [query].
  Future<List<CommunityPlaylist>> browse(
    CommunityQuery query, {
    int offset = 0,
    int limit = pageSize,
  });

  Future<CommunityPlaylistDetail> fetchDetail(String id);

  /// Copies a community playlist into the parent's library (private, with a
  /// reference to the original). Returns the new playlist's id.
  Future<String> fork(String id);

  /// Rates (or re-rates) a playlist, 1–5 stars.
  Future<void> rate(String id, int stars);

  Future<void> report(String id, ReportReason reason, {String? details});

  static const pageSize = 20;
}

class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository(this._client, {String? Function()? currentUserId})
    : _currentUserId = currentUserId ?? (() => _client.auth.currentUser?.id);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  String get _uid {
    final id = _currentUserId();
    if (id == null) throw const PlaylistException(PlaylistError.notFound);
    return id;
  }

  @override
  Future<List<CommunityPlaylist>> browse(
    CommunityQuery query, {
    int offset = 0,
    int limit = CommunityRepository.pageSize,
  }) => guardPlaylistCall(() async {
    var filter = _client.from('community_playlists').select();
    final label = query.labelSlug;
    if (label != null) filter = filter.contains('label_slugs', [label]);
    final age = query.ageRange;
    if (age != null) {
      // Overlapping ranges.
      filter = filter.lte('age_min', age.max).gte('age_max', age.min);
    }
    final search = query.trimmedSearch;
    if (search.isNotEmpty) {
      filter = filter.ilike('title', '%${escapeLike(search)}%');
    }
    final ordered = switch (query.sort) {
      CommunitySort.topRated =>
        filter
            .order('rating_avg', ascending: false, nullsFirst: false)
            .order('rating_count', ascending: false)
            .order('published_at', ascending: false),
      CommunitySort.newest => filter.order('published_at', ascending: false),
    };
    final rows = await ordered.range(offset, offset + limit - 1);
    return [for (final r in rows) CommunityPlaylist.fromJson(r)];
  });

  @override
  Future<CommunityPlaylistDetail> fetchDetail(String id) => guardPlaylistCall(
    () async {
      final uid = _uid;
      final (row, videos, rating) = await (
        _client.from('community_playlists').select().eq('id', id).maybeSingle(),
        _client
            .from('playlist_videos')
            .select()
            .eq('playlist_id', id)
            .eq('is_available', true)
            .order('position', ascending: true),
        _client
            .from('ratings')
            .select('stars')
            .eq('playlist_id', id)
            .eq('user_id', uid)
            .maybeSingle(),
      ).wait;
      if (row == null) throw const PlaylistException(PlaylistError.notFound);
      final playlist = CommunityPlaylist.fromJson(row);
      return CommunityPlaylistDetail(
        playlist: playlist,
        videos: [for (final v in videos) PlaylistVideo.fromJson(v)],
        isMine: playlist.ownerId == uid,
        myRating: (rating?['stars'] as num?)?.toInt(),
      );
    },
  );

  @override
  Future<String> fork(String id) => guardPlaylistCall(
    () => _client.rpc<String>('fork_playlist', params: {'p_source_id': id}),
  );

  @override
  Future<void> rate(String id, int stars) => guardPlaylistCall(
    () => _client.rpc<void>(
      'rate_playlist',
      params: {'p_playlist_id': id, 'p_stars': stars.clamp(1, 5)},
    ),
  );

  @override
  Future<void> report(String id, ReportReason reason, {String? details}) =>
      guardPlaylistCall(() async {
        final d = details?.trim();
        // Reports aren't readable by parents, so don't ask for the row back.
        await _client.from('reports').insert({
          'playlist_id': id,
          'reason': reason.dbValue,
          if (d != null && d.isNotEmpty) 'details': d,
        });
      });
}

/// Escapes LIKE wildcards so a search for "100%" matches literally.
String escapeLike(String s) =>
    s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');

import 'dart:convert';

import 'package:clipsy/features/community/data/community_repository.dart';
import 'package:clipsy/features/community/data/profile_repository.dart';
import 'package:clipsy/features/community/domain/community_playlist.dart';
import 'package:clipsy/features/playlists/domain/playlist.dart';
import 'package:clipsy/features/playlists/domain/playlist_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records PostgREST requests and replies with canned responses.
class _Backend {
  final requests = <http.Request>[];
  http.Response Function(http.Request req) reply = (_) =>
      http.Response('[]', 200);

  late final client = SupabaseClient(
    'https://test.supabase.co',
    'anon-key',
    httpClient: MockClient((req) async {
      requests.add(req);
      final r = reply(req);
      return http.Response.bytes(
        r.bodyBytes,
        r.statusCode,
        headers: r.headers,
        request: req,
      );
    }),
  );

  http.Request get last => requests.last;
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Matcher _failsWith(PlaylistError error) =>
    throwsA(isA<PlaylistException>().having((e) => e.error, 'error', error));

Map<String, Object?> _row(String id, {String owner = 'u2'}) => {
  'id': id,
  'owner_id': owner,
  'title': 'Ocean animals',
  'description': 'Whales and friends',
  'cover_url': 'https://i.ytimg.com/vi/aaaaaaaaaaa/hqdefault.jpg',
  'age_min': 5,
  'age_max': 7,
  'rating_avg': 4.5,
  'rating_count': 12,
  'published_at': '2026-10-01T10:00:00Z',
  'forked_from': null,
  'author_name': 'Marta',
  'video_count': 3,
  'total_duration_seconds': 610,
  'label_slugs': ['animals', 'nature'],
};

void main() {
  late _Backend backend;
  late SupabaseCommunityRepository repo;

  setUp(() {
    backend = _Backend();
    repo = SupabaseCommunityRepository(
      backend.client,
      currentUserId: () => 'u1',
    );
  });

  test('top rated: filters, search and ordering', () async {
    backend.reply = (_) => _json([_row('c1')]);
    final result = await repo.browse(
      const CommunityQuery(
        labelSlug: 'animals',
        ageRange: AgeRange.young,
        search: ' 50%_off ',
      ),
      offset: 20,
    );

    final q = backend.last.url.queryParameters;
    expect(backend.last.url.path, '/rest/v1/community_playlists');
    expect(q['label_slugs'], 'cs.{"animals"}');
    expect(q['age_min'], 'lte.7');
    expect(q['age_max'], 'gte.5');
    expect(q['title'], r'ilike.%50\%\_off%');
    expect(
      q['order'],
      'rating_avg.desc.nullslast,rating_count.desc.nullslast,'
      'published_at.desc.nullslast',
    );
    expect(q['offset'], '20');
    expect(q['limit'], '20');

    final p = result.single;
    expect(p.title, 'Ocean animals');
    expect(p.authorName, 'Marta');
    expect(p.ageRange, AgeRange.young);
    expect(p.ratingAvg, 4.5);
    expect(p.ratingCount, 12);
    expect(p.totalDurationSeconds, 610);
    expect(p.labelSlugs, ['animals', 'nature']);
  });

  test('new: newest first, no filters', () async {
    await repo.browse(const CommunityQuery(sort: CommunitySort.newest));
    final q = backend.last.url.queryParameters;
    expect(q['order'], 'published_at.desc.nullslast');
    expect(q.containsKey('label_slugs'), isFalse);
    expect(q.containsKey('title'), isFalse);
  });

  test('detail loads videos and my rating', () async {
    backend.reply = (req) => switch (req.url.path) {
      '/rest/v1/community_playlists' => _json(_row('c1')),
      '/rest/v1/playlist_videos' => _json([
        {
          'id': 'v1',
          'playlist_id': 'c1',
          'youtube_video_id': 'aaaaaaaaaaa',
          'title': 'Whales',
          'position': 0,
        },
      ]),
      '/rest/v1/ratings' => _json({'stars': 4}),
      _ => http.Response('', 404),
    };
    final d = await repo.fetchDetail('c1');
    expect(d.playlist.id, 'c1');
    expect(d.videos.single.title, 'Whales');
    expect(d.myRating, 4);
    expect(d.isMine, isFalse);

    final videos = backend.requests.firstWhere(
      (r) => r.url.path == '/rest/v1/playlist_videos',
    );
    expect(videos.url.queryParameters['is_available'], 'eq.true');
    final rating = backend.requests.firstWhere(
      (r) => r.url.path == '/rest/v1/ratings',
    );
    expect(rating.url.queryParameters['user_id'], 'eq.u1');
  });

  test('detail of a playlist that is no longer shared', () async {
    backend.reply = (_) => _json([]);
    await expectLater(
      repo.fetchDetail('gone'),
      _failsWith(PlaylistError.notFound),
    );
  });

  test('fork and rate go through the database functions', () async {
    backend.reply = (req) => req.url.path.endsWith('fork_playlist')
        ? _json('new-id')
        : http.Response('', 204);
    expect(await repo.fork('c1'), 'new-id');
    expect(jsonDecode(backend.last.body), {'p_source_id': 'c1'});

    await repo.rate('c1', 4);
    expect(backend.last.url.path, '/rest/v1/rpc/rate_playlist');
    expect(jsonDecode(backend.last.body), {
      'p_playlist_id': 'c1',
      'p_stars': 4,
    });
  });

  test('rating your own playlist is refused', () async {
    backend.reply = (_) =>
        _json({'code': '23514', 'message': 'cannot_rate_own_playlist'}, 400);
    await expectLater(
      repo.rate('c1', 5),
      _failsWith(PlaylistError.ownPlaylist),
    );
  });

  test('report inserts without reading back; duplicates are flagged', () async {
    backend.reply = (_) => http.Response('', 201);
    await repo.report('c1', ReportReason.notForKids, details: '  scary  ');
    expect(backend.last.method, 'POST');
    expect(backend.last.url.path, '/rest/v1/reports');
    expect(backend.last.headers['Prefer'], isNot(contains('representation')));
    expect(jsonDecode(backend.last.body), {
      'playlist_id': 'c1',
      'reason': 'not_for_kids',
      'details': 'scary',
    });

    backend.reply = (_) => _json({
      'code': '23505',
      'message': 'duplicate key value violates unique constraint "reports_one_per_parent"',
    }, 409);
    await expectLater(
      repo.report('c1', ReportReason.spam),
      _failsWith(PlaylistError.alreadyReported),
    );
  });

  test('profile name is read and updated for the current parent', () async {
    final profiles = SupabaseProfileRepository(
      backend.client,
      currentUserId: () => 'u1',
    );
    backend.reply = (_) => _json({'display_name': 'Marta'});
    expect(await profiles.fetchDisplayName(), 'Marta');
    expect(backend.last.url.queryParameters['id'], 'eq.u1');

    backend.reply = (_) => http.Response('', 204);
    await profiles.updateDisplayName('  Ana  ');
    expect(backend.last.method, 'PATCH');
    expect(jsonDecode(backend.last.body), {'display_name': 'Ana'});
  });
}

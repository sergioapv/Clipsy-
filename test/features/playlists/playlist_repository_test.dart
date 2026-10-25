import 'dart:convert';
import 'dart:io';

import 'package:clipsy/features/playlists/data/playlist_repository.dart';
import 'package:clipsy/features/playlists/domain/playlist.dart';
import 'package:clipsy/features/playlists/domain/playlist_exception.dart';
import 'package:clipsy/features/playlists/domain/video_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records PostgREST requests and replies with canned responses, so the
/// repository is tested against the real Supabase client.
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
      // postgrest reads response.request, which canned responses lack.
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

void main() {
  late _Backend backend;
  late SupabasePlaylistRepository repo;

  setUp(() {
    backend = _Backend();
    repo = SupabasePlaylistRepository(
      backend.client,
      currentUserId: () => 'user-1',
    );
  });

  test('fetchMine filters by owner, orders, and parses counts', () async {
    backend.reply = (_) => _json([
      {
        'id': 'p1',
        'owner_id': 'user-1',
        'title': 'Space',
        'age_min': 5,
        'age_max': 7,
        'visibility': 'private',
        'cover_url': 'https://i.ytimg.com/vi/x/hqdefault.jpg',
        'sort_index': 0,
        'playlist_labels': [
          {'label_id': 3},
          {'label_id': 14},
        ],
        'playlist_videos': [
          {'count': 4},
        ],
      },
    ]);

    final result = await repo.fetchMine();

    final q = backend.last.url.queryParameters;
    expect(backend.last.method, 'GET');
    expect(backend.last.url.path, '/rest/v1/playlists');
    expect(q['owner_id'], 'eq.user-1');
    expect(q['order'], 'sort_index.asc.nullslast,created_at.desc.nullslast');
    expect(q['select'], contains('playlist_videos(count)'));
    expect(result.single.title, 'Space');
    expect(result.single.videoCount, 4);
    expect(result.single.labelIds, [3, 14]);
    expect(result.single.ageRange, AgeRange.young);
  });

  test('fetchDetail sorts videos and reports missing playlists', () async {
    backend.reply = (_) => _json({
      'id': 'p1',
      'owner_id': 'user-1',
      'title': 'Space',
      'age_min': 2,
      'age_max': 4,
      'playlist_labels': <Object>[],
      'playlist_videos': [
        {
          'id': 'v2',
          'playlist_id': 'p1',
          'youtube_video_id': 'bbbbbbbbbbb',
          'title': 'Second',
          'position': 1,
        },
        {
          'id': 'v1',
          'playlist_id': 'p1',
          'youtube_video_id': 'aaaaaaaaaaa',
          'title': 'First',
          'position': 0,
          'is_available': false,
        },
      ],
    });
    final detail = await repo.fetchDetail('p1');
    expect(backend.last.url.queryParameters['id'], 'eq.p1');
    expect(
      backend.last.url.queryParameters['playlist_videos.order'],
      'position.asc.nullslast',
    );
    expect([for (final v in detail.videos) v.id], ['v1', 'v2']);
    expect(detail.videos.first.isAvailable, isFalse);
    expect(detail.playlist.videoCount, 2);

    backend.reply = (_) => http.Response('', 200);
    await expectLater(
      repo.fetchDetail('gone'),
      _failsWith(PlaylistError.notFound),
    );
  });

  test('publishing sets labels before making the playlist public', () async {
    backend.reply = (_) => http.Response('', 204);
    await repo.update(
      'p1',
      const PlaylistDraft(
        title: 'Birds',
        labelIds: [3],
        visibility: PlaylistVisibility.public,
      ),
    );
    expect(backend.requests.map((r) => r.url.path), [
      '/rest/v1/rpc/set_playlist_labels',
      '/rest/v1/playlists',
    ]);
    expect((jsonDecode(backend.last.body) as Map)['visibility'], 'public');
  });

  test(
    'unpublishing makes the playlist private before changing labels',
    () async {
      backend.reply = (_) => http.Response('', 204);
      await repo.update('p1', const PlaylistDraft(title: 'Birds'));
      expect(backend.requests.map((r) => r.url.path), [
        '/rest/v1/playlists',
        '/rest/v1/rpc/set_playlist_labels',
      ]);
    },
  );

  test('database checks on shared playlists map to errors', () async {
    backend.reply = (_) =>
        _json({'code': '23514', 'message': 'public_playlist_needs_label'}, 400);
    await expectLater(
      repo.update(
        'p1',
        const PlaylistDraft(
          title: 'Birds',
          labelIds: [3],
          visibility: PlaylistVisibility.public,
        ),
      ),
      _failsWith(PlaylistError.needsLabel),
    );
    backend.reply = (_) =>
        _json({'code': '23514', 'message': 'public_playlist_needs_video'}, 400);
    await expectLater(
      repo.removeVideo('v1'),
      _failsWith(PlaylistError.needsVideo),
    );
  });

  test('create inserts trimmed fields, then sets labels', () async {
    backend.reply = (req) => req.url.path.endsWith('/playlists')
        ? _json({'id': 'new-id'}, 201)
        : http.Response('', 204);

    final id = await repo.create(
      const PlaylistDraft(
        title: '  Dinosaurs ',
        description: '   ',
        ageRange: AgeRange.older,
        labelIds: [1, 2, 2],
      ),
    );

    expect(id, 'new-id');
    final insert = backend.requests.first;
    expect(insert.method, 'POST');
    expect(jsonDecode(insert.body), {
      'title': 'Dinosaurs',
      'description': null,
      'age_min': 8,
      'age_max': 12,
      'languages': <String>[],
      'visibility': 'private',
    });
    final rpc = backend.requests.last;
    expect(rpc.url.path, '/rest/v1/rpc/set_playlist_labels');
    expect(jsonDecode(rpc.body), {
      'p_playlist_id': 'new-id',
      'p_label_ids': [1, 2],
    });
  });

  test('create without labels skips the label call', () async {
    backend.reply = (_) => _json({'id': 'new-id'}, 201);
    await repo.create(const PlaylistDraft(title: 'x'));
    expect(backend.requests, hasLength(1));
  });

  test('update patches fields and always replaces labels', () async {
    backend.reply = (_) => http.Response('', 204);
    await repo.update('p1', const PlaylistDraft(title: 'New'));
    expect(backend.requests.first.method, 'PATCH');
    expect(backend.requests.first.url.queryParameters['id'], 'eq.p1');
    final labels =
        jsonDecode(backend.requests.last.body) as Map<String, Object?>;
    expect(labels['p_label_ids'], isEmpty);
  });

  test('addVideo sends metadata and position', () async {
    backend.reply = (_) => _json({
      'id': 'v9',
      'playlist_id': 'p1',
      'youtube_video_id': 'dQw4w9WgXcQ',
      'title': 'Song',
      'position': 3,
    }, 201);
    final video = await repo.addVideo(
      'p1',
      const VideoMetadata(
        videoId: 'dQw4w9WgXcQ',
        title: 'Song',
        channelName: 'Ch',
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      ),
      position: 3,
    );
    expect(video.id, 'v9');
    final body = jsonDecode(backend.last.body) as Map<String, Object?>;
    expect(body['playlist_id'], 'p1');
    expect(body['youtube_video_id'], 'dQw4w9WgXcQ');
    expect(body['position'], 3);
    expect(body.containsKey('is_available'), isFalse);
  });

  test('reorder calls the RPCs with ids in order', () async {
    backend.reply = (_) => http.Response('', 204);
    await repo.reorderVideos('p1', ['b', 'a']);
    expect(backend.last.url.path, '/rest/v1/rpc/reorder_playlist_videos');
    expect(jsonDecode(backend.last.body), {
      'p_playlist_id': 'p1',
      'p_video_ids': ['b', 'a'],
    });
    await repo.reorderMine(['p2', 'p1']);
    expect(backend.last.url.path, '/rest/v1/rpc/reorder_my_playlists');
  });

  test('delete and removeVideo target one row', () async {
    backend.reply = (_) => http.Response('', 204);
    await repo.delete('p1');
    expect(backend.last.method, 'DELETE');
    expect(backend.last.url.queryParameters['id'], 'eq.p1');
    await repo.removeVideo('v1');
    expect(backend.last.url.path, '/rest/v1/playlist_videos');
  });

  group('error mapping', () {
    const meta = VideoMetadata(
      videoId: 'dQw4w9WgXcQ',
      title: 'Song',
      thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    );

    test('duplicate video', () async {
      backend.reply = (_) => _json({
        'code': '23505',
        'message': 'duplicate key value violates unique constraint "playlist_videos_unique_video"',
      }, 409);
      await expectLater(
        repo.addVideo('p1', meta, position: 0),
        _failsWith(PlaylistError.duplicateVideo),
      );
    });

    test('too many videos / labels from triggers', () async {
      backend.reply = (_) =>
          _json({'code': '23514', 'message': 'too_many_videos'}, 400);
      await expectLater(
        repo.addVideo('p1', meta, position: 0),
        _failsWith(PlaylistError.tooManyVideos),
      );
      backend.reply = (_) =>
          _json({'code': '23514', 'message': 'too_many_labels'}, 400);
      await expectLater(
        repo.update('p1', const PlaylistDraft(title: 'x')),
        _failsWith(PlaylistError.tooManyLabels),
      );
    });

    test('network failures', () async {
      final offline = SupabasePlaylistRepository(
        SupabaseClient(
          'https://test.supabase.co',
          'anon-key',
          httpClient: MockClient((_) => throw const SocketException('offline')),
        ),
        currentUserId: () => 'user-1',
      );
      await expectLater(offline.fetchMine(), _failsWith(PlaylistError.network));
    });

    test('anything else is unknown', () async {
      backend.reply = (_) => _json({'code': 'XX000', 'message': 'boom'}, 500);
      await expectLater(repo.fetchMine(), _failsWith(PlaylistError.unknown));
    });
  });

  test('labels are fetched in display order', () async {
    backend.reply = (_) => _json([
      {'id': 1, 'slug': 'science', 'name': 'Science'},
    ]);
    final labels = await SupabaseLabelRepository(backend.client).fetchAll();
    expect(
      backend.last.url.queryParameters['order'],
      'sort_order.asc.nullslast',
    );
    expect(labels.single.slug, 'science');
  });
}

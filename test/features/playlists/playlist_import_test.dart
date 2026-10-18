import 'dart:convert';

import 'package:clipsy/features/auth/domain/app_user.dart';
import 'package:clipsy/features/playlists/data/youtube_playlist_repository.dart';
import 'package:clipsy/features/playlists/domain/imported_playlist.dart';
import 'package:clipsy/features/playlists/domain/youtube_url_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_playlists.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const _parent = AppUser(id: 'u1', email: 'parent@example.com');
const _list = 'PLabcdefghijklmnop';

ImportedVideo _v(String id, {bool playable = true}) => ImportedVideo(
  videoId: id,
  title: 'Video $id',
  playable: playable,
  durationSeconds: 90,
);

ImportedPlaylist _playlist(
  List<ImportedVideo> videos, {
  bool truncated = false,
}) => ImportedPlaylist(
  playlistId: _list,
  title: 'Dinosaur songs',
  channelName: 'Kids TV',
  videos: videos,
  truncated: truncated,
);

void main() {
  group('extractPlaylistId', () {
    test('finds list= on playlist pages and on videos from a playlist', () {
      for (final u in [
        'https://www.youtube.com/playlist?list=$_list',
        'https://m.youtube.com/playlist?list=$_list&feature=share',
        'https://youtube.com/watch?v=dQw4w9WgXcQ&list=$_list&index=3',
        'https://youtu.be/dQw4w9WgXcQ?list=$_list',
        'Check this: https://www.youtube.com/playlist?list=$_list !',
      ]) {
        expect(YouTubeUrlParser.extractPlaylistId(u), _list, reason: u);
      }
    });

    test('ignores links without a playlist and other sites', () {
      for (final u in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://evil.example/playlist?list=$_list',
        'https://www.youtube.com/playlist?list=short',
        'hello',
      ]) {
        expect(YouTubeUrlParser.extractPlaylistId(u), isNull, reason: u);
      }
    });

    test('mixes and personal lists are not importable', () {
      expect(YouTubeUrlParser.isImportablePlaylist(_list), isTrue);
      for (final id in [
        'RDdQw4w9WgXcQ',
        'WL',
        'LLxxxxxxxxxx',
        'ULxxxxxxxxxx',
      ]) {
        expect(YouTubeUrlParser.isImportablePlaylist(id), isFalse, reason: id);
      }
    });
  });

  test(
    'ImportPlan splits new, existing, unavailable and over-limit videos',
    () {
      final plan = ImportPlan.from(
        _playlist([
          _v('aaaaaaaaaaa'),
          _v('bbbbbbbbbbb', playable: false),
          _v('ccccccccccc'),
          _v('aaaaaaaaaaa'), // duplicate within the playlist
          _v('ddddddddddd'),
          _v('eeeeeeeeeee'),
        ]),
        existingIds: {'ccccccccccc'},
        capacity: 2,
      );
      expect(plan.toAdd.map((v) => v.videoId), ['aaaaaaaaaaa', 'ddddddddddd']);
      expect(plan.alreadyThere, 1);
      expect(plan.unavailable, 1);
      expect(plan.overLimit, 1);
    },
  );

  group('SupabaseYouTubePlaylistRepository', () {
    SupabaseYouTubePlaylistRepository repoReplying(int status, Object body) =>
        SupabaseYouTubePlaylistRepository(
          SupabaseClient(
            'https://test.supabase.co',
            'anon-key',
            httpClient: MockClient((req) async {
              expect(req.url.path, '/functions/v1/youtube-playlist');
              expect(jsonDecode(req.body), {'playlistId': _list});
              return http.Response(
                jsonEncode(body),
                status,
                headers: {'content-type': 'application/json'},
                request: req,
              );
            }),
          ),
        );

    Matcher failsWith(PlaylistImportError e) => throwsA(
      isA<PlaylistImportException>().having((x) => x.error, 'error', e),
    );

    test('parses the function response', () async {
      final p = await repoReplying(200, {
        'playlistId': _list,
        'title': 'Dinosaur songs',
        'channelName': 'Kids TV',
        'truncated': true,
        'videos': [
          {
            'videoId': 'aaaaaaaaaaa',
            'title': 'T-Rex',
            'channelName': 'Kids TV',
            'durationSeconds': 185,
            'playable': true,
          },
          {'videoId': 'bbbbbbbbbbb', 'title': '', 'playable': false},
        ],
      }).fetch(_list);
      expect(p.title, 'Dinosaur songs');
      expect(p.truncated, isTrue);
      expect(p.videos.first.toMetadata().durationSeconds, 185);
      expect(p.videos.first.toMetadata().thumbnailUrl, contains('i.ytimg.com'));
      expect(p.videos.last.playable, isFalse);
    });

    test('maps function errors', () async {
      await expectLater(
        repoReplying(503, {'error': 'not_configured'}).fetch(_list),
        failsWith(PlaylistImportError.notConfigured),
      );
      await expectLater(
        repoReplying(429, {'error': 'quota'}).fetch(_list),
        failsWith(PlaylistImportError.quota),
      );
      await expectLater(
        repoReplying(404, {'error': 'not_found'}).fetch(_list),
        failsWith(PlaylistImportError.notFound),
      );
    });

    test('refuses mixes without calling the server', () async {
      final repo = SupabaseYouTubePlaylistRepository(
        SupabaseClient(
          'https://test.supabase.co',
          'anon-key',
          httpClient: MockClient((_) => fail('should not be called')),
        ),
      );
      await expectLater(
        repo.fetch('RDdQw4w9WgXcQ'),
        failsWith(PlaylistImportError.unsupported),
      );
    });
  });

  Future<(FakePlaylistRepository, String)> openPlaylist(
    WidgetTester tester, {
    required FakeYouTubePlaylistRepository youtube,
    FakeInAppBrowser? browser,
  }) async {
    final repo = FakePlaylistRepository();
    final p = repo.seed('Dinos', videoIds: ['ccccccccccc']);
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
      browser: browser,
      youtubePlaylists: youtube,
    );
    await tester.tap(find.text('Dinos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add video'));
    await tester.pumpAndSettle();
    return (repo, p.id);
  }

  testWidgets('browser: add a whole playlist from a playlist page', (
    tester,
  ) async {
    final youtube = FakeYouTubePlaylistRepository()
      ..playlists[_list] = _playlist([
        _v('aaaaaaaaaaa'),
        _v('bbbbbbbbbbb', playable: false),
        _v('ccccccccccc'),
        _v('ddddddddddd'),
      ]);
    final browser = FakeInAppBrowser();
    final (repo, id) = await openPlaylist(
      tester,
      youtube: youtube,
      browser: browser,
    );
    await tester.tap(find.byKey(const Key('browse-youtube')));
    await tester.pumpAndSettle();

    browser.visit('https://m.youtube.com/playlist?list=$_list');
    await tester.pump();
    expect(find.byKey(const Key('browser-add-playlist')), findsOneWidget);
    expect(find.byKey(const Key('browser-add')), findsNothing);

    await tester.tap(find.byKey(const Key('browser-add-playlist')));
    await tester.pumpAndSettle();
    expect(find.text('Dinosaur songs'), findsOneWidget);
    expect(find.text('1 video is already in this playlist'), findsOneWidget);
    expect(find.textContaining("1 video can't play in Clipsy"), findsOneWidget);

    await tester.tap(find.text('Add 2 videos'));
    await tester.pumpAndSettle();
    expect(repo.videoIdsOf(id), ['ccccccccccc', 'aaaaaaaaaaa', 'ddddddddddd']);
    expect(find.text('2 videos added'), findsOneWidget);
  });

  testWidgets('browser: a video opened from a playlist offers both', (
    tester,
  ) async {
    final browser = FakeInAppBrowser();
    await openPlaylist(
      tester,
      youtube: FakeYouTubePlaylistRepository(),
      browser: browser,
    );
    await tester.tap(find.byKey(const Key('browse-youtube')));
    await tester.pumpAndSettle();
    browser.visit('https://m.youtube.com/watch?v=aaaaaaaaaaa&list=$_list');
    await tester.pump();
    expect(find.byKey(const Key('browser-add-playlist')), findsOneWidget);
    expect(find.byKey(const Key('browser-add')), findsOneWidget);

    // A mix (auto-generated) is not offered.
    browser.visit(
      'https://m.youtube.com/watch?v=aaaaaaaaaaa&list=RDaaaaaaaaaaa',
    );
    await tester.pump();
    expect(find.byKey(const Key('browser-add-playlist')), findsNothing);
  });

  testWidgets('paste: a playlist link opens the import preview', (
    tester,
  ) async {
    final youtube = FakeYouTubePlaylistRepository()
      ..playlists[_list] = _playlist([_v('aaaaaaaaaaa'), _v('ddddddddddd')]);
    final (repo, id) = await openPlaylist(tester, youtube: youtube);

    await tester.enterText(
      find.byKey(const Key('video-url-field')),
      'https://www.youtube.com/playlist?list=$_list',
    );
    await tester.tap(find.text('Check video'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 2 videos'));
    await tester.pumpAndSettle();
    expect(repo.videoIdsOf(id), ['ccccccccccc', 'aaaaaaaaaaa', 'ddddddddddd']);
    expect(find.text('2 videos added'), findsOneWidget);
  });

  testWidgets('import errors explain what is wrong', (tester) async {
    final youtube = FakeYouTubePlaylistRepository()
      ..error = PlaylistImportError.notConfigured;
    await openPlaylist(tester, youtube: youtube);
    await tester.enterText(
      find.byKey(const Key('video-url-field')),
      'https://www.youtube.com/playlist?list=$_list',
    );
    await tester.tap(find.text('Check video'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("isn't set up yet on the server"),
      findsOneWidget,
    );
  });
}

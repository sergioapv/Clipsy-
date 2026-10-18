import 'dart:convert';

import 'package:clipsy/features/auth/domain/app_user.dart';
import 'package:clipsy/features/playlists/data/oembed_client.dart';
import 'package:clipsy/features/playlists/data/youtube_playlist_repository.dart';
import 'package:clipsy/features/playlists/domain/imported_playlist.dart';
import 'package:clipsy/features/playlists/domain/youtube_url_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  group('PlaylistImporter', () {
    /// oEmbed fake: known ids are embeddable, 'blocked…' ids aren't.
    OEmbedClient oembed({bool offline = false}) => OEmbedClient(
      MockClient((req) async {
        if (offline) throw http.ClientException('offline');
        final url = req.url.queryParameters['url']!;
        if (url.contains('list=PLmissing')) {
          return http.Response('Not Found', 404);
        }
        if (url.contains('/playlist')) {
          return http.Response(
            jsonEncode({'title': 'Dinosaur songs', 'author_name': 'Kids TV'}),
            200,
          );
        }
        final id = Uri.parse(url).queryParameters['v']!;
        if (id.startsWith('blocked')) return http.Response('Unauthorized', 401);
        if (id.startsWith('gone')) return http.Response('Not Found', 404);
        return http.Response(jsonEncode({'title': 'Title $id'}), 200);
      }),
    );

    test('lists ids from the player, then checks each with oEmbed', () async {
      final progress = <(int, int)>[];
      final importer = PlaylistImporter(
        ids: FakePlaylistIdsSource({
          _list: [
            'aaaaaaaaaaa',
            'blockedxxxx',
            'aaaaaaaaaaa', // duplicate
            'gonexxxxxxx',
            'bbbbbbbbbbb',
          ],
        }),
        oembed: oembed(),
        concurrency: 2,
      );
      final p = await importer.fetch(
        _list,
        onProgress: (c, t) => progress.add((c, t)),
      );
      expect(p.title, 'Dinosaur songs');
      expect(p.channelName, 'Kids TV');
      expect(
        [for (final v in p.videos) (v.videoId, v.playable)],
        [
          ('aaaaaaaaaaa', true),
          ('blockedxxxx', false),
          ('gonexxxxxxx', false),
          ('bbbbbbbbbbb', true),
        ],
      );
      expect(p.videos.first.title, 'Title aaaaaaaaaaa');
      expect(progress.first, (0, 4));
      expect(progress.last, (4, 4));
      expect(p.truncated, isFalse);
    });

    test('caps the import at the playlist limit', () async {
      final ids = [
        for (var i = 0; i < 12; i++) 'v${i.toString().padLeft(10, '0')}',
      ];
      final p = await PlaylistImporter(
        ids: FakePlaylistIdsSource({_list: ids}),
        oembed: oembed(),
        maxVideos: 10,
      ).fetch(_list);
      expect(p.videos, hasLength(10));
      expect(p.truncated, isTrue);
    });

    Matcher failsWith(PlaylistImportError e) => throwsA(
      isA<PlaylistImportException>().having((x) => x.error, 'error', e),
    );

    test('a playlist the player cannot list is reported as not found', () {
      expect(
        PlaylistImporter(
          ids: FakePlaylistIdsSource({}),
          oembed: oembed(),
        ).fetch(_list),
        failsWith(PlaylistImportError.notFound),
      );
    });

    test(
      'a playlist oEmbed does not know fails fast, without the player',
      () async {
        final source = FakePlaylistIdsSource({});
        await expectLater(
          PlaylistImporter(
            ids: source,
            oembed: oembed(),
          ).fetch('PLmissingmissing'),
          failsWith(PlaylistImportError.notFound),
        );
        expect(source.requests, isEmpty);
      },
    );

    test(
      'a full 200-video list from the player is flagged as cut off',
      () async {
        final ids = [
          for (var i = 0; i < 200; i++) 'v${i.toString().padLeft(10, '0')}',
        ];
        final p = await PlaylistImporter(
          ids: FakePlaylistIdsSource({_list: ids}),
          oembed: oembed(),
          concurrency: 8,
        ).fetch(_list);
        expect(p.videos, hasLength(200));
        expect(p.truncated, isTrue);
      },
    );

    test('network trouble while checking videos is reported', () {
      expect(
        PlaylistImporter(
          ids: FakePlaylistIdsSource({
            _list: ['aaaaaaaaaaa'],
          }),
          oembed: oembed(offline: true),
        ).fetch(_list),
        failsWith(PlaylistImportError.network),
      );
    });

    test('mixes are refused without touching the player', () async {
      final source = FakePlaylistIdsSource({});
      await expectLater(
        PlaylistImporter(ids: source, oembed: oembed()).fetch('RDaaaaaaaaaaa'),
        failsWith(PlaylistImportError.unsupported),
      );
      expect(source.requests, isEmpty);
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
      ..error = PlaylistImportError.notFound;
    await openPlaylist(tester, youtube: youtube);
    await tester.enterText(
      find.byKey(const Key('video-url-field')),
      'https://www.youtube.com/playlist?list=$_list',
    );
    await tester.tap(find.text('Check video'));
    await tester.pumpAndSettle();
    expect(find.textContaining("couldn't read that playlist"), findsOneWidget);
    // The sheet hosts the (here fake) hidden player while it works.
    expect(find.byKey(const Key('fake-playlist-host')), findsOneWidget);
  });
}

class FakePlaylistIdsSource implements PlaylistIdsSource {
  FakePlaylistIdsSource(this.lists);

  final Map<String, List<String>> lists;
  final requests = <String>[];

  @override
  Widget buildHost(BuildContext context) => const SizedBox();

  @override
  Future<List<String>> videoIds(String playlistId) async {
    requests.add(playlistId);
    return lists[playlistId] ??
        (throw const PlaylistImportException(PlaylistImportError.notFound));
  }

  @override
  Future<void> dispose() async {}
}

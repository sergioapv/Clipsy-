import 'package:clipsy/features/auth/domain/app_user.dart';
import 'package:clipsy/features/playlists/domain/video_metadata.dart';
import 'package:clipsy/features/playlists/domain/youtube_browse_policy.dart';
import 'package:clipsy/features/playlists/presentation/playlist_detail_screen.dart';
import 'package:clipsy/features/playlists/presentation/youtube_browser_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_playlists.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const _parent = AppUser(id: 'u1', email: 'parent@example.com');

void main() {
  group('YouTubeBrowsePolicy', () {
    bool allows(String u) => YouTubeBrowsePolicy.allows(Uri.tryParse(u));

    test('stays on YouTube and its consent pages', () {
      for (final u in [
        'https://m.youtube.com/',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        'https://youtube.com/results?search_query=dinosaurs',
        'https://consent.youtube.com/m?continue=x',
        'https://consent.google.com/ml?continue=x',
        'about:blank',
      ]) {
        expect(allows(u), isTrue, reason: u);
      }
    });

    test('blocks app hand-offs and other sites', () {
      for (final u in [
        'intent://www.youtube.com/watch?v=x#Intent;scheme=vnd.youtube;end',
        'vnd.youtube:dQw4w9WgXcQ',
        'http://m.youtube.com/',
        'https://evil.example/',
        'https://notyoutube.com/',
        'https://youtube.com.evil.example/',
        'https://accounts.google.com/signin',
        'market://details?id=com.google.android.youtube',
      ]) {
        expect(allows(u), isFalse, reason: u);
      }
      expect(YouTubeBrowsePolicy.allows(null), isFalse);
    });
  });

  Future<(FakePlaylistRepository, FakeInAppBrowser, String)> openBrowser(
    WidgetTester tester, {
    FakeVideoLookupRepository? lookup,
    List<String> languages = const [],
    Map<String, Object> prefs = const {},
  }) async {
    final repo = FakePlaylistRepository();
    final p = repo.seed(
      'Animals',
      videoIds: ['aaaaaaaaaaa'],
      languages: languages,
    );
    final browser = FakeInAppBrowser();
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
      lookup: lookup,
      browser: browser,
      prefs: prefs,
    );
    await tester.tap(find.text('Animals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add video'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browse-youtube')));
    await tester.pumpAndSettle();
    return (repo, browser, p.id);
  }

  testWidgets('YouTube opens in the playlist language; the choice is kept', (
    tester,
  ) async {
    final (_, browser, _) = await openBrowser(tester, languages: ['pt-PT']);
    expect(
      browser.loads.single,
      Uri.parse('https://m.youtube.com/?hl=pt-PT&gl=PT'),
    );
    expect(find.text('pt-PT'), findsOneWidget);

    // Switch to Brazilian Portuguese (YouTube calls it plain "pt").
    await tester.tap(find.byKey(const Key('browser-language')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('language-search')), 'pt-br');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-pt-BR')));
    await tester.pumpAndSettle();
    expect(browser.loads.last, Uri.parse('https://m.youtube.com/?hl=pt&gl=BR'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('browser.language'), 'pt-BR');

    // Any language: back to the app's, which also resets YouTube's cookie.
    await tester.tap(find.byKey(const Key('browser-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-any')));
    await tester.pumpAndSettle();
    expect(browser.loads.last, Uri.parse('https://m.youtube.com/?hl=en'));
    expect(prefs.getString('browser.language'), isNull);
  });

  testWidgets('a playlist without a language uses the last choice', (
    tester,
  ) async {
    final (_, browser, _) = await openBrowser(
      tester,
      prefs: {'browser.language': 'en-GB'},
    );
    expect(
      browser.loads.single,
      Uri.parse('https://m.youtube.com/?hl=en-GB&gl=GB'),
    );
  });

  test('BCP 47 tags map onto YouTube hl/gl', () {
    expect(YouTubeBrowsePolicy.youTubeLocale('pt-PT'), ('pt-PT', 'PT'));
    expect(YouTubeBrowsePolicy.youTubeLocale('pt-BR'), ('pt', 'BR'));
    expect(YouTubeBrowsePolicy.youTubeLocale('pt'), ('pt', null));
    expect(YouTubeBrowsePolicy.youTubeLocale('en-GB'), ('en-GB', 'GB'));
    expect(YouTubeBrowsePolicy.youTubeLocale('es-ES'), ('es', 'ES'));
    expect(YouTubeBrowsePolicy.youTubeLocale('es-419'), ('es-419', null));
    expect(YouTubeBrowsePolicy.youTubeLocale('zh-Hant'), ('zh-TW', 'TW'));
    expect(YouTubeBrowsePolicy.youTubeLocale('zh-Hans'), ('zh-CN', null));
    expect(YouTubeBrowsePolicy.youTubeLocale('fr-CA'), ('fr-CA', 'CA'));
  });

  testWidgets('browse, open a video, add it to the playlist', (tester) async {
    final lookup = FakeVideoLookupRepository()
      ..addKnown('dQw4w9WgXcQ', 'Lions roar');
    final (repo, browser, id) = await openBrowser(tester, lookup: lookup);

    expect(find.byType(YouTubeBrowserScreen), findsOneWidget);
    // No language on the playlist: YouTube in the app's language.
    expect(browser.loads.single, Uri.parse('https://m.youtube.com/?hl=en'));
    // Not on a video page: nothing to add.
    expect(find.byKey(const Key('browser-add')), findsNothing);

    browser.visit('https://m.youtube.com/results?search_query=lions');
    await tester.pump();
    expect(find.byKey(const Key('browser-add')), findsNothing);

    browser.visit('https://m.youtube.com/watch?v=dQw4w9WgXcQ&pp=abc');
    await tester.pump();
    expect(find.text('Add to “Animals”'), findsOneWidget);

    await tester.tap(find.byKey(const Key('browser-add')));
    await tester.pumpAndSettle();
    expect(repo.videoIdsOf(id), ['aaaaaaaaaaa', 'dQw4w9WgXcQ']);
    expect(find.text('Added “Lions roar”'), findsOneWidget);
    expect(find.text('In this playlist'), findsOneWidget);

    // A video that's already there shows as added straight away.
    browser.visit('https://m.youtube.com/shorts/aaaaaaaaaaa');
    await tester.pump();
    expect(find.byKey(const Key('browser-added')), findsOneWidget);
  });

  testWidgets('videos that cannot be embedded are refused with a reason', (
    tester,
  ) async {
    final lookup = FakeVideoLookupRepository()
      ..errors['bbbbbbbbbbb'] = VideoLookupError.notEmbeddable;
    final (repo, browser, id) = await openBrowser(tester, lookup: lookup);

    browser.visit('https://m.youtube.com/watch?v=bbbbbbbbbbb');
    await tester.pump();
    await tester.tap(find.byKey(const Key('browser-add')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("doesn't allow it to play outside YouTube"),
      findsOneWidget,
    );
    expect(repo.videoIdsOf(id), ['aaaaaaaaaaa']);
  });

  testWidgets('back goes back in the browser first, then closes it', (
    tester,
  ) async {
    final (_, browser, _) = await openBrowser(tester);
    browser.visit('https://m.youtube.com/watch?v=dQw4w9WgXcQ');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(browser.backs, 1);
    expect(find.byType(YouTubeBrowserScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(YouTubeBrowserScreen), findsNothing);
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
  });
}

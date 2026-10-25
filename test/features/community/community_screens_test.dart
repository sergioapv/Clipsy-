import 'package:clipsy/core/storage/secure_store.dart';
import 'package:clipsy/features/auth/domain/app_user.dart';
import 'package:clipsy/features/community/domain/community_playlist.dart';
import 'package:clipsy/features/community/presentation/community_playlist_screen.dart';
import 'package:clipsy/features/playlists/domain/playlist.dart';
import 'package:clipsy/features/playlists/presentation/playlist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_community.dart';
import '../../helpers/fake_playlists.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const _parent = AppUser(id: 'u1', email: 'parent@example.com');

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

FakeCommunityRepository _library({FakePlaylistRepository? mine}) =>
    FakeCommunityRepository(library: mine)
      ..publish(
        'Ocean animals',
        id: 'c1',
        ratingAvg: 4.2,
        ratingCount: 5,
        labels: ['animals'],
        ageRange: AgeRange.young,
      )
      ..publish(
        'Space for toddlers',
        id: 'c2',
        author: 'Rui',
        ratingAvg: 4.8,
        ratingCount: 9,
        labels: ['space'],
        ageRange: AgeRange.toddlers,
      )
      ..publish(
        'Bedtime songs',
        id: 'c3',
        author: 'Ana',
        labels: ['music'],
        ageRange: AgeRange.toddlers,
      );

Future<void> _openCommunity(WidgetTester tester) async {
  await tester.tap(find.text('Community'));
  await tester.pumpAndSettle();
}

List<String> _titles(WidgetTester tester) =>
    [
      for (final t in ['Ocean animals', 'Space for toddlers', 'Bedtime songs'])
        if (find.text(t).evaluate().isNotEmpty) t,
    ]..sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );

void main() {
  testWidgets('browse: top rated, new, age filter, label and search', (
    tester,
  ) async {
    _tallPhone(tester);
    final community = _library();
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      community: community,
    );
    await _openCommunity(tester);

    // Top rated: best average first, unrated last; authors, never emails.
    expect(_titles(tester), [
      'Space for toddlers',
      'Ocean animals',
      'Bedtime songs',
    ]);
    expect(find.text('by Rui'), findsOneWidget);
    expect(find.text('No ratings yet'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);

    // New: most recently published first.
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    expect(_titles(tester), [
      'Bedtime songs',
      'Space for toddlers',
      'Ocean animals',
    ]);

    // Ages 5–7.
    await tester.ensureVisible(find.byKey(Key('age-filter-${AgeRange.young}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('age-filter-${AgeRange.young}')));
    await tester.pumpAndSettle();
    expect(_titles(tester), ['Ocean animals']);
    await tester.ensureVisible(find.byKey(const Key('age-filter-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('age-filter-all')));
    await tester.pumpAndSettle();

    // By label: pick a topic first.
    await tester.tap(find.text('By label'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a topic'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pick-label-space')));
    await tester.pumpAndSettle();
    expect(_titles(tester), ['Space for toddlers']);
    expect(find.byKey(const Key('selected-label')), findsOneWidget);
    await tester.tap(find.byKey(const Key('selected-label')));
    await tester.pumpAndSettle();
    expect(find.text('Pick a topic'), findsOneWidget);

    // Search by title (debounced).
    await tester.tap(find.text('Top rated'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('community-search')), 'bed');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(_titles(tester), ['Bedtime songs']);

    await tester.enterText(find.byKey(const Key('community-search')), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('community: filter by language or by variant', (tester) async {
    _tallPhone(tester);
    final community = FakeCommunityRepository()
      ..publish('Canções', id: 'pt', languages: ['pt-PT'])
      ..publish('Músicas', id: 'br', languages: ['pt-BR'])
      ..publish('Fado', id: 'any', languages: ['pt'])
      ..publish('Songs', id: 'en', languages: ['en-GB']);
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      community: community,
    );
    await _openCommunity(tester);
    final all = ['Canções', 'Músicas', 'Fado', 'Songs'];
    List<String> shown() => [
      for (final t in all)
        if (find.text(t).evaluate().isNotEmpty) t,
    ];
    expect(shown(), all);

    Future<void> pick(String tag) async {
      await tester.tap(find.byKey(const Key('community-language-filter')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('language-search')), tag);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('language-$tag')));
      await tester.pumpAndSettle();
    }

    // Português (Portugal): pt-PT, plus the one tagged just "pt".
    await pick('pt-PT');
    expect(shown(), ['Canções', 'Fado']);
    expect(find.text('Português (Portugal)'), findsWidgets);

    // Português, all variants.
    await pick('pt');
    expect(shown(), ['Canções', 'Músicas', 'Fado']);

    // Clear the filter.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('community-language-filter')),
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(shown(), all);
  });

  testWidgets('my playlists: filter by the languages they use', (tester) async {
    _tallPhone(tester);
    final repo = FakePlaylistRepository()
      ..seed('Contos', languages: ['pt-PT'])
      ..seed('Stories', languages: ['en-GB', 'pt-BR'])
      ..seed('Untagged');
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
    );
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('library-language-filter')));
    await tester.pumpAndSettle();
    // Only the languages in use (and their "all variants" entries).
    expect(find.byKey(const Key('language-pt-PT')), findsOneWidget);
    expect(find.byKey(const Key('language-pt')), findsOneWidget);
    expect(find.byKey(const Key('language-en-GB')), findsOneWidget);
    expect(find.byKey(const Key('language-fr')), findsNothing);
    await tester.tap(find.byKey(const Key('language-pt')));
    await tester.pumpAndSettle();
    expect(find.text('Contos'), findsOneWidget);
    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('Untagged'), findsNothing);
    // No reordering while filtered.
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('library-language-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-en-GB')));
    await tester.pumpAndSettle();
    expect(find.text('Contos'), findsNothing);
    expect(find.text('Stories'), findsOneWidget);

    await tester.tap(find.byKey(const Key('library-language-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-any')));
    await tester.pumpAndSettle();
    expect(find.text('Untagged'), findsOneWidget);
  });

  testWidgets('save a copy to my playlists, then open it', (tester) async {
    _tallPhone(tester);
    final mine = FakePlaylistRepository();
    final community = _library(mine: mine);
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: mine,
      community: community,
    );
    await _openCommunity(tester);
    await tester.tap(find.text('Ocean animals'));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityPlaylistScreen), findsOneWidget);
    expect(find.text('Video aaaaaaaaaaa'), findsOneWidget);

    await tester.tap(find.byKey(const Key('community-save')));
    await tester.pumpAndSettle();
    expect(find.text('Saved to your playlists'), findsOneWidget);
    expect(mine.playlists.single.title, 'Ocean animals');

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    expect(find.text('Video bbbbbbbbbbb'), findsOneWidget);
  });

  testWidgets('rate a playlist and change the rating', (tester) async {
    _tallPhone(tester);
    final community = _library();
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      community: community,
    );
    await _openCommunity(tester);
    await tester.tap(find.text('Bedtime songs'));
    await tester.pumpAndSettle();
    expect(find.text('Tap a star to rate this playlist.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rate-star-4')));
    await tester.pumpAndSettle();
    expect(community.myRatings['c3'], 4);
    expect(find.text('Thanks for rating.'), findsOneWidget);
    expect(find.text('4.0'), findsOneWidget);
    expect(find.text(' (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rate-star-2')));
    await tester.pumpAndSettle();
    expect(community.myRatings['c3'], 2);
  });

  testWidgets('own shared playlist: no rating, no report', (tester) async {
    _tallPhone(tester);
    final community = _library()
      ..publish('My dinosaurs', id: 'mine', ownerId: 'u1', author: 'Me');
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      community: community,
    );
    await _openCommunity(tester);
    expect(find.text('Yours'), findsOneWidget);
    await tester.ensureVisible(find.text('My dinosaurs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My dinosaurs'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('community-own')), findsOneWidget);
    expect(find.byKey(const Key('rate-star-1')), findsNothing);
    expect(find.byKey(const Key('community-menu')), findsNothing);
  });

  testWidgets('report a playlist once', (tester) async {
    _tallPhone(tester);
    final community = _library();
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      community: community,
    );
    await _openCommunity(tester);
    await tester.tap(find.text('Ocean animals'));
    await tester.pumpAndSettle();

    Future<void> report() async {
      await tester.tap(find.byKey(const Key('community-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('community-report')));
      await tester.pumpAndSettle();
      // Nothing to send until a reason is picked.
      final send = find.byKey(const Key('report-send'));
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      await tester.tap(find.byKey(const Key('report-reason-notForKids')));
      await tester.enterText(
        find.byKey(const Key('report-details')),
        'Very scary shark',
      );
      await tester.pump();
      await tester.tap(send);
      await tester.pumpAndSettle();
    }

    await report();
    expect(community.reports.single, (
      'c1',
      ReportReason.notForKids,
      'Very scary shark',
    ));
    expect(find.text("Thanks. We'll take a look."), findsOneWidget);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await report();
    expect(community.reports, hasLength(1));
    expect(find.text("You've already reported this playlist."), findsOneWidget);
  });

  testWidgets('share a playlist with the community and stop sharing', (
    tester,
  ) async {
    _tallPhone(tester);
    final repo = FakePlaylistRepository()
      ..seed('No labels', videoIds: ['aaaaaaaaaaa'])
      ..seed(
        'Ready',
        videoIds: ['bbbbbbbbbbb'],
        labelIds: [3],
        languages: ['pt-PT'],
      );
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
    );

    Future<void> menu(String key) async {
      await tester.tap(find.byTooltip('More options').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    // Labels are required.
    await tester.tap(find.text('No labels'));
    await tester.pumpAndSettle();
    await menu('menu-share');
    expect(
      find.text('Pick at least one label to share this playlist.'),
      findsOneWidget,
    );
    expect(repo.playlists.first.visibility, PlaylistVisibility.private);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ready'));
    await tester.pumpAndSettle();
    await menu('menu-share');
    expect(repo.playlists.last.visibility, PlaylistVisibility.public);
    expect(find.byKey(const Key('shared-status')), findsOneWidget);

    await menu('menu-unshare');
    expect(repo.playlists.last.visibility, PlaylistVisibility.private);
    expect(find.byKey(const Key('shared-status')), findsNothing);
    expect(find.text('No longer shared'), findsOneWidget);
  });

  testWidgets('the editor only offers sharing once there are videos', (
    tester,
  ) async {
    _tallPhone(tester);
    final repo = FakePlaylistRepository()
      ..seed('Empty')
      ..seed('Birds', videoIds: ['aaaaaaaaaaa'], labelIds: [3]);
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
    );

    Future<void> edit(String title) async {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More options').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
    }

    await edit('Empty');
    final empty = find.byKey(const Key('share-switch'));
    await tester.scrollUntilVisible(
      empty,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<SwitchListTile>(empty).onChanged, isNull);
    expect(
      find.text('Add a video first, then you can share it.'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await edit('Birds');
    final share = find.byKey(const Key('share-switch'));
    await tester.scrollUntilVisible(
      share,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(share);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(share).value, isTrue);

    // Sharing needs a language.
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pick at least one language to share this playlist.'),
      findsOneWidget,
    );
    expect(repo.playlists.last.visibility, PlaylistVisibility.private);

    // Typed as people write it: "pt-br".
    final add = find.byKey(const Key('add-language'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('language-search')), 'pt-br');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-pt-BR')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('language-chip-pt-BR')), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(repo.playlists.last.visibility, PlaylistVisibility.public);
    expect(repo.playlists.last.languages, ['pt-BR']);
  });

  testWidgets('change the name shown in the community', (tester) async {
    _tallPhone(tester);
    final profile = FakeProfileRepository();
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      profile: profile,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final tile = find.byKey(const Key('community-name-tile'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: tile, matching: find.text('Parent')),
      findsOneWidget,
    );

    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('community-name-field')), '  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Use 1 to 40 characters.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('community-name-field')),
      'Marta S.',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(profile.name, 'Marta S.');
    expect(
      find.descendant(of: tile, matching: find.text('Marta S.')),
      findsOneWidget,
    );
  });

  group('share to Clipsy', () {
    testWidgets('a shared video link goes into the chosen playlist', (
      tester,
    ) async {
      _tallPhone(tester);
      final repo = FakePlaylistRepository()
        ..seed('Dinosaurs', videoIds: ['aaaaaaaaaaa']);
      final lookup = FakeVideoLookupRepository()
        ..addKnown('ccccccccccc', 'T. rex for kids');
      final shares = FakeShareIntake();
      await pumpUnlockedClipsy(
        tester,
        auth: FakeAuthRepository(user: _parent),
        playlists: repo,
        lookup: lookup,
        shares: shares,
      );

      shares.share('Watch this! https://youtu.be/ccccccccccc?si=abc');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-intake-sheet')), findsOneWidget);
      await tester.tap(find.text('Dinosaurs').last);
      await tester.pumpAndSettle();

      // The add-video sheet has already checked the link.
      expect(find.text('T. rex for kids'), findsOneWidget);
      await tester.tap(find.text('Add to playlist'));
      await tester.pumpAndSettle();
      expect(repo.videoIdsOf(repo.playlists.single.id), [
        'aaaaaaaaaaa',
        'ccccccccccc',
      ]);
    });

    testWidgets('anything that is not a YouTube link is turned down', (
      tester,
    ) async {
      _tallPhone(tester);
      final shares = FakeShareIntake();
      await pumpUnlockedClipsy(
        tester,
        auth: FakeAuthRepository(user: _parent),
        playlists: FakePlaylistRepository()..seed('Dinosaurs'),
        shares: shares,
      );
      shares.share('https://example.com/cats');
      await tester.pumpAndSettle();
      expect(
        find.text("That link isn't a YouTube video or playlist."),
        findsOneWidget,
      );
      expect(find.byKey(const Key('share-intake-sheet')), findsNothing);
    });

    testWidgets('a link shared while locked waits for the PIN', (tester) async {
      _tallPhone(tester);
      final shares = FakeShareIntake();
      await pumpClipsy(
        tester,
        auth: FakeAuthRepository(user: _parent),
        store: InMemorySecureStore({'pin.hash': await testHasher.hash('2468')}),
        prefs: {'onboarding.complete': true},
        playlists: FakePlaylistRepository()..seed('Dinosaurs'),
        shares: shares,
      );
      shares.share('https://www.youtube.com/watch?v=ccccccccccc');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-intake-sheet')), findsNothing);

      await enterPin(tester, '2468');
      expect(find.byKey(const Key('share-intake-sheet')), findsOneWidget);
    });
  });
}

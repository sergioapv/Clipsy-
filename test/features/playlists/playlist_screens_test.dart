import 'package:clipsy/features/auth/domain/app_user.dart';
import 'package:clipsy/features/playlists/domain/video_metadata.dart';
import 'package:clipsy/features/playlists/presentation/playlist_detail_screen.dart';
import 'package:clipsy/features/playlists/presentation/playlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_playlists.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const _parent = AppUser(id: 'u1', email: 'parent@example.com');

void main() {
  testWidgets('library shows playlists with counts', (tester) async {
    final repo = FakePlaylistRepository()
      ..seed('Dinosaurs', videoIds: ['aaaaaaaaaaa', 'bbbbbbbbbbb'])
      ..seed('Empty one');
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
    );
    expect(find.byType(PlaylistsScreen), findsOneWidget);
    expect(find.text('Dinosaurs'), findsOneWidget);
    expect(find.textContaining('2 videos'), findsOneWidget);
    expect(find.textContaining('No videos'), findsOneWidget);
  });

  testWidgets('create a playlist: title required, labels capped at 3', (
    tester,
  ) async {
    // Tall screen so the whole form is built at once.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final repo = FakePlaylistRepository();
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
    );

    await tester.tap(find.text('New playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Create'));
    await tester.pumpAndSettle();
    expect(find.text('Give the playlist a title'), findsOneWidget);
    expect(repo.calls, isNot(contains('create')));

    await tester.enterText(find.byType(TextFormField).first, 'Planets');
    await tester.tap(find.text('Ages 5–7'));
    for (final label in ['Science', 'Nature', 'Space']) {
      await tester.tap(find.widgetWithText(FilterChip, label));
      await tester.pump();
    }
    final animals = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Animals'),
    );
    expect(animals.onSelected, isNull, reason: 'fourth label is disabled');
    // Unknown slugs fall back to the database name.
    expect(find.widgetWithText(FilterChip, 'Robots'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Create'));
    await tester.pumpAndSettle();

    final created = repo.playlists.single;
    expect(created.title, 'Planets');
    expect(created.ageRange.min, 5);
    expect(created.labelIds, [1, 2, 4]);
    // Lands on the new playlist, ready to add videos.
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    expect(find.text('No videos yet'), findsOneWidget);
  });

  testWidgets('add videos by URL, with friendly errors', (tester) async {
    final repo = FakePlaylistRepository();
    final p = repo.seed('Animals', videoIds: ['aaaaaaaaaaa']);
    final lookup = FakeVideoLookupRepository()
      ..addKnown('dQw4w9WgXcQ', 'Lions roar')
      ..errors['bbbbbbbbbbb'] = VideoLookupError.notEmbeddable;
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
      lookup: lookup,
    );
    await tester.tap(find.text('Animals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add video'));
    await tester.pumpAndSettle();

    Future<void> check(String text) async {
      await tester.enterText(find.byKey(const Key('video-url-field')), text);
      await tester.tap(find.text('Check video'));
      await tester.pumpAndSettle();
    }

    await check('hello');
    expect(
      find.text("That doesn't look like a link to a YouTube video."),
      findsOneWidget,
    );

    await check('https://youtu.be/bbbbbbbbbbb');
    expect(
      find.textContaining("doesn't allow it to play outside YouTube"),
      findsOneWidget,
    );

    await check('https://youtu.be/aaaaaaaaaaa');
    expect(find.text('This video is already in the playlist.'), findsOneWidget);

    await check('Look! https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=3');
    expect(find.text('Lions roar'), findsOneWidget);
    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();

    expect(find.text('1 video added'), findsOneWidget);
    expect(repo.videoIdsOf(p.id), ['aaaaaaaaaaa', 'dQw4w9WgXcQ']);

    // Close the sheet; the list shows the new video.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Lions roar'), findsOneWidget);
    expect(find.textContaining('2 videos'), findsOneWidget);
  });

  testWidgets('swipe to remove, then undo', (tester) async {
    final repo = FakePlaylistRepository();
    final p = repo.seed('Songs', videoIds: ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
    );
    await tester.tap(find.text('Songs'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Video aaaaaaaaaaa'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Video aaaaaaaaaaa'), findsNothing);
    expect(repo.videoIdsOf(p.id), ['bbbbbbbbbbb']);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Video aaaaaaaaaaa'), findsOneWidget);
    expect(repo.videoIdsOf(p.id), ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
  });

  testWidgets('delete a playlist from its screen', (tester) async {
    final repo = FakePlaylistRepository()..seed('Old stuff');
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
    );
    await tester.tap(find.text('Old stuff'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.playlists, isEmpty);
    expect(find.byType(PlaylistsScreen), findsOneWidget);
    expect(find.text('No playlists yet'), findsOneWidget);
  });
}

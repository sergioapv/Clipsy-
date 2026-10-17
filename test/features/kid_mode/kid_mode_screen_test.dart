import 'dart:convert';

import 'package:clipsy/core/storage/secure_store.dart';
import 'package:clipsy/features/auth/domain/app_user.dart';
import 'package:clipsy/features/kid_mode/data/kid_mode_storage.dart';
import 'package:clipsy/features/kid_mode/domain/kid_player.dart';
import 'package:clipsy/features/kid_mode/domain/kid_session.dart';
import 'package:clipsy/features/kid_mode/domain/kid_settings.dart';
import 'package:clipsy/features/kid_mode/domain/screen_time.dart';
import 'package:clipsy/features/kid_mode/presentation/kid_mode_screen.dart';
import 'package:clipsy/features/playlists/presentation/playlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_kid_mode.dart';
import '../../helpers/fake_playlists.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const _parent = AppUser(id: 'u1', email: 'parent@example.com');

String _sessionJson(
  FakeClock clock, {
  Duration limit = const Duration(minutes: 10),
  EndBehaviour end = EndBehaviour.hardStop,
}) => jsonEncode(
  KidSession(
    playlistId: 'p1',
    playlistTitle: 'Animals',
    videos: const [
      KidVideo(rowId: 'r0', youtubeId: 'aaaaaaaaaaa', title: 'Lions'),
      KidVideo(rowId: 'r1', youtubeId: 'bbbbbbbbbbb', title: 'Tigers'),
    ],
    clock: ScreenTimeClock.start(
      limit: limit,
      mode: TimerMode.wallClock,
      now: clock.now,
    ),
    endBehaviour: end,
    startedAt: clock.now,
  ).toJson(),
);

/// Opens the app with a Kid mode session already active (as after a restart).
Future<({FakeKidPlayer player, FakeDeviceLock lock, InMemorySecureStore store})>
_pumpInKidMode(
  WidgetTester tester,
  FakeClock clock, {
  Duration limit = const Duration(minutes: 10),
  FakeAuthRepository? auth,
}) async {
  final player = FakeKidPlayer();
  final lock = FakeDeviceLock();
  final store = InMemorySecureStore({
    'pin.hash': await testHasher.hash('2468'),
  });
  await pumpClipsy(
    tester,
    auth: auth ?? FakeAuthRepository(user: _parent),
    store: store,
    prefs: {
      'onboarding.complete': true,
      KidSessionStore.key: _sessionJson(clock, limit: limit),
    },
    clock: clock,
    player: player,
    deviceLock: lock,
  );
  return (player: player, lock: lock, store: store);
}

Future<void> _elapse(WidgetTester tester, FakeClock clock, Duration d) async {
  for (var s = 0; s < d.inSeconds; s++) {
    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _holdExit(WidgetTester tester, Duration hold) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const Key('kid-exit-button'))),
  );
  await tester.pump(); // First frame starts the hold animation.
  await tester.pump(hold);
  // Animations complete on the frame after their duration.
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starting Kid mode: default limit → PIN → pinning → kid screen', (
    tester,
  ) async {
    final repo = FakePlaylistRepository()
      ..seed('Animals', videoIds: ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
    final player = FakeKidPlayer();
    final lock = FakeDeviceLock();
    await pumpUnlockedClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      playlists: repo,
      player: player,
      deviceLock: lock,
    );
    await tester.tap(find.text('Animals'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-kid-mode')));
    await tester.pumpAndSettle();

    expect(find.text('Use default: 20 min'), findsOneWidget);
    await tester.tap(find.byKey(const Key('use-default-limit')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your PIN to start Kid mode'), findsOneWidget);
    await enterPin(tester, '2468');

    expect(find.text('Clipsy will pin itself'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.byType(KidModeScreen), findsOneWidget);
    expect(lock.startCalls, 1);
    expect(player.loaded.first.$1, 'aaaaaaaaaaa');
    expect(find.text('20 min'), findsOneWidget);
  });

  testWidgets('every exit path is gated by the long press and the PIN', (
    tester,
  ) async {
    final clock = FakeClock();
    final kid = await _pumpInKidMode(tester, clock);
    expect(find.byType(KidModeScreen), findsOneWidget);
    expect(kid.lock.startCalls, 1, reason: 'pinning re-applied on restart');

    // System back does nothing.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(KidModeScreen), findsOneWidget);

    // A tap, or a hold that's too short, does nothing.
    await tester.tap(find.byKey(const Key('kid-exit-button')));
    await tester.pumpAndSettle();
    await _holdExit(tester, const Duration(seconds: 2));
    expect(find.text('Enter parent PIN'), findsNothing);

    // A full hold opens the PIN; a wrong PIN keeps Kid mode.
    await _holdExit(tester, const Duration(seconds: 3));
    expect(find.text('Enter parent PIN'), findsOneWidget);
    await enterPin(tester, '1111');
    expect(find.text('Wrong PIN'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(KidModeScreen), findsOneWidget);

    // The right PIN leaves Kid mode straight into parent mode.
    await _holdExit(tester, const Duration(seconds: 3));
    await enterPin(tester, '2468');
    expect(find.byType(KidModeScreen), findsNothing);
    expect(find.byType(PlaylistsScreen), findsOneWidget);
    expect(kid.lock.pinned, isFalse);
  });

  testWidgets('kid controls: play/pause and picking a video', (tester) async {
    final clock = FakeClock();
    final kid = await _pumpInKidMode(tester, clock);

    await tester.tap(find.byKey(const Key('kid-play-pause')));
    await tester.pump();
    expect(kid.player.plays, 1);
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);

    await tester.tap(find.byKey(const Key('kid-thumb-1')));
    await tester.pump();
    expect(kid.player.loaded.last, ('bbbbbbbbbbb', true));

    // When a video ends, the next one plays automatically.
    kid.player.emit(const PlayerEnded());
    await tester.pump();
    expect(kid.player.loaded.last, ('aaaaaaaaaaa', false));
  });

  testWidgets("time's up: almost-done hint, All done screen, PIN to extend", (
    tester,
  ) async {
    final clock = FakeClock();
    final kid = await _pumpInKidMode(
      tester,
      clock,
      limit: const Duration(minutes: 2),
    );
    await tester.tap(find.byKey(const Key('kid-play-pause')));
    await tester.pump();

    await _elapse(tester, clock, const Duration(seconds: 61));
    expect(find.text('Almost done!'), findsOneWidget);

    await _elapse(tester, clock, const Duration(seconds: 60));
    expect(find.text('All done for now!'), findsOneWidget);
    expect(kid.player.pauses, greaterThanOrEqualTo(1));
    expect(find.byKey(const Key('fake-player')), findsNothing);

    // The kid can't get past it: back does nothing, no thumbnails to tap.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('All done for now!'), findsOneWidget);

    // Parent: PIN, then +5 min.
    await tester.tap(find.byKey(const Key('time-up-parent')));
    await tester.pumpAndSettle();
    await enterPin(tester, '2468');
    await tester.tap(find.text('+5 min'));
    await tester.pumpAndSettle();
    expect(find.text('All done for now!'), findsNothing);
    expect(find.text('5 min'), findsOneWidget);

    // Runs out again; this time the parent exits.
    await _elapse(tester, clock, const Duration(minutes: 5));
    expect(find.text('All done for now!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('time-up-parent')));
    await tester.pumpAndSettle();
    await enterPin(tester, '2468');
    await tester.tap(find.text('Exit Kid mode'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistsScreen), findsOneWidget);
  });

  testWidgets('killing the app during time-up does not reset the timer', (
    tester,
  ) async {
    final clock = FakeClock();
    // Session started 15 minutes ago with a 10-minute limit.
    final started = FakeClock(clock.now.subtract(const Duration(minutes: 15)));
    await pumpClipsy(
      tester,
      // Even signed out (e.g. expired session), Kid mode comes back first.
      auth: FakeAuthRepository(),
      prefs: {KidSessionStore.key: _sessionJson(started)},
      clock: clock,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('All done for now!'), findsOneWidget);
  });
}

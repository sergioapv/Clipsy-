import 'dart:convert';

import 'package:clipsy/core/storage/secure_store.dart';
import 'package:clipsy/features/auth/domain/app_user.dart';
import 'package:clipsy/features/kid_mode/data/kid_mode_storage.dart';
import 'package:clipsy/features/kid_mode/domain/kid_player.dart';
import 'package:clipsy/features/kid_mode/domain/kid_session.dart';
import 'package:clipsy/features/kid_mode/domain/kid_settings.dart';
import 'package:clipsy/features/kid_mode/domain/screen_time.dart';
import 'package:clipsy/features/kid_mode/presentation/kid_fullscreen_view.dart';
import 'package:clipsy/features/kid_mode/presentation/kid_mode_screen.dart';
import 'package:clipsy/features/playlists/presentation/playlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  EndBehaviour end = EndBehaviour.hardStop,
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
      KidSessionStore.key: _sessionJson(clock, limit: limit, end: end),
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

  testWidgets('kids can move back and forward through the video', (
    tester,
  ) async {
    final clock = FakeClock();
    final kid = await _pumpInKidMode(tester, clock);
    kid.player.emitPosition(
      const Duration(seconds: 30),
      const Duration(minutes: 2),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('kid-seek-forward')));
    await tester.pump();
    expect(kid.player.seeks.last, const Duration(seconds: 40));
    await tester.tap(find.byKey(const Key('kid-seek-back')));
    await tester.tap(find.byKey(const Key('kid-seek-back')));
    await tester.pump();
    expect(kid.player.seeks.last, const Duration(seconds: 20));

    // Never past the start, and never onto the very end.
    kid.player.emitPosition(
      const Duration(seconds: 4),
      const Duration(minutes: 2),
    );
    await tester.tap(find.byKey(const Key('kid-seek-back')));
    expect(kid.player.seeks.last, Duration.zero);
    kid.player.emitPosition(
      const Duration(seconds: 115),
      const Duration(minutes: 2),
    );
    await tester.tap(find.byKey(const Key('kid-seek-forward')));
    expect(kid.player.seeks.last, const Duration(seconds: 119));

    // Drag the bar to about three quarters.
    final bar = find.byKey(const Key('kid-seek-bar'));
    final rect = tester.getRect(bar);
    await tester.tapAt(Offset(rect.left + rect.width * 0.75, rect.center.dy));
    await tester.pumpAndSettle();
    expect(kid.player.seeks.last.inSeconds, inInclusiveRange(80, 100));
  });

  testWidgets('no seeking while the last video finishes after time is up', (
    tester,
  ) async {
    final clock = FakeClock();
    final kid = await _pumpInKidMode(
      tester,
      clock,
      limit: const Duration(minutes: 1),
      end: EndBehaviour.finishVideo,
    );
    kid.player
      ..emit(const PlayerPlaying())
      ..emitPosition(const Duration(seconds: 30), const Duration(minutes: 5));
    await _elapse(tester, clock, const Duration(seconds: 61));
    expect(find.text('Last video!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('kid-seek-back')));
    await tester.pump();
    final bar = find.byKey(const Key('kid-seek-bar'));
    await tester.tapAt(tester.getCenter(bar));
    await tester.pump();
    expect(kid.player.seeks, isEmpty);
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

  group('full screen', () {
    Future<List<MethodCall>> recordPlatformCalls(WidgetTester tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return calls;
    }

    List<Object?> orientations(List<MethodCall> calls) => [
      for (final c in calls)
        if (c.method == 'SystemChrome.setPreferredOrientations') c.arguments,
    ];

    void phone(WidgetTester tester, {Size physical = const Size(2400, 1080)}) {
      // A typical 20:9 phone in landscape: 873 x 393 logical pixels.
      tester.view.physicalSize = physical;
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
    }

    testWidgets('enter and leave full screen without reloading the video', (
      tester,
    ) async {
      final calls = await recordPlatformCalls(tester);
      final clock = FakeClock();
      final kid = await _pumpInKidMode(tester, clock);
      final loadsBefore = kid.player.loaded.length;

      await tester.tap(find.byKey(const Key('kid-fullscreen')));
      await tester.pumpAndSettle();
      expect(find.byType(KidFullscreenView), findsOneWidget);
      expect(find.byKey(const Key('fake-player')), findsOneWidget);
      expect(orientations(calls).last, [
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);

      await tester.tap(find.byKey(const Key('kid-exit-fullscreen')));
      await tester.pumpAndSettle();
      expect(find.byType(KidFullscreenView), findsNothing);
      expect(find.byType(KidModeScreen), findsOneWidget);
      expect(kid.player.loaded.length, loadsBefore, reason: 'no reload');
    });

    testWidgets('back leaves full screen, but never Kid mode', (tester) async {
      phone(tester);
      final calls = await recordPlatformCalls(tester);
      final clock = FakeClock();
      await _pumpInKidMode(tester, clock);
      await tester.tap(find.byKey(const Key('kid-fullscreen')));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(KidFullscreenView), findsNothing);
      expect(find.byType(KidModeScreen), findsOneWidget);
      // Phones go back to portrait, so leaving full screen is obvious.
      expect(orientations(calls).last, ['DeviceOrientation.portraitUp']);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(KidModeScreen), findsOneWidget);
    });

    /// Landscape screens: a 20:9 phone, the same with a camera cutout
    /// (safe-area inset), and a 16:9 phone that has no natural side bars.
    const screens = {
      '20:9 phone': (Size(2400, 1080), 2.75, 0.0),
      '20:9 phone with cutout': (Size(2400, 1080), 2.75, 80.0),
      '16:9 phone': (Size(1920, 1080), 3.0, 0.0),
    };
    const controls = [
      'kid-play-pause',
      'kid-next',
      'kid-seek-toggle',
      'kid-pick-video',
      'kid-exit-fullscreen',
      'kid-countdown',
    ];

    for (final MapEntry(key: name, value: (size, dpr, inset))
        in screens.entries) {
      testWidgets('$name: every control and the countdown stay visible, '
          'beside the video', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = dpr;
        tester.view.padding = FakeViewPadding(left: inset * dpr);
        addTearDown(tester.view.reset);
        final clock = FakeClock();
        final kid = await _pumpInKidMode(tester, clock);
        await tester.tap(find.byKey(const Key('kid-fullscreen')));
        await tester.pumpAndSettle();

        // Long after any auto-hide would have kicked in.
        await _elapse(tester, clock, const Duration(seconds: 30));
        final screen = Offset.zero & (size / dpr);
        final video = tester.getRect(find.byKey(const Key('fake-player')));
        expect(video.width, greaterThan(200));
        for (final key in controls) {
          final finder = find.byKey(Key(key));
          expect(finder, findsOneWidget, reason: key);
          final r = tester.getRect(finder);
          expect(video.overlaps(r), isFalse, reason: '$key covers the video');
          expect(
            r.left,
            greaterThanOrEqualTo(video.right),
            reason: '$key is not on the right-hand panel',
          );
          expect(screen.contains(r.center), isTrue, reason: '$key off screen');
          expect(r.left, greaterThanOrEqualTo(inset), reason: '$key in cutout');
        }

        // No parent lock in full screen: leave full screen first.
        expect(find.byKey(const Key('kid-exit-button')), findsNothing);

        // The panel is symmetric about its centre line.
        double centreX(String key) => tester.getCenter(find.byKey(Key(key))).dx;
        final axis = centreX('kid-countdown');
        expect(centreX('kid-exit-fullscreen'), closeTo(axis, 0.5));
        expect(
          (centreX('kid-play-pause') + centreX('kid-next')) / 2,
          closeTo(axis, 0.5),
        );
        expect(
          (centreX('kid-seek-toggle') + centreX('kid-pick-video')) / 2,
          closeTo(axis, 0.5),
        );
        expect(
          centreX('kid-play-pause'),
          closeTo(centreX('kid-seek-toggle'), 0.5),
        );

        // Play, then pause ("stop").
        await tester.tap(find.byKey(const Key('kid-play-pause')));
        await tester.pump();
        expect(kid.player.plays, 1);
        await tester.tap(find.byKey(const Key('kid-play-pause')));
        await tester.pump();
        expect(kid.player.pauses, greaterThanOrEqualTo(1));

        // Next video.
        await tester.tap(find.byKey(const Key('kid-next')));
        await tester.pump();
        expect(kid.player.loaded.last, ('bbbbbbbbbbb', true));

        // The seek strip is hidden until asked for.
        expect(find.byKey(const Key('kid-seek-strip')), findsNothing);
        expect(find.byKey(const Key('kid-seek-back')), findsNothing);
        final loadsBefore = kid.player.loaded.length;
        await tester.tap(find.byKey(const Key('kid-seek-toggle')));
        await tester.pumpAndSettle();
        final strip = tester.getRect(find.byKey(const Key('kid-seek-strip')));
        final smaller = tester.getRect(find.byKey(const Key('fake-player')));
        expect(strip.overlaps(smaller), isFalse, reason: 'strip covers video');
        expect(strip.top, greaterThanOrEqualTo(smaller.bottom));
        expect(strip.right, lessThanOrEqualTo(video.right + 1));
        expect(
          screen.contains(strip.bottomCenter - const Offset(0, 1)),
          isTrue,
        );
        expect(smaller.height, lessThanOrEqualTo(video.height));
        expect(kid.player.loaded.length, loadsBefore, reason: 'no reload');

        // Back and forward 10 seconds, and the bar.
        kid.player.emitPosition(
          const Duration(seconds: 50),
          const Duration(minutes: 3),
        );
        await tester.tap(find.byKey(const Key('kid-seek-back')));
        expect(kid.player.seeks.last, const Duration(seconds: 40));
        await tester.tap(find.byKey(const Key('kid-seek-forward')));
        expect(kid.player.seeks.last, const Duration(seconds: 50));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tapAt(
          tester.getCenter(find.byKey(const Key('kid-seek-bar'))),
        );
        await tester.pumpAndSettle();
        expect(kid.player.seeks.last.inSeconds, inInclusiveRange(80, 100));

        // Hide it again: the video gets its room back.
        await tester.tap(find.byKey(const Key('kid-seek-toggle')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('kid-seek-strip')), findsNothing);
        expect(tester.getRect(find.byKey(const Key('fake-player'))), video);

        // Pick a video from the thumbnails.
        await tester.tap(find.byKey(const Key('kid-pick-video')));
        await tester.pumpAndSettle();
        // The picker replaces the panel; nothing is drawn over the video.
        final pickerRect = tester.getRect(
          find.byKey(const Key('kid-video-picker')),
        );
        expect(pickerRect.overlaps(video), isFalse);
        expect(
          tester.getRect(find.byKey(const Key('fake-player'))),
          video,
          reason: 'the video stays put',
        );
        // Close without choosing, then open again and choose.
        await tester.tap(find.byKey(const Key('kid-close-picker')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('kid-video-picker')), findsNothing);
        await tester.tap(find.byKey(const Key('kid-pick-video')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('kid-thumb-0')));
        await tester.pumpAndSettle();
        expect(kid.player.loaded.last, ('aaaaaaaaaaa', true));
        expect(find.byKey(const Key('kid-video-picker')), findsNothing);

        // Go back to the normal view.
        await tester.tap(find.byKey(const Key('kid-exit-fullscreen')));
        await tester.pumpAndSettle();
        expect(find.byType(KidFullscreenView), findsNothing);
        expect(find.byType(KidModeScreen), findsOneWidget);
      });
    }

    testWidgets('the countdown shows minutes, then m:ss in the last minute', (
      tester,
    ) async {
      final clock = FakeClock();
      await _pumpInKidMode(tester, clock, limit: const Duration(minutes: 3));
      await tester.tap(find.byKey(const Key('kid-fullscreen')));
      await tester.pumpAndSettle();
      Finder inCountdown(String text) => find.descendant(
        of: find.byKey(const Key('kid-countdown')),
        matching: find.text(text),
      );
      expect(inCountdown('3'), findsOneWidget);
      await _elapse(tester, clock, const Duration(minutes: 2, seconds: 15));
      expect(inCountdown('0:45'), findsOneWidget);
    });
    testWidgets("time's up leaves full screen", (tester) async {
      final calls = await recordPlatformCalls(tester);
      final clock = FakeClock();
      await _pumpInKidMode(tester, clock, limit: const Duration(minutes: 1));
      await tester.tap(find.byKey(const Key('kid-fullscreen')));
      await tester.pumpAndSettle();

      await _elapse(tester, clock, const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(find.text('All done for now!'), findsOneWidget);
      expect(orientations(calls).last, isEmpty);
    });
  });
}

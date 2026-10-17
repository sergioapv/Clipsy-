import 'package:clipsy/core/storage/storage_providers.dart';
import 'package:clipsy/core/utils/clock.dart';
import 'package:clipsy/features/kid_mode/data/kid_mode_storage.dart';
import 'package:clipsy/features/kid_mode/domain/kid_player.dart';
import 'package:clipsy/features/kid_mode/domain/kid_session.dart';
import 'package:clipsy/features/kid_mode/domain/kid_settings.dart';
import 'package:clipsy/features/kid_mode/presentation/kid_mode_controller.dart';
import 'package:clipsy/features/playlists/domain/playlist.dart';
import 'package:clipsy/features/playlists/presentation/playlist_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_kid_mode.dart';
import '../../helpers/fake_playlists.dart';

PlaylistDetail _detail({int videos = 3, bool firstUnavailable = false}) =>
    PlaylistDetail(
      playlist: const Playlist(
        id: 'p1',
        ownerId: 'u1',
        title: 'Space',
        ageRange: AgeRange.fallback,
      ),
      videos: [
        for (var i = 0; i < videos; i++)
          PlaylistVideo(
            id: 'row$i',
            playlistId: 'p1',
            youtubeVideoId: 'v$i'.padRight(11, 'x'),
            title: 'Video $i',
            position: i,
            isAvailable: !(firstUnavailable && i == 0),
          ),
      ],
    );

void main() {
  late FakeClock clock;
  late FakeDeviceLock lock;
  late FakePlaylistRepository playlists;
  late SharedPreferences prefs;

  Future<ProviderContainer> makeContainer({
    KidModeSettings settings = const KidModeSettings(),
  }) async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(clock.call),
        deviceLockProvider.overrideWithValue(lock),
        playlistRepositoryProvider.overrideWithValue(playlists),
      ],
    );
    addTearDown(container.dispose);
    await container.read(kidSettingsProvider.notifier).save(settings);
    return container;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    clock = FakeClock();
    lock = FakeDeviceLock();
    playlists = FakePlaylistRepository();
  });

  KidModeState? read(ProviderContainer c) => c.read(kidModeProvider);
  KidMode ctl(ProviderContainer c) => c.read(kidModeProvider.notifier);

  void tickFor(ProviderContainer c, Duration d) {
    final end = clock.now.add(d);
    while (clock.now.isBefore(end)) {
      clock.advance(const Duration(seconds: 1));
      ctl(c).tick();
    }
  }

  test('start snapshots available videos and persists the session', () async {
    final c = await makeContainer();
    expect(read(c), isNull);
    await ctl(c).start(
      detail: _detail(firstUnavailable: true),
      limit: const Duration(minutes: 10),
    );
    final s = read(c)!;
    expect(s.session.videos.map((v) => v.title), ['Video 1', 'Video 2']);
    expect(s.remaining, const Duration(minutes: 10));
    expect(s.loadRequest, 1);
    expect(KidSessionStore(prefs).load()!.playlistId, 'p1');
  });

  test('refuses a playlist with nothing playable', () async {
    final c = await makeContainer();
    expect(
      () => ctl(c)
          .start(detail: _detail(videos: 0), limit: const Duration(minutes: 5)),
      throwsStateError,
    );
  });

  test('wall clock: almost done, then time up pauses the clock', () async {
    final c = await makeContainer();
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 2));
    ctl(c).onPlayerEvent(const PlayerPlaying());

    tickFor(c, const Duration(seconds: 59));
    expect(read(c)!.isAlmostDone, isFalse);
    tickFor(c, const Duration(seconds: 2));
    expect(read(c)!.isAlmostDone, isTrue);
    tickFor(c, const Duration(seconds: 60));
    final s = read(c)!;
    expect(s.session.status, KidSessionStatus.timeUp);
    expect(s.session.clock.isRunning, isFalse);
    expect(KidSessionStore(prefs).load()!.status, KidSessionStatus.timeUp);

    // Taps on thumbnails do nothing once time is up.
    ctl(c).select(2);
    expect(read(c)!.session.currentIndex, 0);
  });

  test('playback mode only counts while playing', () async {
    final c = await makeContainer(
      settings: const KidModeSettings(timerMode: TimerMode.playback),
    );
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 1));
    tickFor(c, const Duration(minutes: 5));
    expect(read(c)!.remaining, const Duration(minutes: 1));

    ctl(c).onPlayerEvent(const PlayerPlaying());
    tickFor(c, const Duration(seconds: 30));
    ctl(c).onPlayerEvent(const PlayerPaused());
    tickFor(c, const Duration(minutes: 5));
    expect(read(c)!.remaining, const Duration(seconds: 30));
    expect(read(c)!.session.status, KidSessionStatus.watching);
  });

  test(
    'autoplays the next video and stops at the end of the playlist',
    () async {
      final c = await makeContainer();
      await ctl(
        c,
      ).start(detail: _detail(videos: 2), limit: const Duration(minutes: 30));
      ctl(c).onPlayerEvent(const PlayerEnded());
      expect(read(c)!.session.currentIndex, 1);
      expect(read(c)!.autoplay, isTrue);
      expect(read(c)!.loadRequest, 2);

      ctl(c).onPlayerEvent(const PlayerEnded());
      expect(read(c)!.session.currentIndex, 0);
      expect(read(c)!.autoplay, isFalse, reason: 'waits for a tap');
    },
  );

  test('a video that fails to play is skipped', () async {
    final c = await makeContainer();
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 30));
    ctl(c).onPlayerEvent(const PlayerFailed(150));
    expect(read(c)!.session.currentIndex, 1);
  });

  test('finish-video mode lets the video end, then stops', () async {
    final c = await makeContainer(
      settings: const KidModeSettings(endBehaviour: EndBehaviour.finishVideo),
    );
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 1));
    ctl(c).onPlayerEvent(const PlayerPlaying());
    tickFor(c, const Duration(seconds: 61));
    expect(read(c)!.session.status, KidSessionStatus.finishingVideo);

    ctl(c).select(2);
    expect(read(c)!.session.currentIndex, 0, reason: 'no new videos');

    ctl(c).onPlayerEvent(const PlayerEnded());
    expect(read(c)!.session.status, KidSessionStatus.timeUp);
    expect(read(c)!.session.currentIndex, 0, reason: 'no autoplay');
  });

  test('finish-video mode is capped, and pausing ends it', () async {
    final c = await makeContainer(
      settings: const KidModeSettings(endBehaviour: EndBehaviour.finishVideo),
    );
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 1));
    ctl(c).onPlayerEvent(const PlayerPlaying());
    tickFor(c, const Duration(seconds: 61));
    tickFor(c, KidModeSettings.maxOverrun);
    expect(read(c)!.session.status, KidSessionStatus.timeUp);

    final c2 = await makeContainer(
      settings: const KidModeSettings(endBehaviour: EndBehaviour.finishVideo),
    );
    await ctl(c2).start(detail: _detail(), limit: const Duration(minutes: 1));
    ctl(c2).onPlayerEvent(const PlayerPlaying());
    tickFor(c2, const Duration(seconds: 61));
    ctl(c2).onPlayerEvent(const PlayerPaused());
    expect(read(c2)!.session.status, KidSessionStatus.timeUp);
  });

  test('hard stop ignores a playing video', () async {
    final c = await makeContainer();
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 1));
    ctl(c).onPlayerEvent(const PlayerPlaying());
    tickFor(c, const Duration(seconds: 61));
    expect(read(c)!.session.status, KidSessionStatus.timeUp);
  });

  test('extend after time up gives exactly the extra time', () async {
    final c = await makeContainer();
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 1));
    tickFor(c, const Duration(seconds: 61));
    // The "All done" screen stays up for a while.
    clock.advance(const Duration(minutes: 30));
    await ctl(c).extend(const Duration(minutes: 5));
    final s = read(c)!;
    expect(s.session.status, KidSessionStatus.watching);
    expect(s.remaining, const Duration(minutes: 5));
    tickFor(c, const Duration(minutes: 1));
    expect(read(c)!.remaining, const Duration(minutes: 4));
  });

  test('exit clears the session, unpins and unlocks parent mode', () async {
    final c = await makeContainer();
    lock.pinned = true;
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 10));
    await ctl(c).exit();
    expect(read(c), isNull);
    expect(KidSessionStore(prefs).load(), isNull);
    expect(lock.pinned, isFalse);
  });

  test(
    'a restart resumes the session; wall-clock time kept counting',
    () async {
      final c = await makeContainer();
      await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 10));
      tickFor(c, const Duration(minutes: 3));
      c.dispose();

      // App killed for 4 minutes.
      clock.advance(const Duration(minutes: 4));
      final restarted = await makeContainer();
      final s = read(restarted)!;
      expect(s.session.playlistTitle, 'Space');
      expect(s.session.clock.remaining(clock.now), const Duration(minutes: 3));
    },
  );

  test('a restart in playback mode does not count the dead time', () async {
    const settings = KidModeSettings(timerMode: TimerMode.playback);
    final c = await makeContainer(settings: settings);
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 10));
    ctl(c).onPlayerEvent(const PlayerPlaying());
    tickFor(c, const Duration(minutes: 2));
    c.dispose();

    clock.advance(const Duration(hours: 1));
    final restarted = await makeContainer(settings: settings);
    final remaining = read(restarted)!.session.clock.remaining(clock.now);
    // Lost at most one checkpoint interval.
    expect(remaining, greaterThanOrEqualTo(const Duration(minutes: 8)));
    expect(
      remaining,
      lessThanOrEqualTo(const Duration(minutes: 8) + KidMode.checkpointEvery),
    );
  });

  test('records a video duration once, best effort', () async {
    final c = await makeContainer();
    await ctl(c).start(detail: _detail(), limit: const Duration(minutes: 10));
    ctl(c).onPlayerEvent(const PlayerDurationKnown(125));
    await Future<void>.delayed(Duration.zero);
    expect(playlists.durations, {'row0': 125});
    expect(read(c)!.session.videos.first.durationSeconds, 125);

    ctl(c).onPlayerEvent(const PlayerDurationKnown(130));
    await Future<void>.delayed(Duration.zero);
    expect(playlists.durations['row0'], 125, reason: 'only the first time');
  });
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/clock.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../playlists/domain/playlist.dart';
import '../../playlists/presentation/playlist_providers.dart';
import '../data/device_lock.dart';
import '../data/kid_mode_storage.dart';
import '../data/youtube_kid_player.dart';
import '../domain/kid_player.dart';
import '../domain/kid_session.dart';
import '../domain/kid_settings.dart';
import '../domain/screen_time.dart';

part 'kid_mode_controller.g.dart';

@Riverpod(keepAlive: true)
KidSettingsRepository kidSettingsRepository(Ref ref) =>
    KidSettingsRepository(ref.watch(sharedPreferencesProvider));

@Riverpod(keepAlive: true)
KidSessionStore kidSessionStore(Ref ref) =>
    KidSessionStore(ref.watch(sharedPreferencesProvider));

@Riverpod(keepAlive: true)
DeviceLock deviceLock(Ref ref) => const PlatformDeviceLock();

/// The player for the Kid mode screen; disposed with it.
@riverpod
KidPlayer kidPlayer(Ref ref) {
  final player = YoutubeKidPlayer();
  ref.onDispose(player.dispose);
  return player;
}

@Riverpod(keepAlive: true)
class KidSettings extends _$KidSettings {
  @override
  KidModeSettings build() => ref.watch(kidSettingsRepositoryProvider).load();

  Future<void> save(KidModeSettings settings) async {
    await ref.read(kidSettingsRepositoryProvider).save(settings);
    state = settings;
  }
}

/// What the Kid mode screen renders.
@immutable
class KidModeState {
  const KidModeState({
    required this.session,
    required this.now,
    this.loadRequest = 0,
    this.autoplay = false,
    this.isPlaying = false,
  });

  final KidSession session;

  /// Time of the last tick; drives the countdown display.
  final DateTime now;

  /// Bumped whenever the screen should (re)load [KidSession.currentVideo].
  final int loadRequest;
  final bool autoplay;
  final bool isPlaying;

  Duration get remaining => session.clock.remaining(now);
  bool get isAlmostDone =>
      session.status == KidSessionStatus.watching &&
      session.clock.isAlmostDone(now);

  KidModeState copyWith({
    KidSession? session,
    DateTime? now,
    int? loadRequest,
    bool? autoplay,
    bool? isPlaying,
  }) => KidModeState(
    session: session ?? this.session,
    now: now ?? this.now,
    loadRequest: loadRequest ?? this.loadRequest,
    autoplay: autoplay ?? this.autoplay,
    isPlaying: isPlaying ?? this.isPlaying,
  );
}

/// The active Kid mode session (or `null` in parent mode).
///
/// Every change is persisted, so killing the app resumes Kid mode with the
/// same remaining time.
@Riverpod(keepAlive: true)
class KidMode extends _$KidMode {
  static const checkpointEvery = Duration(seconds: 5);

  DateTime? _lastCheckpoint;

  DateTime get _now => ref.read(clockProvider)();
  KidSessionStore get _store => ref.read(kidSessionStoreProvider);

  @override
  KidModeState? build() {
    final saved = _store.load();
    if (saved == null) return null;
    return KidModeState(
      session: saved.copyWith(clock: saved.clock.restore()),
      now: _now,
    );
  }

  /// Starts Kid mode on [detail]'s available videos.
  Future<void> start({
    required PlaylistDetail detail,
    required Duration limit,
  }) async {
    final videos = [
      for (final v in detail.videos)
        if (v.isAvailable) KidVideo.fromPlaylistVideo(v),
    ];
    if (videos.isEmpty) throw StateError('Playlist has no playable videos');
    final settings = ref.read(kidSettingsProvider);
    final now = _now;
    final session = KidSession(
      playlistId: detail.playlist.id,
      playlistTitle: detail.playlist.title,
      videos: videos,
      clock: ScreenTimeClock.start(
        limit: limit,
        mode: settings.timerMode,
        now: now,
      ),
      endBehaviour: settings.endBehaviour,
      startedAt: now,
    );
    state = KidModeState(session: session, now: now, loadRequest: 1);
    await _persist();
  }

  // -- Player events ---------------------------------------------------------

  void onPlayerEvent(KidPlayerEvent event) {
    final s = state;
    if (s == null) return;
    switch (event) {
      case PlayerPlaying():
        if (s.session.isTimeUp) return;
        _update(
          s.copyWith(
            isPlaying: true,
            session: s.session.copyWith(clock: s.session.clock.resume(_now)),
          ),
          playbackOnly: true,
        );
      case PlayerPaused()
          when s.session.status == KidSessionStatus.finishingVideo:
        // Pausing during the last video ends the session, so the overrun
        // can't be stretched.
        _timeUp();
      case PlayerPaused():
        _update(
          s.copyWith(
            isPlaying: false,
            session: s.session.copyWith(clock: s.session.clock.pause(_now)),
          ),
          playbackOnly: true,
        );
      case PlayerEnded():
        if (s.session.status == KidSessionStatus.finishingVideo) {
          _timeUp();
        } else {
          _advance(s.copyWith(isPlaying: false));
        }
      case PlayerFailed():
        switch (s.session.status) {
          case KidSessionStatus.watching:
            // Skip videos that can no longer be played.
            _advance(s.copyWith(isPlaying: false));
          case KidSessionStatus.finishingVideo:
            _timeUp();
          case KidSessionStatus.timeUp:
            break;
        }
      case PlayerDurationKnown(:final seconds):
        _recordDuration(seconds);
    }
  }

  /// Clock changes from play/pause only matter in playback mode; in
  /// wall-clock mode the clock runs regardless.
  void _update(KidModeState next, {bool playbackOnly = false}) {
    final mode = next.session.clock.mode;
    if (playbackOnly && mode == TimerMode.wallClock) {
      final current = state!;
      state = next.copyWith(session: current.session);
      return;
    }
    state = next;
    unawaited(_persist());
  }

  void _advance(KidModeState s) {
    final session = s.session;
    final clock = session.clock.mode == TimerMode.playback
        ? session.clock.pause(_now)
        : session.clock;
    final next = session.currentIndex + 1;
    if (next < session.videos.length) {
      state = s.copyWith(
        session: session.copyWith(currentIndex: next, clock: clock),
        loadRequest: s.loadRequest + 1,
        autoplay: true,
      );
    } else {
      // End of the playlist: back to the first video, waiting for a tap.
      state = s.copyWith(
        session: session.copyWith(currentIndex: 0, clock: clock),
        loadRequest: s.loadRequest + 1,
        autoplay: false,
      );
    }
    unawaited(_persist());
  }

  void _recordDuration(int seconds) {
    final s = state;
    final video = s?.session.currentVideo;
    if (s == null || video == null || video.durationSeconds != null) return;
    final videos = [...s.session.videos];
    videos[s.session.currentIndex] = KidVideo(
      rowId: video.rowId,
      youtubeId: video.youtubeId,
      title: video.title,
      thumbnailUrl: video.thumbnailUrl,
      durationSeconds: seconds,
    );
    state = s.copyWith(session: s.session.copyWith(videos: videos));
    unawaited(_persist());
    // Best effort: offline or signed out simply means it's recorded later.
    unawaited(
      ref
          .read(playlistRepositoryProvider)
          .recordDuration(video.rowId, seconds)
          .catchError((Object _) {}),
    );
  }

  // -- Kid actions ---------------------------------------------------------

  /// The child tapped a thumbnail.
  void select(int index) {
    final s = state;
    if (s == null || s.session.status != KidSessionStatus.watching) return;
    if (index < 0 || index >= s.session.videos.length) return;
    state = s.copyWith(
      session: s.session.copyWith(currentIndex: index),
      loadRequest: s.loadRequest + 1,
      autoplay: true,
    );
    unawaited(_persist());
  }

  // -- Time --------------------------------------------------------------

  /// Called every second by the Kid mode screen.
  void tick() {
    final s = state;
    if (s == null) return;
    final now = _now;
    final session = s.session;
    switch (session.status) {
      case KidSessionStatus.watching when session.clock.isUp(now):
        if (session.endBehaviour == EndBehaviour.finishVideo && s.isPlaying) {
          state = s.copyWith(
            now: now,
            session: session.copyWith(status: KidSessionStatus.finishingVideo),
          );
          unawaited(_persist());
        } else {
          _timeUp();
        }
      case KidSessionStatus.finishingVideo
          when session.clock.overrun(now) >= KidModeSettings.maxOverrun:
        _timeUp();
      case _:
        state = s.copyWith(now: now);
        final last = _lastCheckpoint;
        if (session.clock.isRunning &&
            (last == null || now.difference(last) >= checkpointEvery)) {
          _lastCheckpoint = now;
          state = state!.copyWith(
            session: session.copyWith(clock: session.clock.checkpoint(now)),
          );
          unawaited(_persist());
        }
    }
  }

  void _timeUp() {
    final s = state!;
    final now = _now;
    state = s.copyWith(
      now: now,
      isPlaying: false,
      session: s.session.copyWith(
        status: KidSessionStatus.timeUp,
        clock: s.session.clock.pause(now).stopAtLimit(),
      ),
    );
    unawaited(_persist());
  }

  // -- Parent actions (after the PIN) -------------------------------------

  Future<void> extend(Duration extra) async {
    final s = state;
    if (s == null) return;
    final now = _now;
    var clock = s.session.clock.extend(extra);
    if (clock.mode == TimerMode.wallClock) clock = clock.resume(now);
    state = s.copyWith(
      now: now,
      session: s.session.copyWith(
        clock: clock,
        status: KidSessionStatus.watching,
      ),
    );
    await _persist();
  }

  /// Ends Kid mode and returns to (unlocked) parent mode.
  Future<void> exit() async {
    await _store.clear();
    await ref.read(deviceLockProvider).stopPinning();
    // The parent just proved the PIN; don't ask again.
    ref.read(parentSessionProvider.notifier).markUnlocked();
    state = null;
  }

  Future<void> _persist() async {
    final s = state;
    if (s != null) await _store.save(s.session);
  }
}

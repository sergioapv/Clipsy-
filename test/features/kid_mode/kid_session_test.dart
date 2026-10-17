import 'package:clipsy/features/kid_mode/data/kid_mode_storage.dart';
import 'package:clipsy/features/kid_mode/domain/kid_navigation_policy.dart';
import 'package:clipsy/features/kid_mode/domain/kid_session.dart';
import 'package:clipsy/features/kid_mode/domain/kid_settings.dart';
import 'package:clipsy/features/kid_mode/domain/screen_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 17, 9);
  final session = KidSession(
    playlistId: 'p1',
    playlistTitle: 'Space',
    videos: const [
      KidVideo(rowId: 'v1', youtubeId: 'aaaaaaaaaaa', title: 'A'),
      KidVideo(
        rowId: 'v2',
        youtubeId: 'bbbbbbbbbbb',
        title: 'B',
        durationSeconds: 60,
      ),
    ],
    clock: ScreenTimeClock.start(
      limit: const Duration(minutes: 20),
      mode: TimerMode.wallClock,
      now: t0,
    ),
    endBehaviour: EndBehaviour.finishVideo,
    startedAt: t0,
    currentIndex: 1,
    status: KidSessionStatus.finishingVideo,
  );

  test('session survives a JSON round trip', () {
    final copy = KidSession.fromJson(session.toJson());
    expect(copy.playlistId, 'p1');
    expect(copy.videos.map((v) => v.youtubeId), ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
    expect(copy.videos[1].durationSeconds, 60);
    expect(copy.currentIndex, 1);
    expect(copy.currentVideo!.title, 'B');
    expect(copy.status, KidSessionStatus.finishingVideo);
    expect(copy.endBehaviour, EndBehaviour.finishVideo);
    expect(copy.clock.runningSince, t0);
  });

  group('storage', () {
    test('saves, loads and clears the session', () async {
      SharedPreferences.setMockInitialValues({});
      final store = KidSessionStore(await SharedPreferences.getInstance());
      expect(store.load(), isNull);
      await store.save(session);
      expect(store.load()!.playlistTitle, 'Space');
      await store.clear();
      expect(store.load(), isNull);
    });

    test('a corrupt session is ignored instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        KidSessionStore.key: '{"nope":1',
      });
      final store = KidSessionStore(await SharedPreferences.getInstance());
      expect(store.load(), isNull);
    });

    test('settings default and round trip', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = KidSettingsRepository(await SharedPreferences.getInstance());
      expect(repo.load(), const KidModeSettings());
      const custom = KidModeSettings(
        defaultLimit: Duration(minutes: 45),
        timerMode: TimerMode.playback,
        endBehaviour: EndBehaviour.finishVideo,
        exitHold: Duration(seconds: 5),
      );
      await repo.save(custom);
      expect(repo.load(), custom);
    });
  });

  group('KidNavigationPolicy', () {
    final base = Uri.parse('https://www.youtube-nocookie.com');
    bool allows(String url) =>
        KidNavigationPolicy.allows(Uri.tryParse(url), playerBaseUrl: base);

    test('allows the player page and embeds', () {
      expect(allows('https://www.youtube-nocookie.com'), isTrue);
      expect(allows('https://www.youtube-nocookie.com/'), isTrue);
      expect(allows('about:blank'), isTrue);
      expect(
        allows('https://www.youtube-nocookie.com/embed/aaaaaaaaaaa?rel=0'),
        isTrue,
      );
      expect(allows('https://www.youtube.com/embed/aaaaaaaaaaa'), isTrue);
    });

    test('blocks every way out', () {
      for (final url in [
        'https://www.youtube.com/watch?v=aaaaaaaaaaa&feature=emb_logo',
        'https://www.youtube.com/watch?v=bbbbbbbbbbb&feature=emb_rel_end',
        'https://youtu.be/aaaaaaaaaaa',
        'https://www.youtube.com/channel/UC123',
        'https://www.youtube.com/@channel',
        'https://m.youtube.com/',
        'https://googleads.g.doubleclick.net/pagead/aclk?x=1',
        'https://www.youtube-nocookie.com/watch?v=aaaaaaaaaaa',
        'intent://youtube.com/watch#Intent;scheme=vnd.youtube;end',
        'vnd.youtube:aaaaaaaaaaa',
        'http://www.youtube.com/embed/aaaaaaaaaaa',
        'https://evil.example/embed/aaaaaaaaaaa',
      ]) {
        expect(allows(url), isFalse, reason: url);
      }
      expect(KidNavigationPolicy.allows(null, playerBaseUrl: base), isFalse);
    });
  });
}

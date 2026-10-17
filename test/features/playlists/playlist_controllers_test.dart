import 'package:clipsy/features/playlists/domain/playlist.dart';
import 'package:clipsy/features/playlists/domain/playlist_exception.dart';
import 'package:clipsy/features/playlists/domain/video_metadata.dart';
import 'package:clipsy/features/playlists/presentation/playlist_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_playlists.dart';

void main() {
  late FakePlaylistRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakePlaylistRepository();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [playlistRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  VideoMetadata meta(String id) => VideoMetadata(
    videoId: id,
    title: 'T $id',
    thumbnailUrl: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
  );

  group('MyPlaylists', () {
    test('reorders optimistically and persists', () async {
      repo
        ..seed('A')
        ..seed('B')
        ..seed('C');
      final sub = container.listen(myPlaylistsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(myPlaylistsProvider.future);

      await container.read(myPlaylistsProvider.notifier).reorder(0, 2);

      expect(container.read(myPlaylistsProvider).value!.map((p) => p.title), [
        'B',
        'C',
        'A',
      ]);
      expect(repo.playlists.map((p) => p.title), ['B', 'C', 'A']);
    });

    test('rolls back a failed reorder', () async {
      repo
        ..seed('A')
        ..seed('B');
      final sub = container.listen(myPlaylistsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(myPlaylistsProvider.future);

      repo.failNext = const PlaylistException(PlaylistError.network);
      await expectLater(
        container.read(myPlaylistsProvider.notifier).reorder(0, 1),
        throwsA(isA<PlaylistException>()),
      );
      expect(container.read(myPlaylistsProvider).value!.map((p) => p.title), [
        'A',
        'B',
      ]);
    });

    test('create adds to the library and delete removes', () async {
      final sub = container.listen(myPlaylistsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(myPlaylistsProvider.future);
      final notifier = container.read(myPlaylistsProvider.notifier);

      final id = await notifier.create(const PlaylistDraft(title: ' New '));
      final afterCreate = await container.read(myPlaylistsProvider.future);
      expect(afterCreate.single.title, 'New');

      await notifier.delete(id);
      expect(container.read(myPlaylistsProvider).value, isEmpty);
      expect(repo.playlists, isEmpty);
    });
  });

  group('PlaylistDetailController', () {
    late String id;
    late PlaylistDetailControllerProvider provider;

    setUp(() async {
      id = repo.seed('Space', videoIds: ['aaaaaaaaaaa', 'bbbbbbbbbbb']).id;
      provider = playlistDetailControllerProvider(id);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container.read(provider.future);
    });

    List<String> shown() => [
      for (final v in container.read(provider).value!.videos) v.youtubeVideoId,
    ];

    test('adds videos at the end', () async {
      await container.read(provider.notifier).addVideo(meta('ccccccccccc'));
      expect(shown(), ['aaaaaaaaaaa', 'bbbbbbbbbbb', 'ccccccccccc']);
      expect(repo.videoIdsOf(id).last, 'ccccccccccc');
      expect(container.read(provider).value!.playlist.videoCount, 3);
      expect(container.read(provider.notifier).contains('ccccccccccc'), isTrue);
    });

    test('remove then undo restores the original position', () async {
      final notifier = container.read(provider.notifier);
      final first = container.read(provider).value!.videos.first;

      final index = await notifier.removeVideo(first);
      expect(index, 0);
      expect(shown(), ['bbbbbbbbbbb']);
      expect(repo.videoIdsOf(id), ['bbbbbbbbbbb']);

      await notifier.restoreVideo(first, index);
      expect(shown(), ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
      expect(repo.videoIdsOf(id), ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
    });

    test('failed removal puts the video back', () async {
      repo.failNext = const PlaylistException(PlaylistError.network);
      final first = container.read(provider).value!.videos.first;
      await expectLater(
        container.read(provider.notifier).removeVideo(first),
        throwsA(isA<PlaylistException>()),
      );
      expect(shown(), ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
    });

    test('reorders and updates the cover', () async {
      await container.read(provider.notifier).reorder(1, 0);
      expect(shown(), ['bbbbbbbbbbb', 'aaaaaaaaaaa']);
      expect(repo.videoIdsOf(id), ['bbbbbbbbbbb', 'aaaaaaaaaaa']);
      expect(
        container.read(provider).value!.playlist.coverUrl,
        contains('bbbbbbbbbbb'),
      );
    });

    test('updateDetails edits the playlist', () async {
      await container
          .read(provider.notifier)
          .updateDetails(
            const PlaylistDraft(
              title: 'Planets',
              ageRange: AgeRange.young,
              labelIds: [1, 4],
            ),
          );
      final p = container.read(provider).value!.playlist;
      expect(p.title, 'Planets');
      expect(p.ageRange, AgeRange.young);
      expect(p.labelIds, [1, 4]);
      expect(repo.playlists.single.title, 'Planets');
    });
  });

  group('PlaylistDraft', () {
    test('validates title, description and labels', () {
      expect(const PlaylistDraft(title: '  ').isValid, isFalse);
      expect(PlaylistDraft(title: 'x' * 81).isValid, isFalse);
      expect(
        PlaylistDraft(title: 'ok', description: 'd' * 501).isValid,
        isFalse,
      );
      expect(
        const PlaylistDraft(title: 'ok', labelIds: [1, 2, 3, 4]).isValid,
        isFalse,
      );
      expect(
        const PlaylistDraft(title: 'ok', labelIds: [1, 2, 3]).isValid,
        isTrue,
      );
      expect(
        const PlaylistDraft(title: 'ok', description: '  ').trimmedDescription,
        isNull,
      );
    });

    test('AgeRange.fromDb clamps out-of-range values', () {
      expect(AgeRange.fromDb(0, 17), const AgeRange(1, 14));
      expect(AgeRange.fromDb(9, 3), const AgeRange(9, 9));
    });
  });
}

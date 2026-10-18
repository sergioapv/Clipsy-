import 'package:clipsy/features/playlists/data/oembed_client.dart';
import 'package:clipsy/features/playlists/data/playlist_repository.dart';
import 'package:clipsy/features/playlists/data/youtube_playlist_repository.dart';
import 'package:clipsy/features/playlists/domain/imported_playlist.dart';
import 'package:clipsy/features/playlists/domain/in_app_browser.dart';
import 'package:clipsy/features/playlists/domain/label.dart';
import 'package:clipsy/features/playlists/domain/playlist.dart';
import 'package:clipsy/features/playlists/domain/playlist_exception.dart';
import 'package:clipsy/features/playlists/domain/video_metadata.dart';
import 'package:clipsy/features/playlists/domain/youtube_url_parser.dart';
import 'package:flutter/widgets.dart';

/// In-memory playlist store that mimics the database rules the UI relies on.
class FakePlaylistRepository implements PlaylistRepository {
  FakePlaylistRepository({this.ownerId = 'u1'});

  final String ownerId;
  final playlists = <Playlist>[];
  final videos = <String, List<PlaylistVideo>>{};
  var _nextId = 0;

  /// Set to make the next call fail.
  PlaylistException? failNext;
  final calls = <String>[];

  void _maybeFail(String call) {
    calls.add(call);
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  Playlist seed(String title, {List<String> videoIds = const []}) {
    final id = 'p${_nextId++}';
    videos[id] = [
      for (final (i, v) in videoIds.indexed)
        PlaylistVideo(
          id: 'v${_nextId++}',
          playlistId: id,
          youtubeVideoId: v,
          title: 'Video $v',
          thumbnailUrl: YouTubeUrlParser.thumbnailUrl(v),
          position: i,
        ),
    ];
    final p = Playlist(
      id: id,
      ownerId: ownerId,
      title: title,
      ageRange: AgeRange.fallback,
      videoCount: videoIds.length,
    );
    playlists.add(p);
    return p;
  }

  Playlist _withCounts(Playlist p) {
    final v = videos[p.id] ?? const [];
    return p.copyWith(
      videoCount: v.length,
      coverUrl: v.firstOrNull?.thumbnailUrl,
    );
  }

  @override
  Future<List<Playlist>> fetchMine() async {
    _maybeFail('fetchMine');
    return [for (final p in playlists) _withCounts(p)];
  }

  @override
  Future<PlaylistDetail> fetchDetail(String id) async {
    _maybeFail('fetchDetail');
    final p = playlists.where((p) => p.id == id).firstOrNull;
    if (p == null) throw const PlaylistException(PlaylistError.notFound);
    final v = [...?videos[id]]
      ..sort((a, b) => a.position.compareTo(b.position));
    return PlaylistDetail(playlist: _withCounts(p), videos: v);
  }

  @override
  Future<String> create(PlaylistDraft draft) async {
    _maybeFail('create');
    final id = 'p${_nextId++}';
    playlists.insert(
      0,
      Playlist(
        id: id,
        ownerId: ownerId,
        title: draft.trimmedTitle,
        description: draft.trimmedDescription,
        ageRange: draft.ageRange,
        labelIds: draft.labelIds,
      ),
    );
    videos[id] = [];
    return id;
  }

  @override
  Future<void> update(String id, PlaylistDraft draft) async {
    _maybeFail('update');
    final i = playlists.indexWhere((p) => p.id == id);
    playlists[i] = playlists[i].copyWith(
      title: draft.trimmedTitle,
      description: draft.trimmedDescription,
      ageRange: draft.ageRange,
      labelIds: draft.labelIds,
    );
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail('delete');
    playlists.removeWhere((p) => p.id == id);
    videos.remove(id);
  }

  @override
  Future<void> reorderMine(List<String> playlistIds) async {
    _maybeFail('reorderMine');
    playlists.sort(
      (a, b) => playlistIds.indexOf(a.id).compareTo(playlistIds.indexOf(b.id)),
    );
  }

  @override
  Future<PlaylistVideo> addVideo(
    String playlistId,
    VideoMetadata video, {
    required int position,
  }) async {
    _maybeFail('addVideo');
    final list = videos[playlistId]!;
    if (list.any((v) => v.youtubeVideoId == video.videoId)) {
      throw const PlaylistException(PlaylistError.duplicateVideo);
    }
    final added = PlaylistVideo(
      id: 'v${_nextId++}',
      playlistId: playlistId,
      youtubeVideoId: video.videoId,
      title: video.title,
      channelName: video.channelName,
      thumbnailUrl: video.thumbnailUrl,
      position: position,
    );
    list.add(added);
    return added;
  }

  @override
  Future<List<PlaylistVideo>> addVideos(
    String playlistId,
    List<VideoMetadata> videos, {
    required int startPosition,
  }) async {
    _maybeFail('addVideos');
    return [
      for (final (i, v) in videos.indexed)
        await addVideo(playlistId, v, position: startPosition + i),
    ];
  }

  @override
  Future<void> removeVideo(String videoId) async {
    _maybeFail('removeVideo');
    for (final list in videos.values) {
      list.removeWhere((v) => v.id == videoId);
    }
  }

  @override
  Future<void> reorderVideos(String playlistId, List<String> videoIds) async {
    _maybeFail('reorderVideos');
    final list = videos[playlistId]!;
    videos[playlistId] = [
      for (final (i, id) in videoIds.indexed)
        () {
          final v = list.firstWhere((v) => v.id == id);
          return PlaylistVideo(
            id: v.id,
            playlistId: v.playlistId,
            youtubeVideoId: v.youtubeVideoId,
            title: v.title,
            channelName: v.channelName,
            thumbnailUrl: v.thumbnailUrl,
            position: i,
          );
        }(),
    ];
  }

  final durations = <String, int>{};

  @override
  Future<void> recordDuration(String videoId, int seconds) async {
    _maybeFail('recordDuration');
    durations[videoId] = seconds;
  }

  List<String> videoIdsOf(String playlistId) => [
    for (final v in [
      ...videos[playlistId]!,
    ]..sort((a, b) => a.position.compareTo(b.position)))
      v.youtubeVideoId,
  ];
}

class FakeLabelRepository implements LabelRepository {
  static const all = [
    Label(id: 1, slug: 'science', name: 'Science'),
    Label(id: 2, slug: 'nature', name: 'Nature'),
    Label(id: 3, slug: 'animals', name: 'Animals'),
    Label(id: 4, slug: 'space', name: 'Space'),
    Label(id: 99, slug: 'robots', name: 'Robots'),
  ];

  @override
  Future<List<Label>> fetchAll() async => all;
}

/// Answers lookups from a fixed table, without parsing or networking quirks.
class FakeVideoLookupRepository implements VideoLookupRepository {
  final known = <String, VideoMetadata>{};
  final errors = <String, VideoLookupError>{};

  void addKnown(String id, String title) => known[id] = VideoMetadata(
    videoId: id,
    title: title,
    channelName: 'Kids Channel',
    thumbnailUrl: YouTubeUrlParser.thumbnailUrl(id),
  );

  @override
  Future<VideoMetadata> lookup(String input) async {
    final id = YouTubeUrlParser.extractVideoId(input);
    if (id == null) {
      throw const VideoLookupException(VideoLookupError.invalidUrl);
    }
    final error = errors[id];
    if (error != null) throw VideoLookupException(error);
    return known[id] ??
        (throw const VideoLookupException(VideoLookupError.notFound));
  }
}

/// Scriptable browser: tests set [url] to simulate navigation.
class FakeInAppBrowser implements InAppBrowser {
  @override
  final ValueNotifier<Uri?> url = ValueNotifier(null);
  @override
  final ValueNotifier<int> progress = ValueNotifier(100);
  final loads = <Uri>[];
  var history = 0;
  var backs = 0;

  void visit(String u) {
    history++;
    url.value = Uri.parse(u);
  }

  @override
  Widget buildView(BuildContext context) =>
      const ColoredBox(key: Key('fake-browser'), color: Color(0xFF000000));

  @override
  Future<void> load(Uri uri) async {
    loads.add(uri);
    url.value = uri;
  }

  @override
  Future<bool> canGoBack() async => history > 0;

  @override
  Future<void> goBack() async {
    backs++;
    history--;
  }

  @override
  Future<void> dispose() async {}
}

class FakeYouTubePlaylistRepository implements YouTubePlaylistRepository {
  final playlists = <String, ImportedPlaylist>{};
  PlaylistImportError? error;

  @override
  Future<ImportedPlaylist> fetch(String playlistId) async {
    final e = error;
    if (e != null) throw PlaylistImportException(e);
    return playlists[playlistId] ??
        (throw const PlaylistImportException(PlaylistImportError.notFound));
  }
}

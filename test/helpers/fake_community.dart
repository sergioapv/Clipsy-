import 'dart:async';

import 'package:clipsy/features/community/data/community_repository.dart';
import 'package:clipsy/features/community/data/profile_repository.dart';
import 'package:clipsy/features/community/domain/community_playlist.dart';
import 'package:clipsy/features/playlists/domain/playlist.dart';
import 'package:clipsy/features/playlists/domain/playlist_exception.dart';
import 'package:clipsy/features/playlists/domain/share_intake.dart';
import 'package:clipsy/features/playlists/domain/youtube_url_parser.dart';

import 'fake_playlists.dart';

/// In-memory community library. Forks go into [library], when given.
class FakeCommunityRepository implements CommunityRepository {
  FakeCommunityRepository({this.me = 'u1', this.library});

  final String me;
  final FakePlaylistRepository? library;
  final playlists = <CommunityPlaylist>[];
  final videos = <String, List<PlaylistVideo>>{};
  final myRatings = <String, int>{};
  final reports = <(String, ReportReason, String?)>[];
  final queries = <(CommunityQuery, int)>[];
  PlaylistException? failNext;

  void _maybeFail() {
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  CommunityPlaylist publish(
    String title, {
    String id = 'c1',
    String ownerId = 'u2',
    String author = 'Marta',
    double? ratingAvg,
    int ratingCount = 0,
    List<String> labels = const ['animals'],
    AgeRange ageRange = AgeRange.young,
    List<String> videoIds = const ['aaaaaaaaaaa', 'bbbbbbbbbbb'],
  }) {
    final p = CommunityPlaylist(
      id: id,
      ownerId: ownerId,
      title: title,
      authorName: author,
      ageRange: ageRange,
      videoCount: videoIds.length,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      labelSlugs: labels,
      publishedAt: DateTime(2026, 10, 1).add(Duration(hours: playlists.length)),
    );
    playlists.add(p);
    videos[id] = [
      for (final (i, v) in videoIds.indexed)
        PlaylistVideo(
          id: '$id-v$i',
          playlistId: id,
          youtubeVideoId: v,
          title: 'Video $v',
          thumbnailUrl: YouTubeUrlParser.thumbnailUrl(v),
          position: i,
        ),
    ];
    return p;
  }

  @override
  Future<List<CommunityPlaylist>> browse(
    CommunityQuery query, {
    int offset = 0,
    int limit = CommunityRepository.pageSize,
  }) async {
    _maybeFail();
    queries.add((query, offset));
    final search = query.trimmedSearch.toLowerCase();
    final age = query.ageRange;
    final matches = playlists
        .where(
          (p) =>
              (query.labelSlug == null ||
                  p.labelSlugs.contains(query.labelSlug)) &&
              (age == null ||
                  (p.ageRange.min <= age.max && p.ageRange.max >= age.min)) &&
              (search.isEmpty || p.title.toLowerCase().contains(search)),
        )
        .toList();
    switch (query.sort) {
      case CommunitySort.topRated:
        matches.sort(
          (a, b) => (b.ratingAvg ?? -1).compareTo(a.ratingAvg ?? -1),
        );
      case CommunitySort.newest:
        matches.sort((a, b) => b.publishedAt!.compareTo(a.publishedAt!));
    }
    return matches.skip(offset).take(limit).toList();
  }

  @override
  Future<CommunityPlaylistDetail> fetchDetail(String id) async {
    _maybeFail();
    final p = playlists.where((p) => p.id == id).firstOrNull;
    if (p == null) throw const PlaylistException(PlaylistError.notFound);
    return CommunityPlaylistDetail(
      playlist: p,
      videos: videos[id] ?? const [],
      isMine: p.ownerId == me,
      myRating: myRatings[id],
    );
  }

  @override
  Future<String> fork(String id) async {
    _maybeFail();
    final p = playlists.firstWhere((p) => p.id == id);
    final copy = library?.seed(
      p.title,
      videoIds: [for (final v in videos[id]!) v.youtubeVideoId],
    );
    return copy?.id ?? 'fork-of-$id';
  }

  @override
  Future<void> rate(String id, int stars) async {
    _maybeFail();
    final i = playlists.indexWhere((p) => p.id == id);
    if (playlists[i].ownerId == me) {
      throw const PlaylistException(PlaylistError.ownPlaylist);
    }
    myRatings[id] = stars;
    final p = playlists[i];
    // Recompute as if this were the only change.
    final others = (p.ratingAvg ?? 0) * p.ratingCount;
    final count = p.ratingCount + 1;
    playlists[i] = p.withRating((others + stars) / count, count);
  }

  @override
  Future<void> report(String id, ReportReason reason, {String? details}) async {
    _maybeFail();
    if (reports.any((r) => r.$1 == id)) {
      throw const PlaylistException(PlaylistError.alreadyReported);
    }
    reports.add((id, reason, details));
  }
}

class FakeProfileRepository implements ProfileRepository {
  String name = 'Parent';

  @override
  Future<String> fetchDisplayName() async => name;

  @override
  Future<void> updateDisplayName(String name) async => this.name = name.trim();
}

/// Links "shared to Clipsy" on demand.
class FakeShareIntake implements ShareIntake {
  final _controller = StreamController<String>.broadcast();

  void share(String text) => _controller.add(text);

  @override
  Stream<String> get shares => _controller.stream;
}

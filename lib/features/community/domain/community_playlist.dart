import 'package:flutter/foundation.dart';

import '../../../core/l10n/languages.dart';
import '../../playlists/domain/playlist.dart';

enum CommunitySort { topRated, newest }

/// What to show in the community library. Used as a provider key, so it has
/// value equality.
@immutable
class CommunityQuery {
  const CommunityQuery({
    this.sort = CommunitySort.topRated,
    this.labelSlug,
    this.ageRange,
    this.language,
    this.search = '',
  });

  final CommunitySort sort;
  final String? labelSlug;

  /// Playlists whose age range overlaps this one.
  final AgeRange? ageRange;

  /// A language (`pt`, any variant) or a variant (`pt-PT`, plus playlists
  /// tagged only `pt`).
  final LanguageFilter? language;

  /// Matched against the title, case-insensitively.
  final String search;

  String get trimmedSearch => search.trim();

  @override
  bool operator ==(Object other) =>
      other is CommunityQuery &&
      other.sort == sort &&
      other.labelSlug == labelSlug &&
      other.ageRange == ageRange &&
      other.language == language &&
      other.trimmedSearch == trimmedSearch;

  @override
  int get hashCode =>
      Object.hash(sort, labelSlug, ageRange, language, trimmedSearch);
}

/// A published playlist as other parents see it (`community_playlists` view).
@immutable
class CommunityPlaylist {
  const CommunityPlaylist({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.authorName,
    required this.ageRange,
    required this.videoCount,
    this.description,
    this.coverUrl,
    this.ratingAvg,
    this.ratingCount = 0,
    this.publishedAt,
    this.forkedFrom,
    this.totalDurationSeconds,
    this.labelSlugs = const [],
    this.languages = const [],
  });

  factory CommunityPlaylist.fromJson(Map<String, Object?> json) =>
      CommunityPlaylist(
        id: json['id']! as String,
        ownerId: json['owner_id']! as String,
        title: json['title']! as String,
        description: json['description'] as String?,
        coverUrl: json['cover_url'] as String?,
        authorName: json['author_name'] as String? ?? '',
        ageRange: AgeRange.fromDb(
          (json['age_min'] as num?)?.toInt() ?? AgeRange.fallback.min,
          (json['age_max'] as num?)?.toInt() ?? AgeRange.fallback.max,
        ),
        ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
        ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
        publishedAt: switch (json['published_at']) {
          final String s => DateTime.tryParse(s),
          _ => null,
        },
        forkedFrom: json['forked_from'] as String?,
        videoCount: (json['video_count'] as num?)?.toInt() ?? 0,
        totalDurationSeconds: (json['total_duration_seconds'] as num?)?.toInt(),
        labelSlugs: [
          for (final s in (json['label_slugs'] as List<Object?>?) ?? const [])
            s! as String,
        ],
        languages: [
          for (final l in (json['languages'] as List<Object?>?) ?? const [])
            l! as String,
        ],
      );

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? coverUrl;
  final String authorName;
  final AgeRange ageRange;
  final double? ratingAvg;
  final int ratingCount;
  final DateTime? publishedAt;
  final String? forkedFrom;
  final int videoCount;

  /// Known only once every video's length has been recorded.
  final int? totalDurationSeconds;
  final List<String> labelSlugs;
  final List<String> languages;

  CommunityPlaylist withRating(double? avg, int count) => CommunityPlaylist(
    id: id,
    ownerId: ownerId,
    title: title,
    description: description,
    coverUrl: coverUrl,
    authorName: authorName,
    ageRange: ageRange,
    ratingAvg: avg,
    ratingCount: count,
    publishedAt: publishedAt,
    forkedFrom: forkedFrom,
    videoCount: videoCount,
    totalDurationSeconds: totalDurationSeconds,
    labelSlugs: labelSlugs,
    languages: languages,
  );
}

/// A community playlist with its videos and the caller's own rating.
@immutable
class CommunityPlaylistDetail {
  const CommunityPlaylistDetail({
    required this.playlist,
    required this.videos,
    required this.isMine,
    this.myRating,
  });

  final CommunityPlaylist playlist;
  final List<PlaylistVideo> videos;

  /// Parents can't rate or report their own playlists.
  final bool isMine;

  /// 1–5, or `null` if the parent hasn't rated it.
  final int? myRating;

  CommunityPlaylistDetail copyWith({
    CommunityPlaylist? playlist,
    int? myRating,
  }) => CommunityPlaylistDetail(
    playlist: playlist ?? this.playlist,
    videos: videos,
    isMine: isMine,
    myRating: myRating ?? this.myRating,
  );
}

/// Why a parent reports a playlist (database enum `report_reason`).
enum ReportReason {
  inappropriate('inappropriate'),
  violentOrScary('violent_or_scary'),
  notForKids('not_for_kids'),
  misleading('misleading'),
  spam('spam'),
  other('other');

  const ReportReason(this.dbValue);

  final String dbValue;
}

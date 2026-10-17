import 'package:flutter/foundation.dart';

enum PlaylistVisibility { private, public }

/// Target age range for a playlist.
@immutable
class AgeRange {
  const AgeRange(this.min, this.max)
    : assert(min >= minAge && max <= maxAge && min <= max);

  /// Clamps arbitrary database values into the supported range.
  factory AgeRange.fromDb(int min, int max) {
    final lo = min.clamp(minAge, maxAge);
    final hi = max.clamp(lo, maxAge);
    return AgeRange(lo, hi);
  }

  static const minAge = 1;
  static const maxAge = 14;

  static const toddlers = AgeRange(2, 4);
  static const young = AgeRange(5, 7);
  static const older = AgeRange(8, 12);
  static const presets = [toddlers, young, older];
  static const fallback = AgeRange(2, 12);

  final int min;
  final int max;

  @override
  bool operator ==(Object other) =>
      other is AgeRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => '$min–$max';
}

/// A playlist as shown in the parent's library.
@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.ageRange,
    this.description,
    this.coverUrl,
    this.visibility = PlaylistVisibility.private,
    this.forkedFrom,
    this.labelIds = const [],
    this.videoCount = 0,
    this.isHidden = false,
    this.ratingAvg,
    this.ratingCount = 0,
    this.sortIndex = 0,
  });

  /// Parses a `playlists` row, optionally with embedded
  /// `playlist_labels(label_id)` and `playlist_videos(count)`.
  factory Playlist.fromJson(Map<String, Object?> json) {
    final labels = (json['playlist_labels'] as List<Object?>?) ?? const [];
    final videos = json['playlist_videos'] as List<Object?>?;
    final countRow = videos != null && videos.length == 1
        ? (videos.first! as Map<String, Object?>)['count']
        : null;
    return Playlist(
      id: json['id']! as String,
      ownerId: json['owner_id']! as String,
      title: json['title']! as String,
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      ageRange: AgeRange.fromDb(
        (json['age_min'] as num?)?.toInt() ?? AgeRange.fallback.min,
        (json['age_max'] as num?)?.toInt() ?? AgeRange.fallback.max,
      ),
      visibility: json['visibility'] == 'public'
          ? PlaylistVisibility.public
          : PlaylistVisibility.private,
      forkedFrom: json['forked_from'] as String?,
      labelIds: [
        for (final l in labels)
          ((l! as Map<String, Object?>)['label_id']! as num).toInt(),
      ],
      videoCount: countRow is num ? countRow.toInt() : (videos?.length ?? 0),
      isHidden: json['is_hidden'] as bool? ?? false,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      sortIndex: (json['sort_index'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String ownerId;
  final String title;
  final String? description;

  /// Thumbnail of the first video, maintained by the database.
  final String? coverUrl;
  final AgeRange ageRange;
  final PlaylistVisibility visibility;
  final String? forkedFrom;
  final List<int> labelIds;
  final int videoCount;
  final bool isHidden;
  final double? ratingAvg;
  final int ratingCount;
  final int sortIndex;

  Playlist copyWith({
    String? title,
    String? description,
    AgeRange? ageRange,
    List<int>? labelIds,
    int? videoCount,
    String? coverUrl,
  }) => Playlist(
    id: id,
    ownerId: ownerId,
    title: title ?? this.title,
    description: description ?? this.description,
    coverUrl: coverUrl ?? this.coverUrl,
    ageRange: ageRange ?? this.ageRange,
    visibility: visibility,
    forkedFrom: forkedFrom,
    labelIds: labelIds ?? this.labelIds,
    videoCount: videoCount ?? this.videoCount,
    isHidden: isHidden,
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
    sortIndex: sortIndex,
  );
}

@immutable
class PlaylistVideo {
  const PlaylistVideo({
    required this.id,
    required this.playlistId,
    required this.youtubeVideoId,
    required this.title,
    required this.position,
    this.channelName,
    this.thumbnailUrl,
    this.durationSeconds,
    this.isAvailable = true,
  });

  factory PlaylistVideo.fromJson(Map<String, Object?> json) => PlaylistVideo(
    id: json['id']! as String,
    playlistId: json['playlist_id']! as String,
    youtubeVideoId: json['youtube_video_id']! as String,
    title: json['title']! as String,
    channelName: json['channel_name'] as String?,
    thumbnailUrl: json['thumbnail_url'] as String?,
    durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    position: (json['position']! as num).toInt(),
    isAvailable: json['is_available'] as bool? ?? true,
  );

  final String id;
  final String playlistId;
  final String youtubeVideoId;
  final String title;
  final String? channelName;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int position;
  final bool isAvailable;
}

/// A playlist with its ordered videos.
@immutable
class PlaylistDetail {
  const PlaylistDetail({required this.playlist, required this.videos});

  factory PlaylistDetail.fromJson(Map<String, Object?> json) {
    final videos = [
      for (final v in (json['playlist_videos'] as List<Object?>?) ?? const [])
        PlaylistVideo.fromJson(v! as Map<String, Object?>),
    ]..sort((a, b) => a.position.compareTo(b.position));
    return PlaylistDetail(
      playlist: Playlist.fromJson(json).copyWith(videoCount: videos.length),
      videos: videos,
    );
  }

  final Playlist playlist;
  final List<PlaylistVideo> videos;

  PlaylistDetail copyWith({Playlist? playlist, List<PlaylistVideo>? videos}) {
    final v = videos ?? this.videos;
    return PlaylistDetail(
      playlist: (playlist ?? this.playlist).copyWith(
        videoCount: v.length,
        coverUrl: v.where((x) => x.isAvailable).firstOrNull?.thumbnailUrl,
      ),
      videos: v,
    );
  }
}

/// Editable fields of a playlist, validated before saving.
@immutable
class PlaylistDraft {
  const PlaylistDraft({
    required this.title,
    this.description = '',
    this.ageRange = AgeRange.fallback,
    this.labelIds = const [],
  });

  static const maxTitleLength = 80;
  static const maxDescriptionLength = 500;
  static const maxLabels = 3;

  final String title;
  final String description;
  final AgeRange ageRange;
  final List<int> labelIds;

  String get trimmedTitle => title.trim();
  String? get trimmedDescription {
    final d = description.trim();
    return d.isEmpty ? null : d;
  }

  bool get isValid =>
      trimmedTitle.isNotEmpty &&
      trimmedTitle.length <= maxTitleLength &&
      description.trim().length <= maxDescriptionLength &&
      labelIds.toSet().length <= maxLabels;
}

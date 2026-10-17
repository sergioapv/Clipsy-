import 'package:flutter/foundation.dart';

import '../../playlists/domain/playlist.dart';
import 'kid_settings.dart';
import 'screen_time.dart';

/// A video as Kid mode needs it. Snapshotted when the session starts, so Kid
/// mode keeps working after a restart even without a network or a session.
@immutable
class KidVideo {
  const KidVideo({
    required this.rowId,
    required this.youtubeId,
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  factory KidVideo.fromPlaylistVideo(PlaylistVideo v) => KidVideo(
    rowId: v.id,
    youtubeId: v.youtubeVideoId,
    title: v.title,
    thumbnailUrl: v.thumbnailUrl,
    durationSeconds: v.durationSeconds,
  );

  factory KidVideo.fromJson(Map<String, Object?> json) => KidVideo(
    rowId: json['rowId']! as String,
    youtubeId: json['youtubeId']! as String,
    title: json['title']! as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  );

  /// `playlist_videos.id`, used to record the duration once known.
  final String rowId;
  final String youtubeId;
  final String title;
  final String? thumbnailUrl;
  final int? durationSeconds;

  Map<String, Object?> toJson() => {
    'rowId': rowId,
    'youtubeId': youtubeId,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'durationSeconds': durationSeconds,
  };
}

enum KidSessionStatus {
  watching,

  /// Time is up, but the current video is allowed to finish.
  finishingVideo,

  /// "All done for now!" — only the PIN can extend or exit.
  timeUp,
}

/// An active Kid mode session. Persisted on every change.
@immutable
class KidSession {
  const KidSession({
    required this.playlistId,
    required this.playlistTitle,
    required this.videos,
    required this.clock,
    required this.endBehaviour,
    required this.startedAt,
    this.currentIndex = 0,
    this.status = KidSessionStatus.watching,
  });

  factory KidSession.fromJson(Map<String, Object?> json) => KidSession(
    playlistId: json['playlistId']! as String,
    playlistTitle: json['playlistTitle']! as String,
    videos: [
      for (final v in json['videos']! as List<Object?>)
        KidVideo.fromJson(v! as Map<String, Object?>),
    ],
    clock: ScreenTimeClock.fromJson(json['clock']! as Map<String, Object?>),
    endBehaviour: EndBehaviour.values.byName(json['endBehaviour']! as String),
    startedAt: DateTime.parse(json['startedAt']! as String),
    currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
    status: KidSessionStatus.values.byName(json['status']! as String),
  );

  final String playlistId;
  final String playlistTitle;
  final List<KidVideo> videos;
  final ScreenTimeClock clock;
  final EndBehaviour endBehaviour;
  final DateTime startedAt;
  final int currentIndex;
  final KidSessionStatus status;

  KidVideo? get currentVideo =>
      currentIndex >= 0 && currentIndex < videos.length
      ? videos[currentIndex]
      : null;

  bool get isTimeUp => status == KidSessionStatus.timeUp;

  KidSession copyWith({
    List<KidVideo>? videos,
    ScreenTimeClock? clock,
    int? currentIndex,
    KidSessionStatus? status,
  }) => KidSession(
    playlistId: playlistId,
    playlistTitle: playlistTitle,
    videos: videos ?? this.videos,
    clock: clock ?? this.clock,
    endBehaviour: endBehaviour,
    startedAt: startedAt,
    currentIndex: currentIndex ?? this.currentIndex,
    status: status ?? this.status,
  );

  Map<String, Object?> toJson() => {
    'version': 1,
    'playlistId': playlistId,
    'playlistTitle': playlistTitle,
    'videos': [for (final v in videos) v.toJson()],
    'clock': clock.toJson(),
    'endBehaviour': endBehaviour.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'currentIndex': currentIndex,
    'status': status.name,
  };
}

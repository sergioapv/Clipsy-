import 'package:flutter/foundation.dart';

import 'video_metadata.dart';
import 'youtube_url_parser.dart';

/// A video from a YouTube playlist, after its oEmbed check.
@immutable
class ImportedVideo {
  const ImportedVideo({
    required this.videoId,
    required this.title,
    required this.playable,
    this.channelName,
    this.durationSeconds,
  });

  factory ImportedVideo.fromJson(Map<String, Object?> json) => ImportedVideo(
    videoId: json['videoId']! as String,
    title: (json['title'] as String?) ?? '',
    channelName: json['channelName'] as String?,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    playable: json['playable'] == true,
  );

  final String videoId;
  final String title;
  final String? channelName;
  final int? durationSeconds;

  /// Passed the oEmbed check: it exists and can be embedded.
  final bool playable;

  VideoMetadata toMetadata() => VideoMetadata(
    videoId: videoId,
    title: title.isEmpty ? videoId : title,
    channelName: channelName,
    thumbnailUrl: YouTubeUrlParser.thumbnailUrl(videoId),
    durationSeconds: durationSeconds,
  );
}

@immutable
class ImportedPlaylist {
  const ImportedPlaylist({
    required this.playlistId,
    required this.title,
    required this.videos,
    this.channelName,
    this.truncated = false,
  });

  factory ImportedPlaylist.fromJson(Map<String, Object?> json) =>
      ImportedPlaylist(
        playlistId: json['playlistId']! as String,
        title: (json['title'] as String?) ?? '',
        channelName: json['channelName'] as String?,
        truncated: json['truncated'] == true,
        videos: [
          for (final v in (json['videos'] as List<Object?>?) ?? const [])
            ImportedVideo.fromJson(v! as Map<String, Object?>),
        ],
      );

  final String playlistId;
  final String title;
  final String? channelName;
  final List<ImportedVideo> videos;

  /// The YouTube playlist has more videos than a Clipsy playlist can hold.
  final bool truncated;
}

/// What adding an imported playlist to a Clipsy playlist would do.
@immutable
class ImportPlan {
  const ImportPlan({
    required this.toAdd,
    required this.alreadyThere,
    required this.unavailable,
    required this.overLimit,
  });

  /// Splits [playlist] given the ids already in the target playlist and how
  /// many more videos it can hold.
  factory ImportPlan.from(
    ImportedPlaylist playlist, {
    required Set<String> existingIds,
    required int capacity,
  }) {
    final toAdd = <ImportedVideo>[];
    var already = 0, unavailable = 0, over = 0;
    final seen = <String>{};
    for (final v in playlist.videos) {
      if (!seen.add(v.videoId)) continue;
      if (existingIds.contains(v.videoId)) {
        already++;
      } else if (!v.playable) {
        unavailable++;
      } else if (toAdd.length >= capacity) {
        over++;
      } else {
        toAdd.add(v);
      }
    }
    return ImportPlan(
      toAdd: toAdd,
      alreadyThere: already,
      unavailable: unavailable,
      overLimit: over,
    );
  }

  final List<ImportedVideo> toAdd;
  final int alreadyThere;
  final int unavailable;
  final int overLimit;
}

enum PlaylistImportError {
  /// Mixes and personal lists can't be read.
  unsupported,

  /// Private, deleted or empty, or YouTube didn't list it in time.
  notFound,
  network,
  unknown,
}

class PlaylistImportException implements Exception {
  const PlaylistImportException(this.error);

  final PlaylistImportError error;

  @override
  String toString() => 'PlaylistImportException($error)';
}

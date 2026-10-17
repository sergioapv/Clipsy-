/// What we know about a YouTube video before it's added to a playlist.
class VideoMetadata {
  const VideoMetadata({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    this.channelName,
    this.durationSeconds,
  });

  final String videoId;
  final String title;
  final String? channelName;
  final String thumbnailUrl;

  /// Unknown from oEmbed; filled in later when available.
  final int? durationSeconds;
}

enum VideoLookupError {
  /// The text isn't a link to a single YouTube video.
  invalidUrl,

  /// Removed, private or never existed.
  notFound,

  /// The uploader disabled playback outside YouTube.
  notEmbeddable,

  network,
  unknown,
}

class VideoLookupException implements Exception {
  const VideoLookupException(this.error);

  final VideoLookupError error;

  @override
  String toString() => 'VideoLookupException($error)';
}

enum PlaylistError {
  /// The video is already in this playlist.
  duplicateVideo,
  tooManyVideos,
  tooManyLabels,
  notFound,
  network,
  unknown,
}

class PlaylistException implements Exception {
  const PlaylistException(this.error, [this.cause]);

  final PlaylistError error;
  final Object? cause;

  @override
  String toString() => 'PlaylistException($error, $cause)';
}

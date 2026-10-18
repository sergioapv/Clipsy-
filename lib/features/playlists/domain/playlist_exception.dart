enum PlaylistError {
  /// The video is already in this playlist.
  duplicateVideo,
  tooManyVideos,
  tooManyLabels,

  /// Publishing needs at least one label.
  needsLabel,

  /// Publishing needs at least one available video (and a published
  /// playlist can't lose its last one).
  needsVideo,

  /// Parents can't rate or report their own playlists.
  ownPlaylist,

  /// This parent has already reported the playlist.
  alreadyReported,
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

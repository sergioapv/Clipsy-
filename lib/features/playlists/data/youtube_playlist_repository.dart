import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../kid_mode/domain/kid_navigation_policy.dart';
import '../domain/imported_playlist.dart';
import '../domain/video_metadata.dart';
import '../domain/youtube_url_parser.dart';
import 'oembed_client.dart';

/// Reads a YouTube playlist without the YouTube Data API.
abstract interface class YouTubePlaylistRepository {
  /// A visible preview player that must stay on screen while [fetch] runs:
  /// it's the YouTube player that lists the playlist's videos.
  Widget buildHost(BuildContext context);

  /// The playlist's videos, each checked with oEmbed. [onProgress] reports
  /// how many videos have been checked so far.
  Future<ImportedPlaylist> fetch(
    String playlistId, {
    void Function(int checked, int total)? onProgress,
  });
}

/// Where the video ids of a playlist come from.
abstract interface class PlaylistIdsSource {
  Widget buildHost(BuildContext context);
  Future<List<String>> videoIds(String playlistId);
  Future<void> dispose();
}

/// Lists a playlist through the official YouTube IFrame player: cue the
/// playlist, then ask the player for its video ids (`getPlaylist()`). No API
/// key involved. The player is muted and never played, but it is shown as a
/// preview: on Android the player only starts when its web view is on
/// screen (youtube_player_iframe hides the web view of an unpainted player),
/// and YouTube's terms don't allow hidden players anyway.
class PlayerPlaylistIdsSource implements PlaylistIdsSource {
  PlayerPlaylistIdsSource({
    // Real playlists list within a second; lists the player can't read
    // (e.g. YouTube Music charts) never do.
    this.timeout = const Duration(seconds: 20),
    this.pollEvery = const Duration(milliseconds: 500),
  }) {
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        mute: true,
        showControls: false,
        enableKeyboard: false,
        pointerEvents: PointerEvents.none,
        privacyEnhancedMode: true,
      ),
    );
    final base = Uri.parse(_controller.params.host);
    // Same lock as Kid mode: the preview player can't navigate anywhere.
    unawaited(
      _controller.webViewController.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) =>
              KidNavigationPolicy.allows(
                Uri.tryParse(r.url),
                playerBaseUrl: base,
              )
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      ),
    );
  }

  final Duration timeout;
  final Duration pollEvery;
  late final YoutubePlayerController _controller;

  @override
  Widget buildHost(BuildContext context) => YoutubePlayer(
    controller: _controller,
    autoFullScreen: false,
    enableFullScreenOnVerticalDrag: false,
  );

  @override
  Future<List<String>> videoIds(String playlistId) async {
    try {
      await _controller.cuePlaylist(
        list: [playlistId],
        listType: ListType.playlist,
      );
    } on TimeoutException {
      // The player never loaded: almost always no (or a very slow) network.
      throw const PlaylistImportException(PlaylistImportError.network);
    }
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_controller.value.error != YoutubeError.none) {
        throw const PlaylistImportException(PlaylistImportError.notFound);
      }
      final ids = await _controller.playlist;
      if (ids.isNotEmpty) return ids;
      await Future<void>.delayed(pollEvery);
    }
    // Private, deleted or empty playlists never produce a list.
    throw const PlaylistImportException(PlaylistImportError.notFound);
  }

  @override
  Future<void> dispose() => _controller.close();
}

/// The IFrame player lists at most this many videos of a playlist.
const playerPlaylistLimit = 200;

/// Combines a [PlaylistIdsSource] with oEmbed: the playlist title, then each
/// video's title and whether it can be embedded.
class PlaylistImporter implements YouTubePlaylistRepository {
  PlaylistImporter({
    required this._ids,
    required this._oembed,
    this.maxVideos = 200,
    this.concurrency = 4,
  });

  final PlaylistIdsSource _ids;
  final OEmbedClient _oembed;
  final int maxVideos;
  final int concurrency;

  @override
  Widget buildHost(BuildContext context) => _ids.buildHost(context);

  @override
  Future<ImportedPlaylist> fetch(
    String playlistId, {
    void Function(int checked, int total)? onProgress,
  }) async {
    if (!YouTubeUrlParser.isImportablePlaylist(playlistId)) {
      throw const PlaylistImportException(PlaylistImportError.unsupported);
    }
    final ({String title, String? channelName})? info;
    try {
      info = await _oembed.fetchPlaylistInfo(playlistId);
    } on VideoLookupException {
      // YouTube says it doesn't exist (or is private): don't wait on the player.
      throw const PlaylistImportException(PlaylistImportError.notFound);
    }
    final listed = await _ids.videoIds(playlistId);
    final all = <String>[];
    for (final id in listed) {
      if (!all.contains(id)) all.add(id);
    }
    final ids = all.take(maxVideos).toList();
    onProgress?.call(0, ids.length);

    final results = List<ImportedVideo?>.filled(ids.length, null);
    var next = 0, checked = 0;
    Future<void> worker() async {
      while (next < ids.length) {
        final i = next++;
        results[i] = await _check(ids[i]);
        onProgress?.call(++checked, ids.length);
      }
    }

    await Future.wait([
      for (var w = 0; w < math.min(concurrency, ids.length); w++) worker(),
    ]);
    return ImportedPlaylist(
      playlistId: playlistId,
      title: info?.title ?? '',
      channelName: info?.channelName,
      videos: [for (final r in results) r!],
      // A full player list means the playlist was probably cut off.
      truncated: all.length > maxVideos || listed.length >= playerPlaylistLimit,
    );
  }

  Future<ImportedVideo> _check(String videoId) async {
    try {
      final meta = await _oembed.fetch(videoId);
      return ImportedVideo(
        videoId: videoId,
        title: meta.title,
        channelName: meta.channelName,
        playable: true,
      );
    } on VideoLookupException catch (e) {
      if (e.error == VideoLookupError.network) {
        throw const PlaylistImportException(PlaylistImportError.network);
      }
      // Removed, private or not embeddable: listed, but skipped.
      return ImportedVideo(videoId: videoId, title: '', playable: false);
    }
  }
}

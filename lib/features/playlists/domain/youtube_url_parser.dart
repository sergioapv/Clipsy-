/// Extracts YouTube video IDs from whatever a parent pastes or shares:
/// full URLs, short links, Shorts, embeds, mobile links, a URL inside a
/// sentence ("Look at this! https://youtu.be/…"), or a bare 11-character ID.
abstract final class YouTubeUrlParser {
  static final _bareId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final _idPrefix = RegExp(r'^([A-Za-z0-9_-]{11})(?![A-Za-z0-9_-])');

  // A YouTube link anywhere in the text. The lookbehind stops matches inside
  // other domains such as "notyoutube.com".
  static final _link = RegExp(
    r'(?<![\w.-])(?:https?://)?(?:[\w-]+\.)*(?:youtube\.com|youtu\.be|youtube-nocookie\.com)(?:/\S*)?',
    caseSensitive: false,
  );

  static const _idSegments = {'shorts', 'embed', 'live', 'v', 'e'};

  /// The video ID, or `null` if [input] doesn't point to a single video.
  static String? extractVideoId(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    if (_bareId.hasMatch(text)) return text;

    for (final match in _link.allMatches(text)) {
      final id = _fromUrl(match.group(0)!);
      if (id != null) return id;
    }
    return null;
  }

  static final _playlistId = RegExp(r'^[A-Za-z0-9_-]{10,64}$');

  /// Auto-generated mixes (RD…) and personal lists (watch later, likes, …)
  /// can't be read through the YouTube Data API.
  static const _unsupportedPlaylistPrefixes = ['RD', 'UL', 'LL', 'WL', 'LM'];

  /// The playlist id (`list=`) of a YouTube link, or `null`. Works for
  /// playlist pages and for videos opened from a playlist.
  static String? extractPlaylistId(String input) {
    for (final match in _link.allMatches(input.trim())) {
      final raw = match.group(0)!;
      final uri = Uri.tryParse(
        raw.toLowerCase().startsWith('http') ? raw : 'https://$raw',
      );
      if (uri == null) continue;
      final host = uri.host.toLowerCase();
      if (!_isHost(host, 'youtube.com') && !_isHost(host, 'youtu.be')) continue;
      final id = uri.queryParameters['list'];
      if (id != null && _playlistId.hasMatch(id)) return id;
    }
    return null;
  }

  /// Whether a playlist id can be imported (not a mix or personal list).
  static bool isImportablePlaylist(String playlistId) =>
      !_unsupportedPlaylistPrefixes.any(playlistId.startsWith);

  /// Canonical watch URL, used for oEmbed lookups.
  static Uri watchUrl(String videoId) =>
      Uri.https('www.youtube.com', '/watch', {'v': videoId});

  /// Thumbnail URL on YouTube's image CDN (the only image host the database
  /// accepts).
  static String thumbnailUrl(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  static String? _fromUrl(String raw) {
    final withScheme = raw.toLowerCase().startsWith('http')
        ? raw
        : 'https://$raw';
    final uri = Uri.tryParse(withScheme);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (_isHost(host, 'youtu.be')) {
      return _take(segments.firstOrNull);
    }
    if (!_isHost(host, 'youtube.com') &&
        !_isHost(host, 'youtube-nocookie.com')) {
      return null;
    }
    if (segments.isEmpty) return null;
    final first = segments.first.toLowerCase();
    if (first == 'watch') return _take(uri.queryParameters['v']);
    if (_idSegments.contains(first)) return _take(segments.elementAtOrNull(1));
    if (first == 'attribution_link') {
      final inner = uri.queryParameters['u'];
      return inner == null ? null : _fromUrl('https://www.youtube.com$inner');
    }
    return null; // Channels, playlists, search, …
  }

  static bool _isHost(String host, String domain) =>
      host == domain || host.endsWith('.$domain');

  static String? _take(String? candidate) {
    if (candidate == null) return null;
    return _idPrefix.firstMatch(candidate)?.group(1);
  }
}

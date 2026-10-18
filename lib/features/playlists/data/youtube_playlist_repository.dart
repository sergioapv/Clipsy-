import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/imported_playlist.dart';
import '../domain/youtube_url_parser.dart';

/// Reads YouTube playlists through the `youtube-playlist` Edge Function, which
/// holds the YouTube Data API key.
abstract interface class YouTubePlaylistRepository {
  Future<ImportedPlaylist> fetch(String playlistId);
}

class SupabaseYouTubePlaylistRepository implements YouTubePlaylistRepository {
  const SupabaseYouTubePlaylistRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ImportedPlaylist> fetch(String playlistId) async {
    if (!YouTubeUrlParser.isImportablePlaylist(playlistId)) {
      throw const PlaylistImportException(PlaylistImportError.unsupported);
    }
    try {
      final res = await _client.functions
          .invoke('youtube-playlist', body: {'playlistId': playlistId})
          .timeout(const Duration(seconds: 30));
      final data = res.data;
      if (data is! Map<String, Object?>) {
        throw const PlaylistImportException(PlaylistImportError.unknown);
      }
      return ImportedPlaylist.fromJson(data);
    } on FunctionException catch (e) {
      final code = e.details is Map ? (e.details as Map)['error'] : null;
      throw PlaylistImportException(switch ((e.status, code)) {
        (_, 'not_configured') => PlaylistImportError.notConfigured,
        (_, 'quota') => PlaylistImportError.quota,
        (404, _) || (_, 'not_found') => PlaylistImportError.notFound,
        (400, _) => PlaylistImportError.unsupported,
        // Function not deployed yet.
        (404 || 503, null) => PlaylistImportError.notConfigured,
        _ => PlaylistImportError.unknown,
      });
    } on TimeoutException {
      throw const PlaylistImportException(PlaylistImportError.network);
    } on SocketException {
      throw const PlaylistImportException(PlaylistImportError.network);
    } on http.ClientException {
      throw const PlaylistImportException(PlaylistImportError.network);
    }
  }
}

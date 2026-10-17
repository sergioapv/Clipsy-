import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/video_metadata.dart';
import '../domain/youtube_url_parser.dart';

/// Looks up video metadata through YouTube's public oEmbed endpoint. No API
/// key is needed, and oEmbed refuses videos that can't be embedded, which is
/// exactly the check Clipsy needs.
class OEmbedClient {
  OEmbedClient(this._http, {this.timeout = const Duration(seconds: 10)});

  final http.Client _http;
  final Duration timeout;

  Future<VideoMetadata> fetch(String videoId) async {
    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': YouTubeUrlParser.watchUrl(videoId).toString(),
      'format': 'json',
    });

    final http.Response response;
    try {
      response = await _http.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const VideoLookupException(VideoLookupError.network);
    } on SocketException {
      throw const VideoLookupException(VideoLookupError.network);
    } on http.ClientException {
      throw const VideoLookupException(VideoLookupError.network);
    }

    switch (response.statusCode) {
      case 200:
        return _parse(videoId, response.body);
      // YouTube answers 401/403 for embedding disabled (and some private
      // videos), 400/404 for removed or unknown ones.
      case 401 || 403:
        throw const VideoLookupException(VideoLookupError.notEmbeddable);
      case 400 || 404:
        throw const VideoLookupException(VideoLookupError.notFound);
      default:
        throw const VideoLookupException(VideoLookupError.unknown);
    }
  }

  static VideoMetadata _parse(String videoId, String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      throw const VideoLookupException(VideoLookupError.unknown);
    }
    if (json is! Map<String, Object?>) {
      throw const VideoLookupException(VideoLookupError.unknown);
    }
    final title = (json['title'] as String?)?.trim();
    if (title == null || title.isEmpty) {
      throw const VideoLookupException(VideoLookupError.notFound);
    }
    final channel = (json['author_name'] as String?)?.trim();
    return VideoMetadata(
      videoId: videoId,
      title: _clip(title, 300),
      channelName: channel == null || channel.isEmpty
          ? null
          : _clip(channel, 200),
      // Built from the ID rather than trusting the response, so it always
      // points at YouTube's CDN.
      thumbnailUrl: YouTubeUrlParser.thumbnailUrl(videoId),
    );
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}

/// Parses user input and validates it against oEmbed.
class VideoLookupRepository {
  const VideoLookupRepository(this._oembed);

  final OEmbedClient _oembed;

  Future<VideoMetadata> lookup(String input) {
    final id = YouTubeUrlParser.extractVideoId(input);
    if (id == null) {
      return Future.error(
        const VideoLookupException(VideoLookupError.invalidUrl),
      );
    }
    return _oembed.fetch(id);
  }
}

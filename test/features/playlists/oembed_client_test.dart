import 'dart:convert';
import 'dart:io';

import 'package:clipsy/features/playlists/data/oembed_client.dart';
import 'package:clipsy/features/playlists/domain/video_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const id = 'dQw4w9WgXcQ';
  late Uri lastRequest;

  OEmbedClient clientReturning(int status, [String body = '']) => OEmbedClient(
    MockClient((req) async {
      lastRequest = req.url;
      return http.Response(body, status);
    }),
  );

  Matcher failsWith(VideoLookupError error) => throwsA(
    isA<VideoLookupException>().having((e) => e.error, 'error', error),
  );

  test('maps a successful response and asks for the canonical URL', () async {
    final client = clientReturning(
      200,
      jsonEncode({
        'title': ' Planets Song ',
        'author_name': 'Kids Channel',
        'thumbnail_url': 'https://evil.example/thumb.jpg',
      }),
    );
    final meta = await client.fetch(id);
    expect(lastRequest.host, 'www.youtube.com');
    expect(lastRequest.path, '/oembed');
    expect(
      lastRequest.queryParameters['url'],
      'https://www.youtube.com/watch?v=$id',
    );
    expect(lastRequest.queryParameters['format'], 'json');
    expect(meta.videoId, id);
    expect(meta.title, 'Planets Song');
    expect(meta.channelName, 'Kids Channel');
    // Thumbnail is always rebuilt from the id, never taken from the response.
    expect(meta.thumbnailUrl, 'https://i.ytimg.com/vi/$id/hqdefault.jpg');
    expect(meta.durationSeconds, isNull);
  });

  test('clips overly long titles', () async {
    final meta = await clientReturning(
      200,
      jsonEncode({'title': 'x' * 400}),
    ).fetch(id);
    expect(meta.title.length, 300);
    expect(meta.channelName, isNull);
  });

  test('401 and 403 mean embedding is disabled', () async {
    expect(
      clientReturning(401, 'Unauthorized').fetch(id),
      failsWith(VideoLookupError.notEmbeddable),
    );
    expect(
      clientReturning(403).fetch(id),
      failsWith(VideoLookupError.notEmbeddable),
    );
  });

  test('400 and 404 mean the video is gone', () async {
    expect(
      clientReturning(404, 'Not Found').fetch(id),
      failsWith(VideoLookupError.notFound),
    );
    expect(
      clientReturning(400, 'Bad Request').fetch(id),
      failsWith(VideoLookupError.notFound),
    );
  });

  test('server errors and bad JSON are unknown errors', () async {
    expect(clientReturning(500).fetch(id), failsWith(VideoLookupError.unknown));
    expect(
      clientReturning(200, '<html>').fetch(id),
      failsWith(VideoLookupError.unknown),
    );
    expect(
      clientReturning(200, '[]').fetch(id),
      failsWith(VideoLookupError.unknown),
    );
  });

  test('a response without a title counts as not found', () async {
    expect(
      clientReturning(200, '{"title": ""}').fetch(id),
      failsWith(VideoLookupError.notFound),
    );
  });

  test('network failures map to network errors', () async {
    final socket = OEmbedClient(
      MockClient((_) => throw const SocketException('offline')),
    );
    expect(socket.fetch(id), failsWith(VideoLookupError.network));

    final clientEx = OEmbedClient(
      MockClient((_) => throw http.ClientException('reset')),
    );
    expect(clientEx.fetch(id), failsWith(VideoLookupError.network));

    final slow = OEmbedClient(
      MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      }),
      timeout: const Duration(milliseconds: 1),
    );
    expect(slow.fetch(id), failsWith(VideoLookupError.network));
  });

  group('VideoLookupRepository', () {
    test('rejects invalid input without a network call', () async {
      var calls = 0;
      final repo = VideoLookupRepository(
        OEmbedClient(
          MockClient((_) async {
            calls++;
            return http.Response('{}', 200);
          }),
        ),
      );
      await expectLater(
        repo.lookup('not a link'),
        failsWith(VideoLookupError.invalidUrl),
      );
      expect(calls, 0);
    });

    test('parses then fetches', () async {
      final repo = VideoLookupRepository(
        clientReturning(200, '{"title":"Hi"}'),
      );
      final meta = await repo.lookup('Watch this https://youtu.be/$id!');
      expect(meta.videoId, id);
      expect(lastRequest.queryParameters['url'], contains(id));
    });
  });
}

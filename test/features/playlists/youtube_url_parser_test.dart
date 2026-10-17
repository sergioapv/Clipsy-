import 'package:clipsy/features/playlists/domain/youtube_url_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'dQw4w9WgXcQ';

  group('extractVideoId accepts', () {
    const inputs = {
      'bare id': id,
      'bare id with spaces': '  $id \n',
      'watch': 'https://www.youtube.com/watch?v=$id',
      'watch without www': 'https://youtube.com/watch?v=$id',
      'watch without scheme': 'youtube.com/watch?v=$id',
      'watch http': 'http://www.youtube.com/watch?v=$id',
      'watch with extra params first':
          'https://www.youtube.com/watch?feature=share&v=$id',
      'watch with time and list':
          'https://www.youtube.com/watch?v=$id&t=42s&list=PL123',
      'mobile': 'https://m.youtube.com/watch?v=$id',
      'music': 'https://music.youtube.com/watch?v=$id',
      'uppercase host': 'HTTPS://WWW.YOUTUBE.COM/watch?v=$id',
      'short link': 'https://youtu.be/$id',
      'short link with share param': 'https://youtu.be/$id?si=AbCdEf123',
      'short link with time': 'https://youtu.be/$id?t=10',
      'shorts': 'https://www.youtube.com/shorts/$id',
      'shorts with params': 'https://youtube.com/shorts/$id?feature=share',
      'embed': 'https://www.youtube.com/embed/$id?rel=0',
      'nocookie embed': 'https://www.youtube-nocookie.com/embed/$id',
      'live': 'https://www.youtube.com/live/$id?si=x',
      'legacy v': 'https://www.youtube.com/v/$id',
      'shared text': 'Look at this one! https://youtu.be/$id so cute',
      'trailing punctuation': 'Watch https://youtu.be/$id.',
      'in parentheses': '(https://www.youtube.com/watch?v=$id)',
      'attribution link':
          'https://www.youtube.com/attribution_link?a=x&u=%2Fwatch%3Fv%3D$id%26feature%3Dshare',
      'id with dash and underscore': 'https://youtu.be/a-b_c-d_e-f',
    };
    inputs.forEach((name, input) {
      test(name, () {
        expect(
          YouTubeUrlParser.extractVideoId(input),
          name.contains('dash') ? 'a-b_c-d_e-f' : id,
        );
      });
    });
  });

  group('extractVideoId rejects', () {
    const inputs = {
      'empty': '',
      'whitespace': '   ',
      'random text': 'hello there',
      'too short id': 'dQw4w9WgXc',
      'too long bare id': 'dQw4w9WgXcQQ',
      'other site': 'https://vimeo.com/123456',
      'lookalike domain': 'https://notyoutube.com/watch?v=$id',
      'lookalike suffix': 'https://youtube.com.evil.example/watch?v=$id',
      'channel': 'https://www.youtube.com/@SomeChannel',
      'playlist only': 'https://www.youtube.com/playlist?list=PL123456',
      'home page': 'https://www.youtube.com/',
      'watch without id': 'https://www.youtube.com/watch',
      'watch with short id': 'https://www.youtube.com/watch?v=abc',
      'short link without id': 'https://youtu.be/',
      'search': 'https://www.youtube.com/results?search_query=dinosaurs',
    };
    inputs.forEach((name, input) {
      test(name, () => expect(YouTubeUrlParser.extractVideoId(input), isNull));
    });
  });

  test('builds canonical URLs', () {
    expect(
      YouTubeUrlParser.watchUrl(id).toString(),
      'https://www.youtube.com/watch?v=$id',
    );
    expect(
      YouTubeUrlParser.thumbnailUrl(id),
      'https://i.ytimg.com/vi/$id/hqdefault.jpg',
    );
  });
}

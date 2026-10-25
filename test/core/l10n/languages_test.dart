import 'package:clipsy/core/l10n/languages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalize turns what people type into valid tags', () {
    expect(Language.normalize('pt-br'), 'pt-BR');
    expect(Language.normalize('PT_pt'), 'pt-PT');
    expect(Language.normalize('en-uk'), 'en-GB');
    expect(Language.normalize('en-US'), 'en-US');
    expect(Language.normalize('es-419'), 'es-419');
    expect(Language.normalize('zh-hant'), 'zh-Hant');
    expect(Language.normalize('sr-latn-rs'), 'sr-Latn-RS');
    expect(Language.normalize(' fil '), 'fil');
    expect(Language.normalize('english'), isNull);
    expect(Language.normalize('pt-'), isNull);
    expect(Language.normalize(''), isNull);
  });

  test('names come from the catalogue, or are built for unknown tags', () {
    expect(Language.of('pt-PT').name, 'Português (Portugal)');
    expect(Language.of('en-GB').name, 'English (UK)');
    expect(Language.of('de-LI').name, 'Deutsch (LI)');
    expect(Language.of('tlh').name, 'tlh');
  });

  test('search finds names (accents ignored), tags and typed codes', () {
    List<String> tags(String q) => [for (final l in Language.search(q)) l.tag];
    expect(tags('portu'), containsAll(['pt', 'pt-PT', 'pt-BR']));
    expect(tags('francais'), contains('fr-CA'));
    expect(tags('en-uk'), ['en-GB']);
    expect(tags('de-li'), ['de-LI'], reason: 'valid but unlisted tag');
    expect(tags('xyzzy'), isEmpty);
  });

  test('a language matches every variant; a variant matches itself and '
      'playlists tagged only with the language', () {
    const anyPortuguese = LanguageFilter('pt');
    const portugal = LanguageFilter('pt-PT');
    expect(anyPortuguese.matches(['pt-BR']), isTrue);
    expect(anyPortuguese.matches(['pt']), isTrue);
    expect(anyPortuguese.matches(['en-GB']), isFalse);
    expect(portugal.matches(['pt-PT', 'en-GB']), isTrue);
    expect(portugal.matches(['pt']), isTrue);
    expect(portugal.matches(['pt-BR']), isFalse);
    expect(portugal.matches([]), isFalse);
  });

  test('the catalogue has no duplicates and only valid tags', () {
    final tags = [for (final l in Language.all) l.tag];
    expect(tags.toSet(), hasLength(tags.length));
    for (final t in tags) {
      expect(Language.normalize(t), t, reason: t);
    }
  });
}

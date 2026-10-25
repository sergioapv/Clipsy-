import 'package:flutter/foundation.dart';

/// A language a playlist can be in, as a BCP 47 tag (`pt`, `pt-PT`,
/// `es-419`, `zh-Hant`). Names are autonyms (each language in its own
/// words), so the list reads the same whatever the app's language.
@immutable
class Language {
  const Language(this.tag, this.name);

  final String tag;
  final String name;

  /// `pt` for `pt-PT`.
  String get base => baseOf(tag);
  bool get isVariant => tag.contains('-');

  static String baseOf(String tag) => tag.split('-').first;

  /// The same shape the database accepts:
  /// language[-Script][-REGION], REGION being two letters or three digits.
  static final _tagPattern = RegExp(
    r'^[a-z]{2,3}(-[A-Z][a-z]{3})?(-([A-Z]{2}|[0-9]{3}))?$',
  );

  /// Turns what someone typed ("en_uk", "PT-br", "es-419") into a valid
  /// tag, or `null`. Common mistakes are fixed: `UK` → `GB`.
  static String? normalize(String input) {
    final parts = input.trim().replaceAll('_', '-').split('-');
    if (parts.isEmpty || parts.first.isEmpty) return null;
    final out = <String>[parts.first.toLowerCase()];
    for (final p in parts.skip(1)) {
      if (p.length == 4) {
        out.add(p[0].toUpperCase() + p.substring(1).toLowerCase());
      } else {
        final region = p.toUpperCase();
        out.add(region == 'UK' ? 'GB' : region);
      }
    }
    final tag = out.join('-');
    return _tagPattern.hasMatch(tag) ? tag : null;
  }

  /// The catalogue entry for [tag], or a bare one showing the tag itself.
  static Language of(String tag) =>
      _byTag[tag] ??
      (() {
        final base = _byTag[baseOf(tag)];
        // Unknown variant of a known language: "Deutsch (LI)".
        return base == null
            ? Language(tag, tag)
            : Language(tag, '${base.name} (${tag.split('-').last})');
      })();

  /// Every language in the catalogue, followed by its variants.
  static const all = <Language>[
    Language('af', 'Afrikaans'),
    Language('am', 'አማርኛ'),
    Language('ar', 'العربية'),
    Language('az', 'Azərbaycan'),
    Language('be', 'Беларуская'),
    Language('bg', 'Български'),
    Language('bn', 'বাংলা'),
    Language('bs', 'Bosanski'),
    Language('ca', 'Català'),
    Language('cs', 'Čeština'),
    Language('cy', 'Cymraeg'),
    Language('da', 'Dansk'),
    Language('de', 'Deutsch'),
    Language('de-DE', 'Deutsch (Deutschland)'),
    Language('de-AT', 'Deutsch (Österreich)'),
    Language('de-CH', 'Deutsch (Schweiz)'),
    Language('el', 'Ελληνικά'),
    Language('en', 'English'),
    Language('en-US', 'English (US)'),
    Language('en-GB', 'English (UK)'),
    Language('en-AU', 'English (Australia)'),
    Language('en-CA', 'English (Canada)'),
    Language('en-IE', 'English (Ireland)'),
    Language('en-IN', 'English (India)'),
    Language('en-NZ', 'English (New Zealand)'),
    Language('en-ZA', 'English (South Africa)'),
    Language('es', 'Español'),
    Language('es-ES', 'Español (España)'),
    Language('es-419', 'Español (Latinoamérica)'),
    Language('es-MX', 'Español (México)'),
    Language('es-AR', 'Español (Argentina)'),
    Language('es-CO', 'Español (Colombia)'),
    Language('es-US', 'Español (Estados Unidos)'),
    Language('et', 'Eesti'),
    Language('eu', 'Euskara'),
    Language('fa', 'فارسی'),
    Language('fi', 'Suomi'),
    Language('fil', 'Filipino'),
    Language('fr', 'Français'),
    Language('fr-FR', 'Français (France)'),
    Language('fr-CA', 'Français (Canada)'),
    Language('fr-BE', 'Français (Belgique)'),
    Language('fr-CH', 'Français (Suisse)'),
    Language('ga', 'Gaeilge'),
    Language('gl', 'Galego'),
    Language('gu', 'ગુજરાતી'),
    Language('ha', 'Hausa'),
    Language('he', 'עברית'),
    Language('hi', 'हिन्दी'),
    Language('hr', 'Hrvatski'),
    Language('hu', 'Magyar'),
    Language('hy', 'Հայերեն'),
    Language('id', 'Bahasa Indonesia'),
    Language('ig', 'Igbo'),
    Language('is', 'Íslenska'),
    Language('it', 'Italiano'),
    Language('ja', '日本語'),
    Language('ka', 'ქართული'),
    Language('kk', 'Қазақ тілі'),
    Language('km', 'ខ្មែរ'),
    Language('kn', 'ಕನ್ನಡ'),
    Language('ko', '한국어'),
    Language('lb', 'Lëtzebuergesch'),
    Language('lo', 'ລາວ'),
    Language('lt', 'Lietuvių'),
    Language('lv', 'Latviešu'),
    Language('mk', 'Македонски'),
    Language('ml', 'മലയാളം'),
    Language('mn', 'Монгол'),
    Language('mr', 'मराठी'),
    Language('ms', 'Bahasa Melayu'),
    Language('mt', 'Malti'),
    Language('my', 'မြန်မာ'),
    Language('nb', 'Norsk bokmål'),
    Language('ne', 'नेपाली'),
    Language('nl', 'Nederlands'),
    Language('nl-NL', 'Nederlands (Nederland)'),
    Language('nl-BE', 'Nederlands (België)'),
    Language('nn', 'Norsk nynorsk'),
    Language('pa', 'ਪੰਜਾਬੀ'),
    Language('pl', 'Polski'),
    Language('pt', 'Português'),
    Language('pt-PT', 'Português (Portugal)'),
    Language('pt-BR', 'Português (Brasil)'),
    Language('pt-AO', 'Português (Angola)'),
    Language('pt-MZ', 'Português (Moçambique)'),
    Language('ro', 'Română'),
    Language('ru', 'Русский'),
    Language('si', 'සිංහල'),
    Language('sk', 'Slovenčina'),
    Language('sl', 'Slovenščina'),
    Language('sq', 'Shqip'),
    Language('sr', 'Српски'),
    Language('sv', 'Svenska'),
    Language('sw', 'Kiswahili'),
    Language('ta', 'தமிழ்'),
    Language('te', 'తెలుగు'),
    Language('th', 'ไทย'),
    Language('tr', 'Türkçe'),
    Language('uk', 'Українська'),
    Language('ur', 'اردو'),
    Language('uz', 'Oʻzbek'),
    Language('vi', 'Tiếng Việt'),
    Language('xh', 'isiXhosa'),
    Language('yo', 'Yorùbá'),
    Language('zh', '中文'),
    Language('zh-Hans', '简体中文'),
    Language('zh-Hant', '繁體中文'),
    Language('zu', 'isiZulu'),
  ];

  static final Map<String, Language> _byTag = {for (final l in all) l.tag: l};

  /// Catalogue entries whose name or tag matches [query] (accents and case
  /// ignored), plus the typed tag itself when it's valid but not listed.
  static List<Language> search(String query) {
    if (query.trim().isEmpty) return all;
    final typed = normalize(query);
    final matches = [
      for (final l in all)
        if (l.matches(query)) l,
    ];
    if (typed != null && !_byTag.containsKey(typed)) {
      matches.add(of(typed));
    }
    return matches;
  }

  /// Whether this language's name or tag matches a search [query].
  bool matches(String query) {
    final q = _fold(query.trim());
    if (q.isEmpty) return true;
    final typed = normalize(query);
    return _fold(name).contains(q) ||
        _fold(tag).startsWith(q) ||
        (typed != null && tag == typed);
  }

  static String _fold(String s) {
    const from = 'áàâãäåçéèêëíìîïñóòôõöúùûüýÿ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyy';
    final lower = s.toLowerCase().replaceAll('_', '-');
    final b = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    return b.toString();
  }

  @override
  bool operator ==(Object other) => other is Language && other.tag == tag;

  @override
  int get hashCode => tag.hashCode;

  @override
  String toString() => tag;
}

/// A language filter: a bare language (`pt`) matches every variant; a
/// variant (`pt-PT`) matches itself and playlists tagged only `pt`.
@immutable
class LanguageFilter {
  const LanguageFilter(this.tag);

  final String tag;

  bool get anyVariant => !tag.contains('-');

  bool matches(List<String> tags) => anyVariant
      ? tags.any((t) => Language.baseOf(t) == tag)
      : tags.any((t) => t == tag || t == Language.baseOf(tag));

  @override
  bool operator ==(Object other) => other is LanguageFilter && other.tag == tag;

  @override
  int get hashCode => tag.hashCode;
}

/// Which pages the parent-mode YouTube browser may open.
///
/// Browsing stays on YouTube (plus Google's cookie-consent pages, which
/// YouTube shows in the EU). App links (`intent:`, `vnd.youtube:`) and other
/// sites are blocked, so the browser never hands off to the YouTube app or an
/// external browser.
abstract final class YouTubeBrowsePolicy {
  static final home = Uri.https('m.youtube.com', '/');

  /// YouTube's home with its interface language (`hl`) and region (`gl`)
  /// set for [language], a BCP 47 tag. YouTube has no "only this language"
  /// filter, but it ranks home and search results by these and remembers
  /// them in a cookie. With no language, [fallbackHl] (the app's language)
  /// resets an earlier choice.
  static Uri homeFor(String? language, {required String fallbackHl}) {
    if (language == null) {
      return home.replace(queryParameters: {'hl': fallbackHl});
    }
    final (hl, gl) = youTubeLocale(language);
    return home.replace(queryParameters: {'hl': hl, 'gl': ?gl});
  }

  /// A BCP 47 tag as YouTube's `hl` and `gl`. YouTube's own codes differ in
  /// a few places: Brazilian Portuguese is `pt` (Portugal is `pt-PT`),
  /// Spain's Spanish is `es`, and Chinese scripts go by region.
  static (String hl, String? gl) youTubeLocale(String language) {
    final parts = language.split('-');
    final lang = parts.first;
    final region =
        parts.length > 1 && RegExp(r'^[A-Z]{2}$').hasMatch(parts.last)
        ? parts.last
        : null;
    return switch (language) {
      'pt-BR' => ('pt', 'BR'),
      'es-ES' => ('es', 'ES'),
      'zh-Hant' => ('zh-TW', 'TW'),
      'zh-Hans' => ('zh-CN', null),
      'es-419' => ('es-419', null),
      _ when region != null => ('$lang-$region', region),
      _ => (lang, null),
    };
  }

  static const _allowedHosts = {
    'youtube.com',
    'youtu.be',
    'consent.google.com',
  };

  static bool allows(Uri? uri) {
    if (uri == null) return false;
    if (uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'blob') {
      return true;
    }
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return _allowedHosts.any((h) => host == h || host.endsWith('.$h'));
  }
}

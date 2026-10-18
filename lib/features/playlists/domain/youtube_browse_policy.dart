/// Which pages the parent-mode YouTube browser may open.
///
/// Browsing stays on YouTube (plus Google's cookie-consent pages, which
/// YouTube shows in the EU). App links (`intent:`, `vnd.youtube:`) and other
/// sites are blocked, so the browser never hands off to the YouTube app or an
/// external browser.
abstract final class YouTubeBrowsePolicy {
  static final home = Uri.https('m.youtube.com', '/');

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

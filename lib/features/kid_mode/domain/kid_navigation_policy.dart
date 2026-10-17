/// Decides which page loads the Kid mode player's web view may perform.
///
/// The player page itself and YouTube embed frames are allowed. Everything
/// else is blocked: tapping the YouTube logo or title, end-screen suggestions,
/// "Watch on YouTube", channel links and ads would otherwise navigate away or
/// open the YouTube app. Blocked links are never opened externally in Kid mode.
abstract final class KidNavigationPolicy {
  static const _youtubeHosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
  };

  /// [playerBaseUrl] is the page the player HTML is loaded under.
  static bool allows(Uri? uri, {required Uri playerBaseUrl}) {
    if (uri == null) return false;
    if (uri.scheme == 'about' || uri.scheme == 'data') return true;
    if (uri.scheme != 'https') return false;

    // The player's own page (loaded with loadHtmlString under this base URL).
    if (uri.host == playerBaseUrl.host &&
        (uri.path.isEmpty ||
            uri.path == '/' ||
            uri.path == playerBaseUrl.path)) {
      return true;
    }
    // The iframe player itself.
    return _youtubeHosts.contains(uri.host.toLowerCase()) &&
        uri.path.startsWith('/embed/');
  }
}

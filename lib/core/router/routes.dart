/// Route paths. Keep in one place so redirects and links agree.
abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const pinSetup = '/pin/setup';
  static const onboarding = '/onboarding';
  static const unlock = '/unlock';
  static const kid = '/kid';

  static const playlists = '/playlists';
  static const newPlaylist = '/playlists/new';
  static String playlist(String id) => '/playlists/$id';
  static String editPlaylist(String id) => '/playlists/$id/edit';
  static String browseYouTube(String id) => '/playlists/$id/browse';
  static const community = '/community';
  static String communityPlaylist(String id) => '/community/$id';
  static const settings = '/settings';
  static const changePin = '/settings/pin';

  static const home = playlists;

  /// Screens that only exist to get through the [AppGate].
  static const gatePages = {splash, signIn, pinSetup, onboarding, unlock, kid};
}

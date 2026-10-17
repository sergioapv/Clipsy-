/// App-wide constants that are not build-time configuration.
abstract final class AppConfig {
  /// Deep link Supabase redirects to after a magic link or OAuth sign-in.
  /// Registered in AndroidManifest.xml, Info.plist and the Supabase dashboard.
  static const authRedirectScheme = 'app.clipsy';
  static const authRedirectHost = 'login-callback';
  static const authRedirectUri = '$authRedirectScheme://$authRedirectHost';

  /// Parent mode locks again when the app has been in the background longer
  /// than this.
  static const parentRelockAfter = Duration(minutes: 1);
}

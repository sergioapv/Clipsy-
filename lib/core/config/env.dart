/// Build-time configuration, injected with `--dart-define` or
/// `--dart-define-from-file=.env`. Nothing secret lives here: the Supabase
/// publishable (anon) key is designed to ship in clients, and Row Level
/// Security protects the data.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Accepts either the new `SUPABASE_PUBLISHABLE_KEY` name or the legacy
  /// `SUPABASE_ANON_KEY`.
  static const supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}

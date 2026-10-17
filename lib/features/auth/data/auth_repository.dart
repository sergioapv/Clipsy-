import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/app_user.dart';

/// Parent authentication. Widgets go through this, never through Supabase.
abstract interface class AuthRepository {
  AppUser? get currentUser;

  /// Emits the signed-in user (or `null`) now and on every change.
  Stream<AppUser?> authStateChanges();

  Future<void> sendMagicLink(String email);
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
    yield* _auth.onAuthStateChange
        .map((state) => _map(state.session?.user))
        .distinct();
  }

  @override
  Future<void> sendMagicLink(String email) => _auth.signInWithOtp(
    email: email.trim(),
    emailRedirectTo: AppConfig.authRedirectUri,
  );

  @override
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.authRedirectUri,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static AppUser? _map(User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? const {};
    return AppUser(
      id: user.id,
      email: user.email,
      displayName: (meta['display_name'] ?? meta['full_name']) as String?,
    );
  }
}

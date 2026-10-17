import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_store.dart';

/// Persists the Supabase session (refresh token included) in the platform
/// keystore instead of the default SharedPreferences.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this._store);

  static const _key = 'supabase.session';

  final SecureStore _store;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await _store.read(_key) != null;

  @override
  Future<String?> accessToken() => _store.read(_key);

  @override
  Future<void> removePersistedSession() => _store.delete(_key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(_key, persistSessionString);
}

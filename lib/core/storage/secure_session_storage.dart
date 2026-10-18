import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_store.dart';

/// Persists the Supabase session (refresh token included) in the platform
/// keystore instead of the default SharedPreferences.
///
/// Keystore reads can fail on some devices (e.g. keys invalidated by a
/// restore). A session we can't read is dropped, so the parent simply signs
/// in again instead of the app failing to start.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this._store);

  static const _key = 'supabase.session';

  final SecureStore _store;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _store.read(_key);
    } on Exception {
      await removePersistedSession();
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _store.delete(_key);
    } on Exception {
      // Nothing more we can do; the next write overwrites it.
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(_key, persistSessionString);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/env.dart';
import 'core/storage/secure_session_storage.dart';
import 'core/storage/secure_store.dart';
import 'core/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isSupabaseConfigured) {
    runApp(const ConfigMissingApp());
    return;
  }

  const secureStore = FlutterSecureStore();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: const SecureSessionStorage(secureStore),
      // Only treat our own callback as an auth redirect; other deep links
      // (e.g. "Share to Clipsy" later) must not be swallowed.
      detectSessionInUriPredicate: (uri) =>
          uri.scheme == AppConfig.authRedirectScheme &&
          uri.host == AppConfig.authRedirectHost,
    ),
  );
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Screens show errors with a retry button instead of silently retrying.
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStoreProvider.overrideWithValue(secureStore),
      ],
      child: const ClipsyApp(),
    ),
  );
}

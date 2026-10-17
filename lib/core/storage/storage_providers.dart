import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_store.dart';

part 'storage_providers.g.dart';

/// Overridden in `main()` with the instance loaded before `runApp`.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');

@Riverpod(keepAlive: true)
SecureStore secureStore(Ref ref) => const FlutterSecureStore();

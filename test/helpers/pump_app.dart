import 'package:clipsy/app.dart';
import 'package:clipsy/core/storage/secure_store.dart';
import 'package:clipsy/core/storage/storage_providers.dart';
import 'package:clipsy/features/auth/data/auth_repository.dart';
import 'package:clipsy/features/auth/data/pin_repository.dart';
import 'package:clipsy/features/auth/domain/pin.dart';
import 'package:clipsy/features/auth/presentation/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fast hasher for tests: few iterations, no isolate.
const testHasher = PinHasher(iterations: 2, useIsolate: false);

Future<void> pumpClipsy(
  WidgetTester tester, {
  required AuthRepository auth,
  InMemorySecureStore? store,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final secure = store ?? InMemorySecureStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        secureStoreProvider.overrideWithValue(secure),
        authRepositoryProvider.overrideWithValue(auth),
        pinRepositoryProvider.overrideWithValue(
          PinRepository(store: secure, hasher: testHasher),
        ),
      ],
      child: const ClipsyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(ValueKey('pin-key-$d')));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

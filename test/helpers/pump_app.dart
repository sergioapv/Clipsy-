import 'package:clipsy/app.dart';
import 'package:clipsy/core/storage/secure_store.dart';
import 'package:clipsy/core/storage/storage_providers.dart';
import 'package:clipsy/features/auth/data/auth_repository.dart';
import 'package:clipsy/features/auth/data/pin_repository.dart';
import 'package:clipsy/features/auth/domain/pin.dart';
import 'package:clipsy/features/auth/presentation/auth_providers.dart';
import 'package:clipsy/features/playlists/presentation/playlist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_playlists.dart';

/// Fast hasher for tests: few iterations, no isolate.
const testHasher = PinHasher(iterations: 2, useIsolate: false);

Future<void> pumpClipsy(
  WidgetTester tester, {
  required AuthRepository auth,
  InMemorySecureStore? store,
  Map<String, Object> prefs = const {},
  FakePlaylistRepository? playlists,
  FakeVideoLookupRepository? lookup,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final secure = store ?? InMemorySecureStore();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        playlistRepositoryProvider.overrideWithValue(
          playlists ?? FakePlaylistRepository(),
        ),
        labelRepositoryProvider.overrideWithValue(FakeLabelRepository()),
        videoLookupRepositoryProvider.overrideWithValue(
          lookup ?? FakeVideoLookupRepository(),
        ),
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

/// Starts the app already signed in and unlocked (PIN 2468), on the library.
Future<void> pumpUnlockedClipsy(
  WidgetTester tester, {
  required AuthRepository auth,
  FakePlaylistRepository? playlists,
  FakeVideoLookupRepository? lookup,
}) async {
  final store = InMemorySecureStore({
    'pin.hash': await testHasher.hash('2468'),
  });
  await pumpClipsy(
    tester,
    auth: auth,
    store: store,
    prefs: {'onboarding.complete': true},
    playlists: playlists,
    lookup: lookup,
  );
  await enterPin(tester, '2468');
}

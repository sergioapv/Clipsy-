import 'dart:async';

import 'package:clipsy/bootstrap.dart';
import 'package:clipsy/core/storage/secure_session_storage.dart';
import 'package:clipsy/core/storage/secure_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingStore implements SecureStore {
  var deletes = 0;

  @override
  Future<String?> read(String key) async =>
      throw PlatformException(code: 'keystore', message: 'unwrap failed');

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async => deletes++;
}

void main() {
  testWidgets(
    'a failing startup step is shown with a retry, not a frozen splash',
    (tester) async {
      var attempts = 0;
      final gate = Completer<void>();
      await tester.pumpWidget(
        StartupApp(
          bootstrap: () async {
            attempts++;
            await gate.future;
            throw const BootstrapException('Connecting to Supabase', 'boom');
          },
        ),
      );
      // Something is drawn straight away.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text("Clipsy couldn't start"), findsOneWidget);
      expect(
        find.textContaining('Connecting to Supabase: boom'),
        findsOneWidget,
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
    },
  );

  test(
    'an unreadable stored session is dropped instead of failing startup',
    () async {
      final store = _ThrowingStore();
      final storage = SecureSessionStorage(store);
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
      expect(store.deletes, greaterThan(0));
    },
  );
}

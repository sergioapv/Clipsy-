import 'package:clipsy/core/storage/secure_store.dart';
import 'package:clipsy/features/auth/domain/app_user.dart';
import 'package:clipsy/features/auth/presentation/onboarding_screen.dart';
import 'package:clipsy/features/auth/presentation/pin_setup_screen.dart';
import 'package:clipsy/features/auth/presentation/sign_in_screen.dart';
import 'package:clipsy/features/auth/presentation/unlock_screen.dart';
import 'package:clipsy/features/playlists/presentation/playlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

const _parent = AppUser(id: 'u1', email: 'parent@example.com');

void main() {
  testWidgets('signed-out parents land on sign-in and can request a link', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpClipsy(tester, auth: auth);
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(auth.sentLinks, isEmpty);

    await tester.enterText(find.byType(TextFormField), 'mum@example.com ');
    await tester.tap(find.text('Email me a sign-in link'));
    await tester.pumpAndSettle();
    expect(auth.sentLinks, ['mum@example.com']);
    expect(find.text('Check your email'), findsOneWidget);
  });

  testWidgets('first launch: sign in → create PIN → onboarding → home', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final store = InMemorySecureStore();
    await pumpClipsy(tester, auth: auth, store: store);

    auth.emit(_parent);
    await tester.pumpAndSettle();
    expect(find.byType(PinSetupScreen), findsOneWidget);

    await enterPin(tester, '1357');
    expect(find.text('Enter the PIN again'), findsOneWidget);
    await enterPin(tester, '1358');
    expect(find.text("The PINs didn't match. Try again."), findsOneWidget);

    await enterPin(tester, '1357');
    await enterPin(tester, '1357');
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(store.values.keys, contains('pin.hash'));

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistsScreen), findsOneWidget);
  });

  testWidgets('returning parent must enter the PIN to reach parent mode', (
    tester,
  ) async {
    final store = InMemorySecureStore({
      'pin.hash': await testHasher.hash('2468'),
    });
    await pumpClipsy(
      tester,
      auth: FakeAuthRepository(user: _parent),
      store: store,
      prefs: {'onboarding.complete': true},
    );
    expect(find.byType(UnlockScreen), findsOneWidget);

    await enterPin(tester, '1111');
    expect(find.text('Wrong PIN'), findsOneWidget);
    expect(find.byType(UnlockScreen), findsOneWidget);

    await enterPin(tester, '2468');
    expect(find.byType(PlaylistsScreen), findsOneWidget);

    // Settings → lock sends the parent back to the gate.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lock parent mode now'));
    await tester.pumpAndSettle();
    expect(find.byType(UnlockScreen), findsOneWidget);

    // And unlocking returns to Settings, not home.
    await enterPin(tester, '2468');
    expect(find.text('Lock parent mode now'), findsOneWidget);
  });

  testWidgets('forgot PIN signs out and clears the PIN', (tester) async {
    final auth = FakeAuthRepository(user: _parent);
    final store = InMemorySecureStore({
      'pin.hash': await testHasher.hash('2468'),
    });
    await pumpClipsy(
      tester,
      auth: auth,
      store: store,
      prefs: {'onboarding.complete': true},
    );

    await tester.tap(find.text('Forgot PIN?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in again'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(store.values, isEmpty);
  });

  testWidgets('Portuguese locale is supported', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('pt', 'PT')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpClipsy(tester, auth: FakeAuthRepository());
    expect(find.text('Enviar link de início de sessão'), findsOneWidget);
  });
}

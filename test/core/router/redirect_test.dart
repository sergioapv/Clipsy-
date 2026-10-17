import 'package:clipsy/core/router/app_gate.dart';
import 'package:clipsy/core/router/redirect.dart';
import 'package:clipsy/core/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? go(AppGate gate, String location) =>
      redirectFor(gate, Uri.parse(location));

  test('each gate sends the user to its screen', () {
    expect(go(AppGate.loading, Routes.home), Routes.splash);
    expect(go(AppGate.signedOut, Routes.home), Routes.signIn);
    expect(go(AppGate.needsPin, Routes.signIn), Routes.pinSetup);
    expect(go(AppGate.needsOnboarding, Routes.pinSetup), Routes.onboarding);
  });

  test('stays put when already on the gate screen', () {
    expect(go(AppGate.signedOut, Routes.signIn), isNull);
    expect(go(AppGate.locked, Routes.unlock), isNull);
  });

  test('locked remembers the page and returns to it after unlock', () {
    final target = go(AppGate.locked, Routes.settings)!;
    expect(Uri.parse(target).path, Routes.unlock);
    expect(Uri.parse(target).queryParameters['from'], Routes.settings);
    expect(go(AppGate.ready, target), Routes.settings);
  });

  test('ready leaves gate screens for home and allows parent screens', () {
    expect(go(AppGate.ready, Routes.signIn), Routes.home);
    expect(go(AppGate.ready, Routes.unlock), Routes.home);
    expect(go(AppGate.ready, Routes.settings), isNull);
  });

  test('ignores unsafe "from" values', () {
    for (final from in [
      'https://evil.example',
      '//evil.example',
      Routes.unlock,
    ]) {
      final loc = Uri(path: Routes.unlock, queryParameters: {'from': from});
      expect(go(AppGate.ready, loc.toString()), Routes.home, reason: from);
    }
  });

  test('signed-out users cannot reach parent screens', () {
    for (final path in [Routes.playlists, Routes.settings, Routes.changePin]) {
      expect(go(AppGate.signedOut, path), Routes.signIn);
    }
  });

  test('Kid mode overrides everything and nothing else is reachable', () {
    for (final path in [
      Routes.playlists,
      Routes.settings,
      Routes.signIn,
      Routes.unlock,
      Routes.changePin,
    ]) {
      expect(go(AppGate.kidMode, path), Routes.kid, reason: path);
    }
    expect(go(AppGate.kidMode, Routes.kid), isNull);
  });

  test('leaving Kid mode leaves the kid screen', () {
    expect(go(AppGate.ready, Routes.kid), Routes.home);
    expect(go(AppGate.locked, Routes.kid), Routes.unlock);
  });
}

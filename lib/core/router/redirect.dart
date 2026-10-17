import 'app_gate.dart';
import 'routes.dart';

/// Pure redirect rule, unit-tested without a widget tree.
///
/// Returns the location to go to, or `null` to stay on [location].
String? redirectFor(AppGate gate, Uri location) {
  final path = location.path;
  final gatePage = switch (gate) {
    AppGate.kidMode => Routes.kid,
    AppGate.loading => Routes.splash,
    AppGate.signedOut => Routes.signIn,
    AppGate.needsPin => Routes.pinSetup,
    AppGate.needsOnboarding => Routes.onboarding,
    AppGate.locked => Routes.unlock,
    AppGate.ready => null,
  };

  if (gatePage != null) {
    if (path == gatePage) return null;
    // Remember where a locked parent was, to return there after the PIN.
    if (gate == AppGate.locked && !Routes.gatePages.contains(path)) {
      return Uri(
        path: Routes.unlock,
        queryParameters: {'from': location.toString()},
      ).toString();
    }
    return gatePage;
  }

  if (Routes.gatePages.contains(path)) {
    final from = location.queryParameters['from'];
    if (path == Routes.unlock && from != null && _isSafeInternal(from)) {
      return from;
    }
    return Routes.home;
  }
  return null;
}

bool _isSafeInternal(String from) {
  final uri = Uri.tryParse(from);
  return uri != null &&
      !uri.hasScheme &&
      !uri.hasAuthority &&
      uri.path.startsWith('/') &&
      !Routes.gatePages.contains(uri.path);
}

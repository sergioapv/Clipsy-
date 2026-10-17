import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/kid_mode/presentation/kid_mode_controller.dart';

part 'app_gate.g.dart';

/// The first thing standing between the user and parent mode. The router
/// sends the user to the matching screen until the gate is [ready].
enum AppGate {
  /// A Kid mode session is active: nothing else is reachable.
  kidMode,
  loading,
  signedOut,
  needsPin,
  needsOnboarding,
  locked,
  ready,
}

@Riverpod(keepAlive: true)
AppGate appGate(Ref ref) {
  // Checked first and works offline/signed out: a restarted app must go
  // straight back to Kid mode.
  if (ref.watch(kidModeProvider.select((s) => s != null))) {
    return AppGate.kidMode;
  }
  final auth = ref.watch(authStateProvider);
  if (!auth.hasValue && !auth.hasError) return AppGate.loading;
  if (auth.value == null) return AppGate.signedOut;

  final pin = ref.watch(pinStatusProvider);
  if (!pin.hasValue) return AppGate.loading;
  if (pin.value != true) return AppGate.needsPin;

  if (!ref.watch(onboardingStatusProvider)) return AppGate.needsOnboarding;
  if (!ref.watch(parentSessionProvider)) return AppGate.locked;
  return AppGate.ready;
}

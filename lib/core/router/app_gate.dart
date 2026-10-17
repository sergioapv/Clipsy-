import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_providers.dart';

part 'app_gate.g.dart';

/// The first thing standing between the user and parent mode. The router
/// sends the user to the matching screen until the gate is [ready].
enum AppGate { loading, signedOut, needsPin, needsOnboarding, locked, ready }

@Riverpod(keepAlive: true)
AppGate appGate(Ref ref) {
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

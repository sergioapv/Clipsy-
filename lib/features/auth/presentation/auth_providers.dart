import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/auth_repository.dart';
import '../data/pin_repository.dart';
import '../domain/app_user.dart';
import '../domain/pin_check_result.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    SupabaseAuthRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges();

@Riverpod(keepAlive: true)
PinRepository pinRepository(Ref ref) =>
    PinRepository(store: ref.watch(secureStoreProvider));

/// Whether a parent PIN exists on this device.
@Riverpod(keepAlive: true)
class PinStatus extends _$PinStatus {
  @override
  Future<bool> build() => ref.watch(pinRepositoryProvider).hasPin();

  Future<void> setPin(String pin) async {
    await ref.read(pinRepositoryProvider).setPin(pin);
    state = const AsyncData(true);
  }

  Future<void> clear() async {
    await ref.read(pinRepositoryProvider).clear();
    state = const AsyncData(false);
  }
}

/// Whether the parent has finished (or skipped) onboarding on this device.
@Riverpod(keepAlive: true)
class OnboardingStatus extends _$OnboardingStatus {
  static const _key = 'onboarding.complete';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> complete() async {
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }
}

/// Whether parent mode is currently unlocked with the PIN. Starts locked on
/// every cold start; [ClipsyApp] relocks it after time in the background.
@Riverpod(keepAlive: true)
class ParentSession extends _$ParentSession {
  @override
  bool build() => false;

  /// Checks [pin] and unlocks on success.
  Future<PinCheckResult> unlockWithPin(String pin) async {
    final result = await ref.read(pinRepositoryProvider).verify(pin);
    if (result is PinAccepted) state = true;
    return result;
  }

  /// Used right after the parent sets a new PIN.
  void markUnlocked() => state = true;

  void lock() => state = false;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  void build() {}

  /// Signs out and removes the device PIN, so the next parent to sign in sets
  /// their own. Also the "forgot PIN" path: re-authenticating is the reset.
  Future<void> signOut() async {
    ref.read(parentSessionProvider.notifier).lock();
    await ref.read(pinStatusProvider.notifier).clear();
    await ref.read(authRepositoryProvider).signOut();
  }
}

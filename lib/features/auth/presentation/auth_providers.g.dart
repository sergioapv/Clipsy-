// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'e250063afa9b4c2b12a0a86d6b995516fe0ab0ae';

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'6ce439e56f78a7861b8f3d71d298011f47656b9a';

@ProviderFor(pinRepository)
final pinRepositoryProvider = PinRepositoryProvider._();

final class PinRepositoryProvider
    extends $FunctionalProvider<PinRepository, PinRepository, PinRepository>
    with $Provider<PinRepository> {
  PinRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinRepositoryHash();

  @$internal
  @override
  $ProviderElement<PinRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PinRepository create(Ref ref) {
    return pinRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PinRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PinRepository>(value),
    );
  }
}

String _$pinRepositoryHash() => r'ffccc4ab4a525a636765767ecb573d817f4df8a9';

/// Whether a parent PIN exists on this device.

@ProviderFor(PinStatus)
final pinStatusProvider = PinStatusProvider._();

/// Whether a parent PIN exists on this device.
final class PinStatusProvider extends $AsyncNotifierProvider<PinStatus, bool> {
  /// Whether a parent PIN exists on this device.
  PinStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinStatusHash();

  @$internal
  @override
  PinStatus create() => PinStatus();
}

String _$pinStatusHash() => r'aa34b503e69157a1966a69da941e17620de3aae2';

/// Whether a parent PIN exists on this device.

abstract class _$PinStatus extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the parent has finished (or skipped) onboarding on this device.

@ProviderFor(OnboardingStatus)
final onboardingStatusProvider = OnboardingStatusProvider._();

/// Whether the parent has finished (or skipped) onboarding on this device.
final class OnboardingStatusProvider
    extends $NotifierProvider<OnboardingStatus, bool> {
  /// Whether the parent has finished (or skipped) onboarding on this device.
  OnboardingStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStatusHash();

  @$internal
  @override
  OnboardingStatus create() => OnboardingStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingStatusHash() => r'88f571bb11729016f7a9b4dbd86d72d117a8b395';

/// Whether the parent has finished (or skipped) onboarding on this device.

abstract class _$OnboardingStatus extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether parent mode is currently unlocked with the PIN. Starts locked on
/// every cold start; [ClipsyApp] relocks it after time in the background.

@ProviderFor(ParentSession)
final parentSessionProvider = ParentSessionProvider._();

/// Whether parent mode is currently unlocked with the PIN. Starts locked on
/// every cold start; [ClipsyApp] relocks it after time in the background.
final class ParentSessionProvider
    extends $NotifierProvider<ParentSession, bool> {
  /// Whether parent mode is currently unlocked with the PIN. Starts locked on
  /// every cold start; [ClipsyApp] relocks it after time in the background.
  ParentSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'parentSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$parentSessionHash();

  @$internal
  @override
  ParentSession create() => ParentSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$parentSessionHash() => r'c25ec200e96117bcb723fbcb58b77df05b0b34e1';

/// Whether parent mode is currently unlocked with the PIN. Starts locked on
/// every cold start; [ClipsyApp] relocks it after time in the background.

abstract class _$ParentSession extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

final class AuthControllerProvider
    extends $NotifierProvider<AuthController, void> {
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$authControllerHash() => r'0b81bdb6c8e7e9470c2aad37dc7c331e3cd62a69';

abstract class _$AuthController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

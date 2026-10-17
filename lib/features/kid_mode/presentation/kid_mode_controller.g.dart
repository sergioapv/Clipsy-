// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kid_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kidSettingsRepository)
final kidSettingsRepositoryProvider = KidSettingsRepositoryProvider._();

final class KidSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          KidSettingsRepository,
          KidSettingsRepository,
          KidSettingsRepository
        >
    with $Provider<KidSettingsRepository> {
  KidSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kidSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kidSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<KidSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KidSettingsRepository create(Ref ref) {
    return kidSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KidSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KidSettingsRepository>(value),
    );
  }
}

String _$kidSettingsRepositoryHash() =>
    r'228b87a7c9e6533285405fe0a79057f1bf0ec582';

@ProviderFor(kidSessionStore)
final kidSessionStoreProvider = KidSessionStoreProvider._();

final class KidSessionStoreProvider
    extends
        $FunctionalProvider<KidSessionStore, KidSessionStore, KidSessionStore>
    with $Provider<KidSessionStore> {
  KidSessionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kidSessionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kidSessionStoreHash();

  @$internal
  @override
  $ProviderElement<KidSessionStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KidSessionStore create(Ref ref) {
    return kidSessionStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KidSessionStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KidSessionStore>(value),
    );
  }
}

String _$kidSessionStoreHash() => r'fd49bdc3d83bb26378e602ec5336a0fd9c3a8b32';

@ProviderFor(deviceLock)
final deviceLockProvider = DeviceLockProvider._();

final class DeviceLockProvider
    extends $FunctionalProvider<DeviceLock, DeviceLock, DeviceLock>
    with $Provider<DeviceLock> {
  DeviceLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceLockHash();

  @$internal
  @override
  $ProviderElement<DeviceLock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceLock create(Ref ref) {
    return deviceLock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceLock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceLock>(value),
    );
  }
}

String _$deviceLockHash() => r'bbfcec1682eb4c4ea2cc61aba66fbafd22302e1e';

/// The player for the Kid mode screen; disposed with it.

@ProviderFor(kidPlayer)
final kidPlayerProvider = KidPlayerProvider._();

/// The player for the Kid mode screen; disposed with it.

final class KidPlayerProvider
    extends $FunctionalProvider<KidPlayer, KidPlayer, KidPlayer>
    with $Provider<KidPlayer> {
  /// The player for the Kid mode screen; disposed with it.
  KidPlayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kidPlayerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kidPlayerHash();

  @$internal
  @override
  $ProviderElement<KidPlayer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KidPlayer create(Ref ref) {
    return kidPlayer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KidPlayer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KidPlayer>(value),
    );
  }
}

String _$kidPlayerHash() => r'08f8f7341776e5016b861d5e0e9fa022a4c3526a';

@ProviderFor(KidSettings)
final kidSettingsProvider = KidSettingsProvider._();

final class KidSettingsProvider
    extends $NotifierProvider<KidSettings, KidModeSettings> {
  KidSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kidSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kidSettingsHash();

  @$internal
  @override
  KidSettings create() => KidSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KidModeSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KidModeSettings>(value),
    );
  }
}

String _$kidSettingsHash() => r'ce86664690f1809ca9f26f745d79f2feb0966e7a';

abstract class _$KidSettings extends $Notifier<KidModeSettings> {
  KidModeSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<KidModeSettings, KidModeSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KidModeSettings, KidModeSettings>,
              KidModeSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The active Kid mode session (or `null` in parent mode).
///
/// Every change is persisted, so killing the app resumes Kid mode with the
/// same remaining time.

@ProviderFor(KidMode)
final kidModeProvider = KidModeProvider._();

/// The active Kid mode session (or `null` in parent mode).
///
/// Every change is persisted, so killing the app resumes Kid mode with the
/// same remaining time.
final class KidModeProvider extends $NotifierProvider<KidMode, KidModeState?> {
  /// The active Kid mode session (or `null` in parent mode).
  ///
  /// Every change is persisted, so killing the app resumes Kid mode with the
  /// same remaining time.
  KidModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kidModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kidModeHash();

  @$internal
  @override
  KidMode create() => KidMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KidModeState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KidModeState?>(value),
    );
  }
}

String _$kidModeHash() => r'be4843ed3f485b3078298968e9fa5e4baab0daf3';

/// The active Kid mode session (or `null` in parent mode).
///
/// Every change is persisted, so killing the app resumes Kid mode with the
/// same remaining time.

abstract class _$KidMode extends $Notifier<KidModeState?> {
  KidModeState? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<KidModeState?, KidModeState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KidModeState?, KidModeState?>,
              KidModeState?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

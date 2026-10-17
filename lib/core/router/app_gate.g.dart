// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appGate)
final appGateProvider = AppGateProvider._();

final class AppGateProvider
    extends $FunctionalProvider<AppGate, AppGate, AppGate>
    with $Provider<AppGate> {
  AppGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appGateHash();

  @$internal
  @override
  $ProviderElement<AppGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppGate create(Ref ref) {
    return appGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppGate>(value),
    );
  }
}

String _$appGateHash() => r'59c1f81203aa718adb0eab424f4c4b39ac32d9c8';

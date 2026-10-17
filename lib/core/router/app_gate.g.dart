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

String _$appGateHash() => r'82f63a97ef8c4e968725ff5ac208ddde0bebf848';

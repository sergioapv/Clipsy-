// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(communityRepository)
final communityRepositoryProvider = CommunityRepositoryProvider._();

final class CommunityRepositoryProvider
    extends
        $FunctionalProvider<
          CommunityRepository,
          CommunityRepository,
          CommunityRepository
        >
    with $Provider<CommunityRepository> {
  CommunityRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'communityRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$communityRepositoryHash();

  @$internal
  @override
  $ProviderElement<CommunityRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CommunityRepository create(Ref ref) {
    return communityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommunityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommunityRepository>(value),
    );
  }
}

String _$communityRepositoryHash() =>
    r'469902ba450233e2e271a0a1fdd3d6220633e281';

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'9ce0dc7c7cccd011e7ef202f77acac629e2a3592';

/// The community library for a [CommunityQuery], loaded a page at a time.

@ProviderFor(CommunityFeed)
final communityFeedProvider = CommunityFeedFamily._();

/// The community library for a [CommunityQuery], loaded a page at a time.
final class CommunityFeedProvider
    extends $AsyncNotifierProvider<CommunityFeed, CommunityPage> {
  /// The community library for a [CommunityQuery], loaded a page at a time.
  CommunityFeedProvider._({
    required CommunityFeedFamily super.from,
    required CommunityQuery super.argument,
  }) : super(
         retry: null,
         name: r'communityFeedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$communityFeedHash();

  @override
  String toString() {
    return r'communityFeedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommunityFeed create() => CommunityFeed();

  @override
  bool operator ==(Object other) {
    return other is CommunityFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communityFeedHash() => r'a39e9542f2cc84c8aaf04c6d82713ba12720f228';

/// The community library for a [CommunityQuery], loaded a page at a time.

final class CommunityFeedFamily extends $Family
    with
        $ClassFamilyOverride<
          CommunityFeed,
          AsyncValue<CommunityPage>,
          CommunityPage,
          FutureOr<CommunityPage>,
          CommunityQuery
        > {
  CommunityFeedFamily._()
    : super(
        retry: null,
        name: r'communityFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The community library for a [CommunityQuery], loaded a page at a time.

  CommunityFeedProvider call(CommunityQuery query) =>
      CommunityFeedProvider._(argument: query, from: this);

  @override
  String toString() => r'communityFeedProvider';
}

/// The community library for a [CommunityQuery], loaded a page at a time.

abstract class _$CommunityFeed extends $AsyncNotifier<CommunityPage> {
  late final _$args = ref.$arg as CommunityQuery;
  CommunityQuery get query => _$args;

  FutureOr<CommunityPage> build(CommunityQuery query);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CommunityPage>, CommunityPage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CommunityPage>, CommunityPage>,
              AsyncValue<CommunityPage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// One community playlist, with the parent's actions on it.

@ProviderFor(CommunityDetail)
final communityDetailProvider = CommunityDetailFamily._();

/// One community playlist, with the parent's actions on it.
final class CommunityDetailProvider
    extends $AsyncNotifierProvider<CommunityDetail, CommunityPlaylistDetail> {
  /// One community playlist, with the parent's actions on it.
  CommunityDetailProvider._({
    required CommunityDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'communityDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$communityDetailHash();

  @override
  String toString() {
    return r'communityDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommunityDetail create() => CommunityDetail();

  @override
  bool operator ==(Object other) {
    return other is CommunityDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communityDetailHash() => r'78760e22222090838dfaaf27cd91d1db8ff01e1f';

/// One community playlist, with the parent's actions on it.

final class CommunityDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          CommunityDetail,
          AsyncValue<CommunityPlaylistDetail>,
          CommunityPlaylistDetail,
          FutureOr<CommunityPlaylistDetail>,
          String
        > {
  CommunityDetailFamily._()
    : super(
        retry: null,
        name: r'communityDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One community playlist, with the parent's actions on it.

  CommunityDetailProvider call(String id) =>
      CommunityDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'communityDetailProvider';
}

/// One community playlist, with the parent's actions on it.

abstract class _$CommunityDetail
    extends $AsyncNotifier<CommunityPlaylistDetail> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<CommunityPlaylistDetail> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CommunityPlaylistDetail>,
              CommunityPlaylistDetail
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CommunityPlaylistDetail>,
                CommunityPlaylistDetail
              >,
              AsyncValue<CommunityPlaylistDetail>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The name shown on the parent's published playlists.

@ProviderFor(MyDisplayName)
final myDisplayNameProvider = MyDisplayNameProvider._();

/// The name shown on the parent's published playlists.
final class MyDisplayNameProvider
    extends $AsyncNotifierProvider<MyDisplayName, String> {
  /// The name shown on the parent's published playlists.
  MyDisplayNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myDisplayNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myDisplayNameHash();

  @$internal
  @override
  MyDisplayName create() => MyDisplayName();
}

String _$myDisplayNameHash() => r'd1263351c8f3939024ddd58fa11179a52ada8131';

/// The name shown on the parent's published playlists.

abstract class _$MyDisplayName extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

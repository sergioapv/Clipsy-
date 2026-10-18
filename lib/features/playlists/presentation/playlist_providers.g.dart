// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playlistRepository)
final playlistRepositoryProvider = PlaylistRepositoryProvider._();

final class PlaylistRepositoryProvider
    extends
        $FunctionalProvider<
          PlaylistRepository,
          PlaylistRepository,
          PlaylistRepository
        >
    with $Provider<PlaylistRepository> {
  PlaylistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playlistRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playlistRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaylistRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaylistRepository create(Ref ref) {
    return playlistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaylistRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaylistRepository>(value),
    );
  }
}

String _$playlistRepositoryHash() =>
    r'acea160a32cbc7d78d492b50bfd3535b0c556b93';

@ProviderFor(labelRepository)
final labelRepositoryProvider = LabelRepositoryProvider._();

final class LabelRepositoryProvider
    extends
        $FunctionalProvider<LabelRepository, LabelRepository, LabelRepository>
    with $Provider<LabelRepository> {
  LabelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelRepositoryHash();

  @$internal
  @override
  $ProviderElement<LabelRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LabelRepository create(Ref ref) {
    return labelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabelRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabelRepository>(value),
    );
  }
}

String _$labelRepositoryHash() => r'720dcad1caef1b4bf4899e52061accb7b5f2528e';

@ProviderFor(videoLookupRepository)
final videoLookupRepositoryProvider = VideoLookupRepositoryProvider._();

final class VideoLookupRepositoryProvider
    extends
        $FunctionalProvider<
          VideoLookupRepository,
          VideoLookupRepository,
          VideoLookupRepository
        >
    with $Provider<VideoLookupRepository> {
  VideoLookupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoLookupRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoLookupRepositoryHash();

  @$internal
  @override
  $ProviderElement<VideoLookupRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoLookupRepository create(Ref ref) {
    return videoLookupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoLookupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoLookupRepository>(value),
    );
  }
}

String _$videoLookupRepositoryHash() =>
    r'49eed8a1faf2a77eb6bf5ba08b68513f9cfed9c4';

/// The parent-mode YouTube browser; disposed with its screen.

@ProviderFor(inAppBrowser)
final inAppBrowserProvider = InAppBrowserProvider._();

/// The parent-mode YouTube browser; disposed with its screen.

final class InAppBrowserProvider
    extends $FunctionalProvider<InAppBrowser, InAppBrowser, InAppBrowser>
    with $Provider<InAppBrowser> {
  /// The parent-mode YouTube browser; disposed with its screen.
  InAppBrowserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inAppBrowserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inAppBrowserHash();

  @$internal
  @override
  $ProviderElement<InAppBrowser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InAppBrowser create(Ref ref) {
    return inAppBrowser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InAppBrowser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InAppBrowser>(value),
    );
  }
}

String _$inAppBrowserHash() => r'20917f43ea6aae396e47f14716ab255989b77e70';

@ProviderFor(youTubePlaylistRepository)
final youTubePlaylistRepositoryProvider = YouTubePlaylistRepositoryProvider._();

final class YouTubePlaylistRepositoryProvider
    extends
        $FunctionalProvider<
          YouTubePlaylistRepository,
          YouTubePlaylistRepository,
          YouTubePlaylistRepository
        >
    with $Provider<YouTubePlaylistRepository> {
  YouTubePlaylistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'youTubePlaylistRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$youTubePlaylistRepositoryHash();

  @$internal
  @override
  $ProviderElement<YouTubePlaylistRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  YouTubePlaylistRepository create(Ref ref) {
    return youTubePlaylistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(YouTubePlaylistRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<YouTubePlaylistRepository>(value),
    );
  }
}

String _$youTubePlaylistRepositoryHash() =>
    r'5919f8df60e004182eda102d7c242bf9591f1f61';

/// All labels, in display order. Rarely changes, so kept for the session.

@ProviderFor(labels)
final labelsProvider = LabelsProvider._();

/// All labels, in display order. Rarely changes, so kept for the session.

final class LabelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Label>>,
          List<Label>,
          FutureOr<List<Label>>
        >
    with $FutureModifier<List<Label>>, $FutureProvider<List<Label>> {
  /// All labels, in display order. Rarely changes, so kept for the session.
  LabelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelsHash();

  @$internal
  @override
  $FutureProviderElement<List<Label>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Label>> create(Ref ref) {
    return labels(ref);
  }
}

String _$labelsHash() => r'973dda8fdd57e3c70e15c617437a12585d133ef9';

/// The parent's library.

@ProviderFor(MyPlaylists)
final myPlaylistsProvider = MyPlaylistsProvider._();

/// The parent's library.
final class MyPlaylistsProvider
    extends $AsyncNotifierProvider<MyPlaylists, List<Playlist>> {
  /// The parent's library.
  MyPlaylistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPlaylistsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPlaylistsHash();

  @$internal
  @override
  MyPlaylists create() => MyPlaylists();
}

String _$myPlaylistsHash() => r'dbcc32a42ccd479f2c1fbab5a3c83c041d5611c7';

/// The parent's library.

abstract class _$MyPlaylists extends $AsyncNotifier<List<Playlist>> {
  FutureOr<List<Playlist>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Playlist>>, List<Playlist>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Playlist>>, List<Playlist>>,
              AsyncValue<List<Playlist>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// One playlist with its videos, plus the edits made on its screen.

@ProviderFor(PlaylistDetailController)
final playlistDetailControllerProvider = PlaylistDetailControllerFamily._();

/// One playlist with its videos, plus the edits made on its screen.
final class PlaylistDetailControllerProvider
    extends $AsyncNotifierProvider<PlaylistDetailController, PlaylistDetail> {
  /// One playlist with its videos, plus the edits made on its screen.
  PlaylistDetailControllerProvider._({
    required PlaylistDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playlistDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playlistDetailControllerHash();

  @override
  String toString() {
    return r'playlistDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaylistDetailController create() => PlaylistDetailController();

  @override
  bool operator ==(Object other) {
    return other is PlaylistDetailControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playlistDetailControllerHash() =>
    r'58a61630fb35eff936c1433df19ab3b273393764';

/// One playlist with its videos, plus the edits made on its screen.

final class PlaylistDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PlaylistDetailController,
          AsyncValue<PlaylistDetail>,
          PlaylistDetail,
          FutureOr<PlaylistDetail>,
          String
        > {
  PlaylistDetailControllerFamily._()
    : super(
        retry: null,
        name: r'playlistDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One playlist with its videos, plus the edits made on its screen.

  PlaylistDetailControllerProvider call(String playlistId) =>
      PlaylistDetailControllerProvider._(argument: playlistId, from: this);

  @override
  String toString() => r'playlistDetailControllerProvider';
}

/// One playlist with its videos, plus the edits made on its screen.

abstract class _$PlaylistDetailController
    extends $AsyncNotifier<PlaylistDetail> {
  late final _$args = ref.$arg as String;
  String get playlistId => _$args;

  FutureOr<PlaylistDetail> build(String playlistId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PlaylistDetail>, PlaylistDetail>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlaylistDetail>, PlaylistDetail>,
              AsyncValue<PlaylistDetail>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

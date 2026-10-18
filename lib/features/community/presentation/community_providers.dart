import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../playlists/presentation/playlist_providers.dart';
import '../data/community_repository.dart';
import '../data/profile_repository.dart';
import '../domain/community_playlist.dart';

part 'community_providers.g.dart';

@Riverpod(keepAlive: true)
CommunityRepository communityRepository(Ref ref) =>
    SupabaseCommunityRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    SupabaseProfileRepository(ref.watch(supabaseClientProvider));

/// Loaded pages of the community library for one query.
@immutable
class CommunityPage {
  const CommunityPage({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<CommunityPlaylist> items;
  final bool hasMore;
  final bool loadingMore;
}

/// The community library for a [CommunityQuery], loaded a page at a time.
@riverpod
class CommunityFeed extends _$CommunityFeed {
  @override
  Future<CommunityPage> build(CommunityQuery query) async {
    final items = await ref.watch(communityRepositoryProvider).browse(query);
    return CommunityPage(
      items: items,
      hasMore: items.length == CommunityRepository.pageSize,
    );
  }

  /// Appends the next page. Failures keep what's loaded and stop paging until
  /// the next refresh.
  Future<void> loadMore() async {
    final page = state.value;
    if (page == null || !page.hasMore || page.loadingMore) return;
    state = AsyncData(
      CommunityPage(items: page.items, hasMore: true, loadingMore: true),
    );
    try {
      final more = await ref
          .read(communityRepositoryProvider)
          .browse(query, offset: page.items.length);
      if (!ref.mounted) return;
      final seen = {for (final p in page.items) p.id};
      state = AsyncData(
        CommunityPage(
          items: [...page.items, ...more.where((p) => !seen.contains(p.id))],
          hasMore: more.length == CommunityRepository.pageSize,
        ),
      );
    } on Exception {
      if (!ref.mounted) return;
      state = AsyncData(CommunityPage(items: page.items, hasMore: false));
    }
  }
}

/// One community playlist, with the parent's actions on it.
@riverpod
class CommunityDetail extends _$CommunityDetail {
  @override
  Future<CommunityPlaylistDetail> build(String id) =>
      ref.watch(communityRepositoryProvider).fetchDetail(id);

  /// Rates the playlist; the aggregate is reloaded from the server.
  Future<void> rate(int stars) async {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(myRating: stars));
    try {
      await ref.read(communityRepositoryProvider).rate(id, stars);
    } catch (_) {
      if (ref.mounted && current != null) state = AsyncData(current);
      rethrow;
    }
    final fresh = await ref.read(communityRepositoryProvider).fetchDetail(id);
    if (ref.mounted) state = AsyncData(fresh);
    // Lists showing the old average.
    ref.invalidate(communityFeedProvider);
  }

  /// Saves a copy to the parent's library; returns the new playlist's id.
  Future<String> saveToLibrary() async {
    final newId = await ref.read(communityRepositoryProvider).fork(id);
    ref.invalidate(myPlaylistsProvider);
    return newId;
  }

  Future<void> report(ReportReason reason, {String? details}) => ref
      .read(communityRepositoryProvider)
      .report(id, reason, details: details);
}

/// The name shown on the parent's published playlists.
@riverpod
class MyDisplayName extends _$MyDisplayName {
  @override
  Future<String> build() =>
      ref.watch(profileRepositoryProvider).fetchDisplayName();

  Future<void> save(String name) async {
    await ref.read(profileRepositoryProvider).updateDisplayName(name);
    state = AsyncData(name.trim());
    ref.invalidate(communityFeedProvider);
    ref.invalidate(communityDetailProvider);
  }
}

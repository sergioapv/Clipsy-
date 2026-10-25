import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/languages.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../playlists/domain/label.dart';
import '../../playlists/domain/playlist.dart';
import '../../playlists/presentation/playlist_l10n.dart';
import '../../playlists/presentation/playlist_providers.dart';
import '../../playlists/presentation/widgets/language_picker.dart';
import '../domain/community_playlist.dart';
import 'community_providers.dart';
import 'widgets/community_playlist_card.dart';

enum _Tab { topRated, newest, byLabel }

/// The community library: playlists other parents shared. Top rated, new,
/// or by label; filtered by age and searched by title.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  _Tab _tab = _Tab.topRated;
  String? _label;
  AgeRange? _age;
  LanguageFilter? _language;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickLanguage() async {
    final pick = await showLanguageFilterPicker(context, current: _language);
    if (pick != null && mounted) setState(() => _language = pick.filter);
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = text);
    });
  }

  CommunityQuery get _communityQuery => CommunityQuery(
    sort: _tab == _Tab.newest ? CommunitySort.newest : CommunitySort.topRated,
    labelSlug: _tab == _Tab.byLabel ? _label : null,
    ageRange: _age,
    language: _language,
    search: _query,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pickingLabel = _tab == _Tab.byLabel && _label == null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCommunity)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              key: const Key('community-search'),
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.communitySearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        onPressed: () {
                          _search.clear();
                          _debounce?.cancel();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<_Tab>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _Tab.topRated,
                  label: Text(l10n.communityTopRated),
                ),
                ButtonSegment(
                  value: _Tab.newest,
                  label: Text(l10n.communityNew),
                ),
                ButtonSegment(
                  value: _Tab.byLabel,
                  label: Text(l10n.communityByLabel),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.single),
            ),
          ),
          const SizedBox(height: 10),
          _AgeFilter(
            leading: LanguageFilterChip(
              key: const Key('community-language-filter'),
              filter: _language,
              onPressed: () => unawaited(_pickLanguage()),
              onClear: () => setState(() => _language = null),
            ),
            value: _age,
            onChanged: (age) => setState(() => _age = age),
          ),
          if (_tab == _Tab.byLabel && _label != null)
            _SelectedLabel(
              slug: _label!,
              onClear: () => setState(() => _label = null),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: pickingLabel
                ? _LabelPicker(onPicked: (s) => setState(() => _label = s))
                : _Feed(query: _communityQuery),
          ),
        ],
      ),
    );
  }
}

class _AgeFilter extends StatelessWidget {
  const _AgeFilter({
    required this.value,
    required this.onChanged,
    this.leading,
  });

  final AgeRange? value;
  final ValueChanged<AgeRange?> onChanged;

  /// Shown before the age chips (the language filter).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (leading != null)
            Padding(padding: const EdgeInsets.only(right: 8), child: leading),
          for (final age in <AgeRange?>[null, ...AgeRange.presets])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('age-filter-${age ?? 'all'}'),
                label: Text(
                  age == null ? l10n.communityAllAges : l10n.ageRangeLabel(age),
                ),
                selected: value == age,
                showCheckmark: false,
                onSelected: (_) => onChanged(age),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedLabel extends ConsumerWidget {
  const _SelectedLabel({required this.slug, required this.onClear});

  final String slug;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final label = ref
        .watch(labelsProvider)
        .value
        ?.where((l) => l.slug == slug)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          key: const Key('selected-label'),
          label: Text(label == null ? slug : l10n.labelName(label)),
          selected: true,
          showCheckmark: false,
          onDeleted: onClear,
          deleteIcon: const Icon(Icons.close_rounded, size: 18),
          onPressed: onClear,
        ),
      ),
    );
  }
}

class _LabelPicker extends ConsumerWidget {
  const _LabelPicker({required this.onPicked});

  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ref
        .watch(labelsProvider)
        .when(
          loading: () => const SkeletonList(count: 3),
          error: (e, _) => ErrorView(
            message: l10n.playlistError(e),
            onRetry: () => ref.invalidate(labelsProvider),
          ),
          data: (labels) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(l10n.communityPickLabel, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final Label label in labels)
                    ActionChip(
                      key: Key('pick-label-${label.slug}'),
                      label: Text(l10n.labelName(label)),
                      onPressed: () => onPicked(label.slug),
                    ),
                ],
              ),
            ],
          ),
        );
  }
}

class _Feed extends ConsumerWidget {
  const _Feed({required this.query});

  final CommunityQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = communityFeedProvider(query);
    final me = ref.watch(authStateProvider).value?.id;
    return ref
        .watch(provider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorView(
            message: l10n.playlistError(e),
            onRetry: () => ref.invalidate(provider),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return EmptyState(
                icon: Icons.public_rounded,
                title: l10n.communityEmptyTitle,
                message: l10n.communityEmptyBody,
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(provider.future),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: page.items.length + (page.hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= page.items.length) {
                    // Reached the end of what's loaded: fetch the next page.
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => unawaited(ref.read(provider.notifier).loadMore()),
                    );
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final p = page.items[i];
                  return CommunityPlaylistCard(
                    key: ValueKey(p.id),
                    playlist: p,
                    isMine: p.ownerId == me,
                  );
                },
              ),
            );
          },
        );
  }
}

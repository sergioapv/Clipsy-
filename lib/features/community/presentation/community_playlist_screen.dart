import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../playlists/domain/playlist.dart';
import '../../playlists/presentation/playlist_l10n.dart';
import '../../playlists/presentation/widgets/label_chips.dart';
import '../../playlists/presentation/widgets/video_thumbnail.dart';
import '../domain/community_playlist.dart';
import 'community_providers.dart';
import 'report_sheet.dart';
import 'widgets/star_rating.dart';

/// A shared playlist: its videos, saving a copy, rating and reporting.
class CommunityPlaylistScreen extends ConsumerWidget {
  const CommunityPlaylistScreen({required this.playlistId, super.key});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = communityDetailProvider(playlistId);
    final detail = ref.watch(provider);
    final canReport = detail.value != null && !detail.value!.isMine;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (canReport)
            PopupMenuButton<void>(
              key: const Key('community-menu'),
              tooltip: l10n.moreOptions,
              icon: const Icon(Icons.more_vert_rounded),
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: const Key('community-report'),
                  onTap: () => unawaited(_report(context, ref)),
                  child: Text(l10n.reportPlaylist),
                ),
              ],
            ),
        ],
      ),
      body: detail.when(
        skipLoadingOnReload: true,
        loading: () => const SkeletonList(thumbnailWidth: 112),
        error: (e, _) => ErrorView(
          message: l10n.playlistError(e),
          onRetry: () => ref.invalidate(provider),
        ),
        data: (d) => _Body(detail: d),
      ),
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final answer = await showReportSheet(context);
    if (answer == null) return;
    try {
      await ref
          .read(communityDetailProvider(playlistId).notifier)
          .report(answer.reason, details: answer.details);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.reportSent)));
    } on Exception catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.playlistError(e))));
    }
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.detail});

  final CommunityPlaylistDetail detail;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _saving = false;
  bool _rating = false;

  CommunityDetail get _controller =>
      ref.read(communityDetailProvider(widget.detail.playlist.id).notifier);

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    try {
      final id = await _controller.saveToLibrary();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.communitySaved),
            action: SnackBarAction(
              label: l10n.communityOpen,
              onPressed: () => router.go(Routes.playlist(id)),
            ),
          ),
        );
    } on Exception catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.playlistError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _rate(int stars) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _rating = true);
    try {
      await _controller.rate(stars);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.communityRateThanks)));
    } on Exception catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.playlistError(e))));
    } finally {
      if (mounted) setState(() => _rating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final d = widget.detail;
    final p = d.playlist;
    final minutes = p.totalDurationSeconds == null
        ? null
        : (p.totalDurationSeconds! / 60).ceil();
    final description = p.description;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(p.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          d.isMine ? l10n.communityYours : l10n.communityByAuthor(p.authorName),
          style: theme.textTheme.bodyLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: 10),
        RatingSummary(
          average: p.ratingAvg,
          count: p.ratingCount,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 4),
        Text(
          [
            l10n.videoCount(p.videoCount),
            if (minutes != null) l10n.minutesShort(minutes),
            l10n.ageRangeLabel(p.ageRange),
          ].join(' · '),
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        if (p.forkedFrom != null) ...[
          const SizedBox(height: 4),
          Text(l10n.communityBasedOn, style: theme.textTheme.bodySmall),
        ],
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(description, style: theme.textTheme.bodyLarge),
        ],
        if (p.labelSlugs.isNotEmpty) ...[
          const SizedBox(height: 14),
          LabelChips(labelSlugs: p.labelSlugs),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('community-save'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.library_add_rounded),
          label: Text(l10n.communitySaveToLibrary),
        ),
        const SizedBox(height: 16),
        _RatingPanel(
          detail: d,
          busy: _rating,
          onRate: (s) => unawaited(_rate(s)),
        ),
        const SizedBox(height: 24),
        Text(l10n.communityVideos, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final v in d.videos) _VideoRow(video: v),
      ],
    );
  }
}

class _RatingPanel extends StatelessWidget {
  const _RatingPanel({
    required this.detail,
    required this.busy,
    required this.onRate,
  });

  final CommunityPlaylistDetail detail;
  final bool busy;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: detail.isMine
          ? Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.communityOwnPlaylist,
                key: const Key('community-own'),
                style: theme.textTheme.bodyMedium,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.communityRateTitle,
                  style: theme.textTheme.titleSmall,
                ),
                if (detail.myRating == null)
                  Text(
                    l10n.communityRateHint,
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 4),
                StarRatingInput(
                  value: detail.myRating,
                  enabled: !busy,
                  onChanged: onRate,
                ),
              ],
            ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.video});

  final PlaylistVideo video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          VideoThumbnail(url: video.thumbnailUrl, width: 112),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (video.channelName != null)
                  Text(
                    video.channelName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

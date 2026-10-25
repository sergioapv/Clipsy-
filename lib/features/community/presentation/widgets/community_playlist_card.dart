import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../playlists/presentation/playlist_l10n.dart';
import '../../../playlists/presentation/widgets/label_chips.dart';
import '../../../playlists/presentation/widgets/language_picker.dart';
import '../../../playlists/presentation/widgets/video_thumbnail.dart';
import '../../domain/community_playlist.dart';
import 'star_rating.dart';

/// A published playlist in the community list.
class CommunityPlaylistCard extends StatelessWidget {
  const CommunityPlaylistCard({
    required this.playlist,
    this.isMine = false,
    super.key,
  });

  final CommunityPlaylist playlist;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall;
    final minutes = playlist.totalDurationSeconds == null
        ? null
        : (playlist.totalDurationSeconds! / 60).ceil();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        child: Card(
          child: InkWell(
            onTap: () => context.push(Routes.communityPlaylist(playlist.id)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VideoThumbnail(
                    url: playlist.coverUrl,
                    width: 128,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMine
                              ? l10n.communityYours
                              : l10n.communityByAuthor(playlist.authorName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: muted,
                        ),
                        const SizedBox(height: 6),
                        RatingSummary(
                          average: playlist.ratingAvg,
                          count: playlist.ratingCount,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            l10n.videoCount(playlist.videoCount),
                            if (minutes != null) l10n.minutesShort(minutes),
                            l10n.ageRangeLabel(playlist.ageRange),
                            if (playlist.languages.isNotEmpty)
                              languagesLabel(playlist.languages),
                          ].join(' · '),
                          style: muted,
                        ),
                        if (playlist.labelSlugs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          LabelChips(labelSlugs: playlist.labelSlugs),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

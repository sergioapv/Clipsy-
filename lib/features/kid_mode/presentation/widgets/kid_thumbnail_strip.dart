import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../playlists/presentation/widgets/video_thumbnail.dart';
import '../../domain/kid_session.dart';

/// Big, tappable thumbnails of the playlist. The playing one is highlighted.
class KidThumbnailStrip extends StatelessWidget {
  const KidThumbnailStrip({
    required this.videos,
    required this.currentIndex,
    required this.onSelect,
    this.enabled = true,
    this.axis = Axis.horizontal,
    this.tileWidth = 220,
    super.key,
  });

  final List<KidVideo> videos;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool enabled;
  final Axis axis;

  /// Width of each thumbnail in a horizontal strip.
  final double tileWidth;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;
    return ListView.separated(
      scrollDirection: axis,
      itemCount: videos.length,
      separatorBuilder: (_, _) =>
          SizedBox(width: horizontal ? 16 : 0, height: horizontal ? 0 : 12),
      itemBuilder: (context, i) {
        final video = videos[i];
        final selected = i == currentIndex;
        final tile = Semantics(
          button: true,
          selected: selected,
          label: video.title,
          child: GestureDetector(
            key: ValueKey('kid-thumb-$i'),
            onTap: enabled ? () => onSelect(i) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: selected ? BrandColors.sunshine : Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoThumbnail(url: video.thumbnailUrl, borderRadius: 22),
                  if (selected)
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white70,
                      child: Icon(
                        Icons.music_note_rounded,
                        color: BrandColors.coral,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        return horizontal
            ? Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: tileWidth, child: tile),
              )
            : tile;
      },
    );
  }
}

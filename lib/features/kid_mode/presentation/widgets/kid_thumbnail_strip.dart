import 'package:flutter/material.dart';

import '../../../../core/widgets/pressable.dart';
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
    final scheme = Theme.of(context).colorScheme;
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
          child: Pressable(
            scale: 0.95,
            child: GestureDetector(
              key: ValueKey('kid-thumb-$i'),
              onTap: enabled ? () => onSelect(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: selected ? scheme.primary : Colors.transparent,
                ),
                child: Stack(
                  children: [
                    VideoThumbnail(url: video.thumbnailUrl, borderRadius: 21),
                    if (selected)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              size: 22,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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

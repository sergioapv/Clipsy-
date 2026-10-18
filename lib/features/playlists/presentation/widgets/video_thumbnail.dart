import 'package:flutter/material.dart';

/// A 16:9 thumbnail with a placeholder while loading or when missing.
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    required this.url,
    this.width,
    this.borderRadius = 12,
    this.dimmed = false,
    super.key,
  });

  final String? url;
  final double? width;
  final double borderRadius;

  /// Greys the image out, e.g. for videos that are no longer available.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.smart_display_rounded,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    Widget image = url == null
        ? placeholder
        : Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
            frameBuilder: (context, child, frame, wasSync) =>
                wasSync || frame != null ? child : placeholder,
          );
    if (dimmed) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: Opacity(opacity: 0.5, child: image),
      );
    }
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: ExcludeSemantics(child: image),
        ),
      ),
    );
  }
}

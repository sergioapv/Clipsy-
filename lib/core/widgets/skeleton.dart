import 'package:flutter/material.dart';

/// Placeholder rows shaped like the content that's loading (a 16:9
/// thumbnail and two lines of text), gently pulsing.
class SkeletonList extends StatefulWidget {
  const SkeletonList({
    this.count = 5,
    this.thumbnailWidth = 128,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    super.key,
  });

  final int count;
  final double thumbnailWidth;
  final EdgeInsets padding;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar(double? width, double height, double radius) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: FadeTransition(
        opacity: Tween(
          begin: 0.45,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: widget.count,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                bar(widget.thumbnailWidth, widget.thumbnailWidth * 9 / 16, 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(double.infinity, 14, 6),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: i.isEven ? 0.55 : 0.4,
                        child: bar(null, 12, 6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

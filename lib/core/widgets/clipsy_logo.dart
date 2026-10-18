import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// App mark: a solid accent tile with a rounded play glyph, plus the
/// lowercase wordmark.
class ClipsyLogo extends StatelessWidget {
  const ClipsyLogo({this.size = 72, this.showWordmark = true, super.key});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Clipsy',
      image: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipsyMark(size: size),
            if (showWordmark) ...[
              SizedBox(height: size * 0.22),
              Text(
                'clipsy',
                style: AppFonts.heading(size * 0.56, scheme.onSurface),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The tile on its own.
class ClipsyMark extends StatelessWidget {
  const ClipsyMark({this.size = 72, this.color, this.glyphColor, super.key});

  final double size;
  final Color? color;
  final Color? glyphColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? scheme.primary,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
      ),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _PlayGlyph(glyphColor ?? scheme.onPrimary)),
      ),
    );
  }
}

/// A play triangle with rounded corners, nudged right of centre so it looks
/// centred.
class _PlayGlyph extends CustomPainter {
  const _PlayGlyph(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.39, s * 0.29)
      ..lineTo(s * 0.72, s * 0.5)
      ..lineTo(s * 0.39, s * 0.71)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.09
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PlayGlyph old) => old.color != color;
}

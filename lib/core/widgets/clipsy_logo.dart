import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// App mark: a rounded play tile plus the wordmark.
class ClipsyLogo extends StatelessWidget {
  const ClipsyLogo({this.size = 72, this.showWordmark = true, super.key});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Clipsy',
      image: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.3),
                gradient: const LinearGradient(
                  colors: [BrandColors.seed, BrandColors.sky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: size * 0.66,
              ),
            ),
            if (showWordmark) ...[
              SizedBox(height: size * 0.18),
              Text(
                'Clipsy',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/widgets/pressable.dart';

/// A round secondary control for Kid mode: a surface-tone disc with an ink
/// icon, taking its colours from the Kid theme (sky by day, navy in full
/// screen).
class KidRoundButton extends StatelessWidget {
  const KidRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 64,
    this.primary = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;

  /// Orange, for play/pause: the one thing a child should find first.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        scale: 0.92,
        child: Material(
          color: primary ? scheme.primary : scheme.surfaceContainer,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                icon,
                size: size * (primary ? 0.62 : 0.5),
                color: primary ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

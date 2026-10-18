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
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final double size;

  /// Orange, for play/pause: the one thing a child should find first.
  final bool primary;

  /// A toggle that's on: drawn in ink, like a pressed key.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      toggled: selected ? true : null,
      label: label,
      child: Pressable(
        scale: 0.92,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Material(
            color: primary
                ? scheme.primary
                : selected
                ? scheme.onSurface
                : scheme.surfaceContainer,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox.square(
                dimension: size,
                child: Icon(
                  icon,
                  size: size * (primary ? 0.62 : 0.5),
                  color: primary
                      ? scheme.onPrimary
                      : selected
                      ? scheme.surface
                      : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

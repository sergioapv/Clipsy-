import 'package:flutter/material.dart';

/// A round, high-contrast secondary control for Kid mode.
class KidRoundButton extends StatelessWidget {
  const KidRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 64,
    this.dark = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;

  /// White-on-translucent style for use over video.
  final bool dark;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: dark ? Colors.black54 : Colors.white,
      shape: const CircleBorder(),
      elevation: dark ? 0 : 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            icon,
            size: size * 0.6,
            color: dark ? Colors.white : const Color(0xFF1F2340),
          ),
        ),
      ),
    ),
  );
}

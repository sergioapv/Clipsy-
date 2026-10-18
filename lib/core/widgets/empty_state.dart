import 'package:flutter/material.dart';

/// A composed "nothing here yet" block: icon tile, heading, one line of
/// guidance and the action that fixes it. Left-aligned, sitting a little
/// above centre.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: const Alignment(0, -0.3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: scheme.surfaceContainer,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: SizedBox.square(
                  dimension: 64,
                  child: Icon(icon, size: 30, color: scheme.onSurface),
                ),
              ),
              const SizedBox(height: 24),
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 28), action!],
            ],
          ),
        ),
      ),
    );
  }
}

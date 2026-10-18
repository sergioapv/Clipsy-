import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'empty_state.dart';

/// Full-area error with a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_rounded,
    title: context.l10n.errorTitle,
    message: message,
    action: FilledButton.tonalIcon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: Text(context.l10n.retry),
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/clipsy_logo.dart';
import '../../../core/widgets/pin_entry_view.dart';
import 'auth_providers.dart';

/// Parental gate in front of parent mode.
class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key});

  Future<void> _forgotPin(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.forgotPinTitle),
        content: Text(l10n.forgotPinBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.forgotPinConfirm),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ClipsyLogo(size: 56, showWordmark: false),
                const SizedBox(height: 16),
                PinEntryView(
                  title: l10n.unlockTitle,
                  check: ref.read(parentSessionProvider.notifier).unlockWithPin,
                  // The router leaves this screen when the session unlocks.
                  onAccepted: () {},
                  footer: TextButton(
                    onPressed: () => unawaited(_forgotPin(context, ref)),
                    child: Text(l10n.forgotPin),
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

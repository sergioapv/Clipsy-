import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../l10n/l10n.dart';
import 'pin_entry_view.dart';

/// Full-screen parental gate. Resolves to `true` once the right PIN is entered.
Future<bool> showPinDialog(BuildContext context, {String? title}) async {
  final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => _PinDialog(title: title),
    ),
  );
  return ok ?? false;
}

class _PinDialog extends ConsumerWidget {
  const _PinDialog({this.title});

  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Parent-themed even when opened from Kid mode.
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.cancel,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: PinEntryView(
                title: title ?? l10n.unlockTitle,
                check: ref.read(pinRepositoryProvider).verify,
                onAccepted: () => Navigator.pop(context, true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

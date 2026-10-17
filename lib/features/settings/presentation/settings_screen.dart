import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../auth/presentation/auth_providers.dart';

/// Parent settings. Time limits and Kid mode options join in Milestone 3;
/// account deletion in Milestone 5.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          _Header(l10n.settingsSecurity),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(l10n.changePin),
            onTap: () => context.push(Routes.changePin),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.lockParentMode),
            subtitle: Text(l10n.lockParentModeHint),
            onTap: () => ref.read(parentSessionProvider.notifier).lock(),
          ),
          _Header(l10n.settingsAccount),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.signedInAs),
            subtitle: Text(user?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () => unawaited(_signOut(context, ref)),
          ),
          _Header(l10n.settingsAbout),
          if (Env.privacyPolicyUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.privacyPolicy),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(
                Uri.parse(Env.privacyPolicyUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

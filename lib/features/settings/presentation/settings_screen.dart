import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/routes.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../community/data/profile_repository.dart';
import '../../community/presentation/community_providers.dart';
import '../../playlists/presentation/playlist_l10n.dart';
import 'kid_mode_settings_section.dart';

/// Parent settings. Account deletion joins in Milestone 5.
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

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(myDisplayNameProvider).value ?? '';
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (name == null || name.trim() == current) return;
    try {
      await ref.read(myDisplayNameProvider.notifier).save(name);
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.playlistError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _Group(
            title: l10n.settingsKidMode,
            children: const [KidModeSettingsSection()],
          ),
          _Group(
            title: l10n.settingsSecurity,
            children: [
              ListTile(
                leading: const Icon(Icons.pin_rounded),
                title: Text(l10n.changePin),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Routes.changePin),
              ),
              ListTile(
                leading: const Icon(Icons.lock_rounded),
                title: Text(l10n.lockParentMode),
                subtitle: Text(l10n.lockParentModeHint),
                onTap: () => ref.read(parentSessionProvider.notifier).lock(),
              ),
            ],
          ),
          _Group(
            title: l10n.settingsAccount,
            children: [
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(l10n.signedInAs),
                subtitle: Text(user?.email ?? ''),
              ),
              ListTile(
                key: const Key('community-name-tile'),
                leading: const Icon(Icons.badge_rounded),
                title: Text(l10n.communityName),
                subtitle: Text(ref.watch(myDisplayNameProvider).value ?? ''),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => unawaited(_editName(context, ref)),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(l10n.signOut),
                onTap: () => unawaited(_signOut(context, ref)),
              ),
            ],
          ),
          _Group(
            title: l10n.settingsAbout,
            children: [
              if (Env.privacyPolicyUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.privacy_tip_rounded),
                  title: Text(l10n.privacyPolicy),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => launchUrl(
                    Uri.parse(Env.privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.description_rounded),
                title: Text(
                  MaterialLocalizations.of(context).licensesPageTitle,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Clipsy',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A titled set of rows on one surface panel.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.communityName),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('community-name-field'),
          controller: _name,
          autofocus: true,
          maxLength: ProfileRepository.maxNameLength,
          textCapitalization: TextCapitalization.words,
          onFieldSubmitted: (_) => _submit(),
          validator: (v) {
            final n = (v ?? '').trim().length;
            return n < 1 || n > ProfileRepository.maxNameLength
                ? l10n.communityNameInvalid
                : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

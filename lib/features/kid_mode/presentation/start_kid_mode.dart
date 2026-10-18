import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/pin_dialog.dart';
import '../../playlists/domain/playlist.dart';
import '../domain/kid_settings.dart';
import 'kid_mode_controller.dart';

/// Parent flow: pick a time limit → PIN → (platform lock guidance) → Kid mode.
/// Once the session starts, the router switches to the Kid mode screen.
Future<void> startKidModeFlow(
  BuildContext context,
  WidgetRef ref,
  PlaylistDetail detail,
) async {
  final l10n = context.l10n;
  if (!detail.videos.any((v) => v.isAvailable)) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.kidNeedsVideos)));
    return;
  }

  final limit = await showModalBottomSheet<Duration>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _TimeLimitSheet(playlistTitle: detail.playlist.title),
  );
  if (limit == null || !context.mounted) return;

  if (!await showPinDialog(context, title: l10n.kidConfirmPin)) return;
  if (!context.mounted) return;

  if (!await _platformLockGuidance(context, ref)) return;

  await ref.read(kidModeProvider.notifier).start(detail: detail, limit: limit);
}

/// Android: explain the pinning prompt the first time. iOS: point to Guided
/// Access when it's off. Returns false if the parent backed out.
Future<bool> _platformLockGuidance(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final lock = ref.read(deviceLockProvider);
  final prefs = ref.read(sharedPreferencesProvider);

  if (lock.canPin) {
    const key = 'kid.pinningExplained';
    if (prefs.getBool(key) ?? false) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.push_pin_rounded),
        title: Text(l10n.pinningDialogTitle),
        content: Text(l10n.pinningDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
    if (ok ?? false) await prefs.setBool(key, true);
    return ok ?? false;
  }

  if (defaultTargetPlatform == TargetPlatform.iOS &&
      !await lock.isGuidedAccessEnabled()) {
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.accessibility_new_rounded),
        title: Text(l10n.onboardingGuidedAccessTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.guidedAccessOffBody),
            const SizedBox(height: 12),
            Text('1. ${l10n.onboardingGuidedAccessStep1}'),
            Text('2. ${l10n.onboardingGuidedAccessStep2}'),
            Text('3. ${l10n.onboardingGuidedAccessStep3}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.startAnyway),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
  return true;
}

class _TimeLimitSheet extends ConsumerWidget {
  const _TimeLimitSheet({required this.playlistTitle});

  final String playlistTitle;

  Future<void> _custom(BuildContext context, Duration initial) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => CustomLimitDialog(initialMinutes: initial.inMinutes),
    );
    if (minutes != null && context.mounted) {
      Navigator.pop(context, Duration(minutes: minutes));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final defaultLimit = ref.watch(
      kidSettingsProvider.select((s) => s.defaultLimit),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.startKidMode, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              playlistTitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('use-default-limit'),
              onPressed: () => Navigator.pop(context, defaultLimit),
              icon: const Icon(Icons.timer_rounded),
              label: Text(l10n.useDefaultLimit(defaultLimit.inMinutes)),
            ),
            const SizedBox(height: 20),
            Text(l10n.orChooseLimit, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in KidModeSettings.limitPresets)
                  ActionChip(
                    label: Text(l10n.minutesShort(m)),
                    onPressed: () =>
                        Navigator.pop(context, Duration(minutes: m)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(l10n.customLimit),
                  onPressed: () => _custom(context, defaultLimit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Slider dialog for a custom number of minutes (5–180).
class CustomLimitDialog extends StatefulWidget {
  const CustomLimitDialog({required this.initialMinutes, super.key});

  final int initialMinutes;

  @override
  State<CustomLimitDialog> createState() => _CustomLimitDialogState();
}

class _CustomLimitDialogState extends State<CustomLimitDialog> {
  late double _minutes = widget.initialMinutes.clamp(5, 180).toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.customLimit),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.minutesShort(_minutes.round()),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Slider(
            value: _minutes,
            min: 5,
            max: 180,
            divisions: 35,
            label: l10n.minutesShort(_minutes.round()),
            onChanged: (v) => setState(() => _minutes = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _minutes.round()),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}

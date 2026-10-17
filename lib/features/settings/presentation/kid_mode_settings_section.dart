import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../kid_mode/domain/kid_settings.dart';
import '../../kid_mode/presentation/kid_mode_controller.dart';
import '../../kid_mode/presentation/start_kid_mode.dart';

/// Settings → Kid mode.
class KidModeSettingsSection extends ConsumerWidget {
  const KidModeSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(kidSettingsProvider);
    final notifier = ref.read(kidSettingsProvider.notifier);
    Future<void> save(KidModeSettings s) => notifier.save(s);

    String timerModeLabel(TimerMode m) => switch (m) {
      TimerMode.wallClock => l10n.timerModeWallClock,
      TimerMode.playback => l10n.timerModePlayback,
    };
    String endLabel(EndBehaviour e) => switch (e) {
      EndBehaviour.hardStop => l10n.endHardStop,
      EndBehaviour.finishVideo => l10n.endFinishVideo(
        KidModeSettings.maxOverrun.inMinutes,
      ),
    };

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(l10n.defaultTimeLimit),
          subtitle: Text(l10n.minutesShort(settings.defaultLimit.inMinutes)),
          onTap: () async {
            final minutes = await _choose<int>(
              context,
              title: l10n.defaultTimeLimit,
              values: [
                ...KidModeSettings.limitPresets,
                if (!KidModeSettings.limitPresets.contains(
                  settings.defaultLimit.inMinutes,
                ))
                  settings.defaultLimit.inMinutes,
                -1,
              ],
              selected: settings.defaultLimit.inMinutes,
              label: (m) => m < 0 ? l10n.customLimit : l10n.minutesShort(m),
            );
            if (minutes == null || !context.mounted) return;
            final value = minutes >= 0
                ? minutes
                : await showDialog<int>(
                    context: context,
                    builder: (_) => CustomLimitDialog(
                      initialMinutes: settings.defaultLimit.inMinutes,
                    ),
                  );
            if (value != null) {
              await save(
                settings.copyWith(defaultLimit: Duration(minutes: value)),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.hourglass_bottom_rounded),
          title: Text(l10n.timerModeTitle),
          subtitle: Text(timerModeLabel(settings.timerMode)),
          onTap: () async {
            final v = await _choose(
              context,
              title: l10n.timerModeTitle,
              values: TimerMode.values,
              selected: settings.timerMode,
              label: timerModeLabel,
            );
            if (v != null) await save(settings.copyWith(timerMode: v));
          },
        ),
        ListTile(
          leading: const Icon(Icons.stop_circle_outlined),
          title: Text(l10n.endBehaviourTitle),
          subtitle: Text(endLabel(settings.endBehaviour)),
          onTap: () async {
            final v = await _choose(
              context,
              title: l10n.endBehaviourTitle,
              values: EndBehaviour.values,
              selected: settings.endBehaviour,
              label: endLabel,
            );
            if (v != null) await save(settings.copyWith(endBehaviour: v));
          },
        ),
        ListTile(
          leading: const Icon(Icons.touch_app_outlined),
          title: Text(l10n.exitGestureTitle),
          subtitle: Text(l10n.exitGestureValue(settings.exitHold.inSeconds)),
          onTap: () async {
            final v = await _choose(
              context,
              title: l10n.exitGestureTitle,
              values: KidModeSettings.exitHoldPresets,
              selected: settings.exitHold.inSeconds,
              label: l10n.exitGestureValue,
            );
            if (v != null) {
              await save(settings.copyWith(exitHold: Duration(seconds: v)));
            }
          },
        ),
        if (defaultTargetPlatform == TargetPlatform.iOS)
          const _GuidedAccessTile(),
      ],
    );
  }
}

Future<T?> _choose<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required T selected,
  required String Function(T) label,
}) => showDialog<T>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text(title),
    children: [
      for (final v in values)
        ListTile(
          title: Text(label(v)),
          trailing: v == selected ? const Icon(Icons.check) : null,
          selected: v == selected,
          onTap: () => Navigator.pop(context, v),
        ),
    ],
  ),
);

class _GuidedAccessTile extends ConsumerStatefulWidget {
  const _GuidedAccessTile();

  @override
  ConsumerState<_GuidedAccessTile> createState() => _GuidedAccessTileState();
}

class _GuidedAccessTileState extends ConsumerState<_GuidedAccessTile> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final on = await ref.read(deviceLockProvider).isGuidedAccessEnabled();
    if (mounted) setState(() => _enabled = on);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: const Icon(Icons.accessibility_new_rounded),
      title: Text(l10n.onboardingGuidedAccessTitle),
      subtitle: Text(
        _enabled == null
            ? ''
            : _enabled!
            ? l10n.guidedAccessOn
            : l10n.guidedAccessOffShort,
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.onboardingGuidedAccessTitle),
          content: Text(
            '1. ${l10n.onboardingGuidedAccessStep1}\n'
            '2. ${l10n.onboardingGuidedAccessStep2}\n'
            '3. ${l10n.onboardingGuidedAccessStep3}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.gotIt),
            ),
          ],
        ),
      ).then((_) => _refresh()),
    );
  }
}

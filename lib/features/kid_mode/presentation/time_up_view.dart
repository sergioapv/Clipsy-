import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import 'kid_mode_controller.dart';

/// "All done for now!" Only a parent (PIN) can add time or exit.
class TimeUpView extends StatelessWidget {
  const TimeUpView({
    required this.exitButton,
    required this.onParent,
    super.key,
  });

  final Widget exitButton;
  final VoidCallback onParent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3D6),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Sun(),
                    const SizedBox(height: 32),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        l10n.timeUpTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.timeUpBody,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(top: 8, right: 8, child: exitButton),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  key: const Key('time-up-parent'),
                  onPressed: onParent,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: Text(l10n.timeUpParent),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                    textStyle: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sun extends StatelessWidget {
  const _Sun();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [BrandColors.sunshine, BrandColors.coral],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x55FFC94D), blurRadius: 40, spreadRadius: 12),
        ],
      ),
      child: const Icon(
        Icons.sentiment_very_satisfied_rounded,
        size: 96,
        color: Colors.white,
      ),
    ),
  );
}

/// After the PIN: add time or leave Kid mode.
Future<void> showTimeUpParentOptions(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = context.l10n;
  final controller = ref.read(kidModeProvider.notifier);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.timeUpParentTitle,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final m in const [5, 10, 15])
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      unawaited(controller.extend(Duration(minutes: m)));
                    },
                    child: Text(l10n.addMinutes(m)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                unawaited(controller.exit());
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.exitKidMode),
            ),
          ],
        ),
      ),
    ),
  );
}

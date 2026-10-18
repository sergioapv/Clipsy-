import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
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
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Moon(),
                      const SizedBox(height: 40),
                      Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          l10n.timeUpTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.timeUpBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
                  icon: const Icon(Icons.lock_rounded, size: 18),
                  label: Text(l10n.timeUpParent),
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
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

/// A crescent moon: the sky colour, bitten by the night.
class _Moon extends StatelessWidget {
  const _Moon();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 168,
        child: CustomPaint(
          painter: _MoonPainter(moon: scheme.onSurface, star: scheme.primary),
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter({required this.moon, required this.star});

  final Color moon;
  final Color star;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final disc = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(s * 0.46, s * 0.54), radius: s * 0.4),
      );
    final bite = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(s * 0.68, s * 0.4), radius: s * 0.34),
      );
    canvas
      ..drawPath(
        Path.combine(PathOperation.difference, disc, bite),
        Paint()..color = moon,
      )
      ..drawCircle(Offset(s * 0.86, s * 0.14), s * 0.045, Paint()..color = star)
      ..drawCircle(
        Offset(s * 0.9, s * 0.74),
        s * 0.03,
        Paint()..color = moon.withValues(alpha: 0.5),
      );
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.moon != moon || old.star != star;
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
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
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
                  FilledButton(
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
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.exitKidMode),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';

/// A small corner button that must be held for [holdDuration] before
/// [onHeld] fires. Taps do nothing, so curious fingers don't open the PIN.
class HoldToExitButton extends StatefulWidget {
  const HoldToExitButton({
    required this.holdDuration,
    required this.onHeld,
    super.key,
  });

  final Duration holdDuration;
  final VoidCallback onHeld;

  @override
  State<HoldToExitButton> createState() => _HoldToExitButtonState();
}

class _HoldToExitButtonState extends State<HoldToExitButton>
    with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      unawaited(HapticFeedback.mediumImpact());
      _progress.value = 0;
      widget.onHeld();
    }
  }

  void _start() => unawaited(_progress.forward(from: 0));

  void _cancel() {
    if (_progress.isAnimating) unawaited(_progress.reverse());
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      label: context.l10n.kidExitHint(widget.holdDuration.inSeconds),
      child: Listener(
        key: const Key('kid-exit-button'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: SizedBox.square(
          dimension: 56,
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: 40,
                  child: CircularProgressIndicator(
                    value: _progress.value,
                    strokeWidth: 3,
                    color: ink,
                    backgroundColor: ink.withValues(alpha: 0.12),
                  ),
                ),
                Icon(
                  Icons.lock_rounded,
                  size: 20,
                  color: ink.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

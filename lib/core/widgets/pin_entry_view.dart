import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/pin_check_result.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../l10n/l10n.dart';
import 'pin_pad.dart';

/// PIN pad wired to a check function, with wrong-PIN feedback and a live
/// lockout countdown. Reused wherever the parental gate is needed.
class PinEntryView extends ConsumerStatefulWidget {
  const PinEntryView({
    required this.check,
    required this.onAccepted,
    this.title,
    this.footer,
    super.key,
  });

  final Future<PinCheckResult> Function(String pin) check;
  final VoidCallback onAccepted;
  final String? title;
  final Widget? footer;

  @override
  ConsumerState<PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends ConsumerState<PinEntryView> {
  bool _busy = false;
  String? _error;
  DateTime? _lockedUntil;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLockout());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadLockout() async {
    final until = await ref.read(pinRepositoryProvider).lockedUntil();
    if (mounted && until != null) _startLockout(until);
  }

  void _startLockout(DateTime until) {
    _ticker?.cancel();
    setState(() => _lockedUntil = until);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (DateTime.now().isAfter(until)) {
        _ticker?.cancel();
        setState(() {
          _lockedUntil = null;
          _error = null;
        });
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _submit(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.check(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = context.l10n;
    switch (result) {
      case PinAccepted():
        widget.onAccepted();
      case PinRejected(:final attemptsBeforeLockout):
        setState(
          () => _error = attemptsBeforeLockout > 0 && attemptsBeforeLockout <= 2
              ? l10n.pinWrongAttemptsLeft(attemptsBeforeLockout)
              : l10n.pinWrong,
        );
      case PinLockedOut(:final until):
        _startLockout(until);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final until = _lockedUntil;
    final locked = until != null;
    final remaining = locked ? until.difference(DateTime.now()) : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              widget.title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        PinPad(
          enabled: !_busy && !locked,
          errorText: locked
              ? l10n.pinLockedOut(_formatDuration(remaining!))
              : _error,
          onCompleted: _submit,
        ),
        ?widget.footer,
      ],
    );
  }

  static String _formatDuration(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds + 1;
    final m = total ~/ 60;
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/pin_entry_view.dart';
import '../../../core/widgets/pin_pad.dart';
import 'auth_providers.dart';

enum _Step { current, enter, confirm }

/// First-launch PIN creation, or (with [isChange]) changing an existing PIN
/// after confirming the current one.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({this.isChange = false, super.key});

  final bool isChange;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  late _Step _step = widget.isChange ? _Step.current : _Step.enter;
  String? _first;
  String? _error;
  bool _saving = false;

  Future<void> _onEntered(String pin) async {
    switch (_step) {
      case _Step.current:
        break; // Handled by PinEntryView.
      case _Step.enter:
        setState(() {
          _first = pin;
          _error = null;
          _step = _Step.confirm;
        });
      case _Step.confirm:
        if (pin != _first) {
          setState(() {
            _first = null;
            _error = context.l10n.pinMismatch;
            _step = _Step.enter;
          });
          return;
        }
        setState(() => _saving = true);
        await ref.read(pinStatusProvider.notifier).setPin(pin);
        if (!mounted) return;
        if (widget.isChange) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.l10n.pinChanged)));
          context.pop();
        } else {
          // The router moves on to onboarding once the gate updates.
          ref.read(parentSessionProvider.notifier).markUnlocked();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (title, subtitle) = switch (_step) {
      _Step.current => (l10n.pinEnterCurrent, null),
      _Step.enter => (
        widget.isChange ? l10n.pinChooseNew : l10n.pinCreateTitle,
        l10n.pinCreateSubtitle,
      ),
      _Step.confirm => (l10n.pinConfirmTitle, null),
    };

    return Scaffold(
      appBar: widget.isChange ? AppBar(title: Text(l10n.changePin)) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isChange)
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                const SizedBox(height: 16),
                if (_step == _Step.current)
                  PinEntryView(
                    title: title,
                    check: ref.read(pinRepositoryProvider).verify,
                    onAccepted: () => setState(() => _step = _Step.enter),
                  )
                else ...[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PinPad(
                    // A new key resets the pad between steps.
                    key: ValueKey(_step),
                    enabled: !_saving,
                    errorText: _error,
                    onCompleted: _onEntered,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

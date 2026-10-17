import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/auth/domain/pin.dart';
import '../l10n/l10n.dart';

/// A 4-dot indicator plus a numeric keypad. Reports the PIN through
/// [onCompleted] once [Pin.length] digits are entered, then clears itself.
class PinPad extends StatefulWidget {
  const PinPad({
    required this.onCompleted,
    this.enabled = true,
    this.errorText,
    super.key,
  });

  final ValueChanged<String> onCompleted;
  final bool enabled;
  final String? errorText;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';

  void _press(String digit) {
    if (!widget.enabled || _digits.length >= Pin.length) return;
    HapticFeedback.selectionClick();
    setState(() => _digits += digit);
    if (_digits.length == Pin.length) {
      final pin = _digits;
      // Let the last dot paint before handing over.
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        setState(() => _digits = '');
        widget.onCompleted(pin);
      });
    }
  }

  void _backspace() {
    if (!widget.enabled || _digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l10n.pinDigitsEntered(_digits.length, Pin.length),
          liveRegion: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < Pin.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _digits.length
                        ? scheme.primary
                        : Colors.transparent,
                    border: Border.all(color: scheme.outline, width: 2),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: Center(
            child: widget.errorText == null
                ? null
                : Text(
                    widget.errorText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  ),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final d in row) _key(d)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 88, height: 80),
            _key('0'),
            SizedBox(
              width: 88,
              height: 80,
              child: IconButton(
                tooltip: l10n.pinBackspace,
                onPressed: widget.enabled ? _backspace : null,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(String digit) => Padding(
    padding: const EdgeInsets.all(6),
    child: SizedBox(
      width: 76,
      height: 68,
      child: FilledButton.tonal(
        key: ValueKey('pin-key-$digit'),
        onPressed: widget.enabled ? () => _press(digit) : null,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        ),
        child: Text(digit),
      ),
    ),
  );
}

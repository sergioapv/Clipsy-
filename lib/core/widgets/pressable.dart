import 'package:flutter/material.dart';

/// Shrinks its child slightly while pressed, so taps feel physical.
/// Purely visual: [child] still handles the tap itself.
class Pressable extends StatefulWidget {
  const Pressable({required this.child, this.scale = 0.97, super.key});

  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

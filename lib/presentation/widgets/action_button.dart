import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Un wrapper para botones que maneja el estado asíncrono y evita múltiples clicks rápidos (double tap timeout o repetición).
/// También muestra un indicador de carga mientras el Future se resuelve.
class ActionButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isTonal;
  final bool isOutlined;
  final bool isText;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : isTonal = false,
       isOutlined = false,
       isText = false;

  const ActionButton.tonal({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : isTonal = true,
       isOutlined = false,
       isText = false;

  const ActionButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : isTonal = false,
       isOutlined = true,
       isText = false;

  const ActionButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : isTonal = false,
       isOutlined = false,
       isText = true;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || widget.onPressed == null) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pass null when loading → Flutter disables the button at gesture level.
    final callback =
        (_isLoading || widget.onPressed == null) ? null : _handlePress;

    Widget content =
        _isLoading
            ? widget.child
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .fade(begin: 1.0, end: 0.4, duration: 600.ms)
                .scale(begin: const Offset(1, 1), end: const Offset(0.95, 0.95))
            : widget.child;

    if (widget.isTonal) {
      return FilledButton.tonal(
        onPressed: callback,
        style: widget.style,
        child: content,
      );
    } else if (widget.isOutlined) {
      return OutlinedButton(
        onPressed: callback,
        style: widget.style,
        child: content,
      );
    } else if (widget.isText) {
      return TextButton(
        onPressed: callback,
        style: widget.style,
        child: content,
      );
    } else {
      return FilledButton(
        onPressed: callback,
        style: widget.style,
        child: content,
      );
    }
  }
}

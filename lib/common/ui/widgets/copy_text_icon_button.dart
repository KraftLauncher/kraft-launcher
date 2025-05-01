import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyTextIconButton extends StatefulWidget {
  const CopyTextIconButton({
    super.key,
    required this.text,
    required this.tooltip,
  });

  final String text;
  final String tooltip;

  @override
  State<CopyTextIconButton> createState() => _CopyTextIconButtonState();
}

class _CopyTextIconButtonState extends State<CopyTextIconButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
      child: Icon(_copied ? Icons.done : Icons.copy, key: ValueKey(_copied)),
    ),
    tooltip: widget.tooltip,
    onPressed: () async {
      if (_copied) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: widget.text));
      setState(() => _copied = true);

      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _copied = false);
      }
    },
  );
}

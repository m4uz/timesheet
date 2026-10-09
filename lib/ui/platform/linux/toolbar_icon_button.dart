import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

/// Icon button used in Linux page-header toolbars.
class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.message,
    required this.icon,
    required this.onPressed,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: YaruIconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}

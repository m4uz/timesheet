import 'package:flutter/material.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:yaru/constants.dart';

/// Compact filter field for [YaruWindowTitleBar] actions.
///
/// Opaque pill + height-locked collapsed [TextField]. Avoid [YaruSearchField]:
/// its strut leading and padded decoration leave the hint top-aligned here.
class ToolbarFilterField extends StatelessWidget {
  const ToolbarFilterField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.width = LinuxLayout.toolbarFilterWidth,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(height: 1.0);
    final lineHeight = textStyle.fontSize ?? 14;

    return Container(
      width: width,
      height: LinuxLayout.toolbarFilterHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: LinuxLayout.space12),
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(kYaruTitleBarItemHeight),
      ),
      child: SizedBox(
        height: lineHeight,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: textStyle,
          cursorWidth: 1,
          decoration: InputDecoration.collapsed(
            hintText: hintText,
            hintStyle: textStyle.copyWith(color: theme.hintColor),
          ),
        ),
      ),
    );
  }
}

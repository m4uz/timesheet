import 'package:flutter/cupertino.dart' hide OverlayVisibilityMode;
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/platform/macos/macos_layout.dart';

class ToolbarTextField extends ToolbarItem {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final double width;

  const ToolbarTextField({
    required this.controller,
    required this.onChanged,
    this.placeholder = 'Filter',
    this.width = MacosLayout.toolbarFilterWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context, ToolbarItemDisplayMode displayMode) {
    return Padding(
      padding: MacosLayout.toolbarItemPadding,
      child: SizedBox(
        width: width,
        child: MacosTextField(
          prefix: const MacosIcon(CupertinoIcons.search),
          clearButtonMode: OverlayVisibilityMode.always,
          controller: controller,
          placeholder: placeholder,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart' hide OverlayVisibilityMode;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class MacosToolbarTextField extends ToolbarItem {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final double width;

  const MacosToolbarTextField({
    required this.controller,
    required this.onChanged,
    this.placeholder = 'Filter',
    this.width = 140,
    super.key,
  });

  @override
  Widget build(BuildContext context, ToolbarItemDisplayMode displayMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: width,
        child: MacosTextField(
          prefix: MacosIcon(CupertinoIcons.search),
          clearButtonMode: OverlayVisibilityMode.always,
          controller: controller,
          placeholder: placeholder,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

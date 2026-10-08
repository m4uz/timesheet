import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// Shared macOS layout metrics and chrome helpers.
class MacosLayout {
  MacosLayout._();

  // Spacing scale
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;

  static const EdgeInsets rowCellPadding = EdgeInsets.all(space10);
  static const EdgeInsets pagePadding = EdgeInsets.all(space20);
  static const EdgeInsets panelPadding = EdgeInsets.all(space16);
  static const EdgeInsets toolbarItemPadding =
      EdgeInsets.symmetric(horizontal: space8);
  static const EdgeInsets footerPadding =
      EdgeInsets.symmetric(horizontal: space8, vertical: space8);
  static const EdgeInsets menuPadding = EdgeInsets.all(space6);

  // Icons / hit targets
  static const double sidebarIconSize = 20;
  static const BoxConstraints sidebarButtonConstraints = BoxConstraints(
    minHeight: 20,
    minWidth: 20,
    maxWidth: 48,
    maxHeight: 38,
  );
  static const double overlayButtonIconSize = 14;
  static const double overlayButtonSize = 22;
  static const double rowActionWidth = 30;
  static const double menuCheckSlotWidth = 18;
  static const double menuCheckIconSize = 16;
  static const double menuItemHeight = 20;

  // Columns / controls
  static const double dayColumnWidth = 40;
  static const double workedColumnWidth = 80;
  static const double flexFieldMinWidth = 120;
  static const double toolbarFilterWidth = 140;
  static const double formLabelWidth = 160;
  static const double toolbarTitleWidthShort = 100;

  // Radii
  static const double fieldRadius = 5;
  static const double menuItemRadius = 4;
}

/// Consistent sidebar toggle used by macOS toolbars.
class MacosSidebarToggle extends StatelessWidget {
  const MacosSidebarToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosTooltip(
      message: 'Toggle Sidebar',
      useMousePosition: false,
      child: MacosIconButton(
        icon: MacosIcon(
          CupertinoIcons.sidebar_left,
          color: MacosTheme.brightnessOf(context).resolve(
            const Color.fromRGBO(0, 0, 0, 0.5),
            const Color.fromRGBO(255, 255, 255, 0.5),
          ),
          size: MacosLayout.sidebarIconSize,
        ),
        boxConstraints: MacosLayout.sidebarButtonConstraints,
        onPressed: () => MacosWindowScope.of(context).toggleSidebar(),
      ),
    );
  }
}

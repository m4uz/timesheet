import 'package:flutter/material.dart';

/// Linux layout metrics aligned with [MacosLayout]/[WindowsLayout] for
/// cross-platform UI consistency (Yaru/Material chrome; geometry matches).
class LinuxLayout {
  LinuxLayout._();

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
  static const EdgeInsets menuPadding = EdgeInsets.all(space6);
  static const EdgeInsets footerPadding =
      EdgeInsets.symmetric(horizontal: space8, vertical: space8);

  // Icons / hit targets
  static const double overlayButtonIconSize = 14;
  static const double overlayButtonSize = 22;
  static const double rowActionWidth = 30;
  static const double rowIconSize = 16;
  static const double menuCheckSlotWidth = 18;
  static const double menuCheckIconSize = 16;
  static const double menuItemHeight = 28;

  // Columns / controls
  static const double dayColumnWidth = 40;
  static const double workedColumnWidth = 80;
  static const double flexFieldMinWidth = 120;
  static const double toolbarFilterWidth = 140;
  static const double formLabelWidth = 160;

  /// Typed segment cluster for both `DD.MM.` and `HH:mm` (same width).
  /// Sized so `HH:mm` / `DD.MM.` stay fully visible at row field type scale.
  static const double dateTimeSegmentClusterWidth = 64;

  /// Date and time columns share one fixed width so digits aren't clipped and
  /// the layout does not shift while editing.
  static const double dateTimeColumnWidth = 112;

  /// Title-bar filter control height (matches Yaru title-bar item height).
  static const double toolbarFilterHeight = 34;

  // Radii / strokes
  static const double fieldRadius = 5;
  static const double menuItemRadius = 4;
  static const double rowDividerWidth = 0.5;

  /// Row field type scale (~macOS title3 = 15).
  static TextStyle rowFieldStyle(ThemeData theme) {
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 15,
    );
  }

  /// Timesheet table cell (~macOS title3).
  static TextStyle tableCellStyle(ThemeData theme) {
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 15,
    );
  }

  /// Timesheet table header (~macOS headline at w600).
  static TextStyle tableHeaderStyle(ThemeData theme) {
    return (theme.textTheme.titleSmall ??
            const TextStyle(fontWeight: FontWeight.w600))
        .copyWith(fontSize: 13, fontWeight: FontWeight.w600);
  }

  /// Toolbar date labels (~macOS caption1 + secondary).
  static TextStyle toolbarLabelStyle(ThemeData theme) {
    return (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// Subjects panel title (~macOS headline).
  static TextStyle panelTitleStyle(ThemeData theme) {
    return (theme.textTheme.titleSmall ??
            const TextStyle(fontWeight: FontWeight.w600))
        .copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  }

  /// Config section title (~macOS headline).
  static TextStyle sectionTitleStyle(ThemeData theme) {
    return theme.textTheme.titleSmall ??
        const TextStyle(fontWeight: FontWeight.w600);
  }

  static Color dividerColor(ThemeData theme) => theme.dividerColor;
}

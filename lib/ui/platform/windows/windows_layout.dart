import 'package:fluent_ui/fluent_ui.dart';

/// Windows layout metrics aligned with [MacosLayout] for cross-platform UI
/// consistency (Fluent chrome kept; geometry and type scale match macOS).
class WindowsLayout {
  WindowsLayout._();

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

  // Icons / hit targets
  static const double overlayButtonIconSize = 14;
  static const double overlayButtonSize = 22;
  static const double rowActionWidth = 30;
  static const double rowIconSize = 16;

  // Columns / controls
  static const double dayColumnWidth = 40;
  static const double workedColumnWidth = 80;
  static const double flexFieldMinWidth = 120;
  static const double toolbarFilterWidth = 140;
  static const double formLabelWidth = 160;

  // Radii / strokes
  static const double fieldRadius = 5;
  static const double rowDividerWidth = 0.5;

  /// Row field type scale (~macOS title3 = 15).
  static TextStyle rowFieldStyle(FluentThemeData theme) {
    return (theme.typography.body ?? const TextStyle()).copyWith(fontSize: 15);
  }

  /// Timesheet table cell (~macOS title3).
  static TextStyle tableCellStyle(FluentThemeData theme) {
    return (theme.typography.body ?? const TextStyle()).copyWith(fontSize: 15);
  }

  /// Timesheet table header (~macOS headline at w600).
  static TextStyle tableHeaderStyle(FluentThemeData theme) {
    return (theme.typography.bodyStrong ??
            const TextStyle(fontWeight: FontWeight.w600))
        .copyWith(fontSize: 13, fontWeight: FontWeight.w600);
  }

  /// Toolbar date labels (~macOS caption1 + gray).
  static TextStyle toolbarLabelStyle(FluentThemeData theme) {
    return (theme.typography.caption ?? const TextStyle(fontSize: 12)).copyWith(
      color: theme.resources.textFillColorSecondary,
    );
  }

  /// Subjects panel title (~macOS headline).
  static TextStyle panelTitleStyle(FluentThemeData theme) {
    return (theme.typography.bodyStrong ??
            const TextStyle(fontWeight: FontWeight.w600))
        .copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  }

  /// Config section title (~macOS headline).
  static TextStyle sectionTitleStyle(FluentThemeData theme) {
    return theme.typography.bodyStrong ??
        const TextStyle(fontWeight: FontWeight.w600);
  }
}

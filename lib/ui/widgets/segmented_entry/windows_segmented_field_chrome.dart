import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Theme, TextSelectionThemeData;
import 'package:timesheet/ui/platform/windows/windows_layout.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';

/// Shared visual chrome for Windows segmented date/time entries.
class WindowsSegmentedFieldChrome extends StatelessWidget {
  const WindowsSegmentedFieldChrome({
    super.key,
    required this.child,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: WindowsLayout.space6,
      vertical: WindowsLayout.space4,
    ),
  });

  static const double segmentClusterWidth =
      SegmentedFieldMetrics.segmentClusterWidth;
  static const double dateSegmentClusterWidth =
      SegmentedFieldMetrics.dateSegmentClusterWidth;
  static const double dateColumnWidth = SegmentedFieldMetrics.dateColumnWidth;
  static const double timeColumnWidth = SegmentedFieldMetrics.timeColumnWidth;
  static const EdgeInsets fieldWithButtonPadding =
      SegmentedFieldMetrics.fieldWithButtonPadding;

  final Widget child;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  static Color borderColor(FluentThemeData theme) =>
      theme.resources.controlStrokeColorDefault;

  static Color fillColor(FluentThemeData theme) =>
      theme.resources.controlFillColorDefault;

  static Color selectionColor(FluentThemeData theme) =>
      theme.accentColor.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor(theme),
            borderRadius: BorderRadius.circular(WindowsLayout.fieldRadius),
            border: Border.all(color: borderColor(theme)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Typed segmented cluster + pointer-only overlay button (calendar/clock).
///
/// Uses [HoverButton] instead of Fluent [IconButton]/[BaseButton] so the
/// control stays safe under Material [ReorderableListView] drag proxies.
class WindowsSegmentedFieldWithButton extends StatelessWidget {
  const WindowsSegmentedFieldWithButton({
    super.key,
    required this.enabled,
    required this.semanticLabel,
    required this.fieldValue,
    required this.fieldWidth,
    required this.segmentedField,
    required this.buttonSemanticLabel,
    required this.buttonIcon,
    required this.onButtonPressed,
  });

  final bool enabled;
  final String semanticLabel;
  final String fieldValue;
  final double fieldWidth;
  final Widget segmentedField;
  final String buttonSemanticLabel;
  final IconData buttonIcon;
  final VoidCallback? onButtonPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final selectionColor = WindowsSegmentedFieldChrome.selectionColor(theme);

    return WindowsSegmentedFieldChrome(
      enabled: enabled,
      padding: WindowsSegmentedFieldChrome.fieldWithButtonPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            enabled: enabled,
            label: semanticLabel,
            value: fieldValue,
            textField: true,
            child: ExcludeSemantics(
              child: SizedBox(
                width: fieldWidth,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: selectionColor,
                    ),
                  ),
                  child: segmentedField,
                ),
              ),
            ),
          ),
          // Mouse/pointer only — keep Tab cycling through typed fields.
          ExcludeFocus(
            child: Semantics(
              button: true,
              enabled: enabled,
              label: buttonSemanticLabel,
              child: HoverButton(
                onPressed: enabled ? onButtonPressed : null,
                builder: (context, states) {
                  final resources = theme.resources;
                  final color = !enabled
                      ? resources.textFillColorDisabled
                      : theme.accentColor;
                  final hoverWash = states.isHovered || states.isPressed
                      ? theme.accentColor.withValues(alpha: 0.15)
                      : Colors.transparent;
                  return Container(
                    width: WindowsLayout.overlayButtonSize,
                    height: WindowsLayout.overlayButtonSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hoverWash,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      buttonIcon,
                      size: WindowsLayout.overlayButtonIconSize,
                      color: color,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/platform/macos/macos_layout.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';

/// Shared visual chrome for macOS segmented date/time entries.
class MacosSegmentedFieldChrome extends StatelessWidget {
  const MacosSegmentedFieldChrome({
    super.key,
    required this.child,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: MacosLayout.space6,
      vertical: MacosLayout.space4,
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

  static Color borderColor(MacosThemeData theme) =>
      theme.brightness == Brightness.dark
      ? const Color(0xFF3F3F3F)
      : const Color(0xFFD0D0D0);

  static Color fillColor(MacosThemeData theme) =>
      theme.brightness == Brightness.dark
      ? const Color(0xFF2B2B2B)
      : const Color(0xFFF5F5F5);

  static Color selectionColor(MacosThemeData theme) =>
      theme.primaryColor.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor(theme),
            borderRadius: BorderRadius.circular(MacosLayout.fieldRadius),
            border: Border.all(color: borderColor(theme)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Typed segmented cluster + pointer-only overlay button (calendar/clock).
class MacosSegmentedFieldWithButton extends StatelessWidget {
  const MacosSegmentedFieldWithButton({
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
    final theme = MacosTheme.of(context);
    final selectionColor = MacosSegmentedFieldChrome.selectionColor(theme);

    return MacosSegmentedFieldChrome(
      enabled: enabled,
      padding: MacosSegmentedFieldChrome.fieldWithButtonPadding,
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
            child: MacosIconButton(
              backgroundColor: MacosColors.transparent,
              hoverColor: theme.primaryColor.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(MacosLayout.space2),
              boxConstraints: const BoxConstraints.tightFor(
                width: MacosLayout.overlayButtonSize,
                height: MacosLayout.overlayButtonSize,
              ),
              semanticLabel: buttonSemanticLabel,
              icon: MacosIcon(
                buttonIcon,
                size: MacosLayout.overlayButtonIconSize,
                color: theme.primaryColor,
              ),
              onPressed: enabled ? onButtonPressed : null,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

/// Shared visual chrome for macOS segmented date/time entries.
class MacosSegmentedFieldChrome extends StatelessWidget {
  const MacosSegmentedFieldChrome({
    super.key,
    required this.child,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
  });

  static const double segmentClusterWidth = 42;

  /// `DD.MM.` needs slightly more room than `HH:mm`.
  static const double dateSegmentClusterWidth = 50;
  static const double dateColumnWidth = 86;

  /// Typed `HH:mm` plus clock overlay button.
  static const double timeColumnWidth = 78;

  static const EdgeInsets fieldWithButtonPadding = EdgeInsets.only(
    left: 6,
    right: 2,
    top: 2,
    bottom: 2,
  );

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
            borderRadius: BorderRadius.circular(5),
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
  final VoidCallback onButtonPressed;

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
              padding: const EdgeInsets.all(2),
              boxConstraints: const BoxConstraints.tightFor(
                width: 22,
                height: 22,
              ),
              semanticLabel: buttonSemanticLabel,
              icon: MacosIcon(
                buttonIcon,
                size: 14,
                color: theme.primaryColor,
              ),
              onPressed: onButtonPressed,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';
import 'package:yaru/yaru.dart';

/// Shared visual chrome for Linux segmented date/time entries.
///
/// Matches Yaru [InputDecorationTheme] fills/borders (neutral surface tint),
/// not [ColorScheme.primary] — Ubuntu orange must not bleed into field chrome.
class LinuxSegmentedFieldChrome extends StatelessWidget {
  const LinuxSegmentedFieldChrome({
    super.key,
    required this.child,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: LinuxLayout.space6,
      vertical: LinuxLayout.space4,
    ),
  });

  static const double segmentClusterWidth =
      LinuxLayout.dateTimeSegmentClusterWidth;
  static const double dateSegmentClusterWidth =
      LinuxLayout.dateTimeSegmentClusterWidth;
  static const double dateColumnWidth = LinuxLayout.dateTimeColumnWidth;
  static const double timeColumnWidth = LinuxLayout.dateTimeColumnWidth;
  static const EdgeInsets fieldWithButtonPadding =
      SegmentedFieldMetrics.fieldWithButtonPadding;

  final Widget child;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  static Color borderColor(ThemeData theme) {
    final scheme = theme.colorScheme;
    return scheme.isHighContrast ? scheme.outlineVariant : scheme.outline;
  }

  static Color fillColor(ThemeData theme) {
    final fromTheme = theme.inputDecorationTheme.fillColor;
    if (fromTheme != null) {
      return fromTheme;
    }
    final scheme = theme.colorScheme;
    return scheme.surface.scale(
      lightness: scheme.isLight ? -0.05 : -0.1,
    );
  }

  static Color foregroundColor(ThemeData theme) =>
      theme.colorScheme.onSurface;

  static Color selectionColor(ThemeData theme) =>
      theme.colorScheme.primary.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor(theme),
            borderRadius: BorderRadius.circular(kYaruButtonRadius),
            border: Border.all(color: borderColor(theme)),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foregroundColor(theme)),
            child: IconTheme.merge(
              data: IconThemeData(color: foregroundColor(theme)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Typed segmented cluster + pointer-only overlay button (calendar/clock).
class LinuxSegmentedFieldWithButton extends StatelessWidget {
  const LinuxSegmentedFieldWithButton({
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
    final theme = Theme.of(context);
    final selectionColor = LinuxSegmentedFieldChrome.selectionColor(theme);
    final foreground = LinuxSegmentedFieldChrome.foregroundColor(theme);

    return SizedBox(
      width: LinuxLayout.dateTimeColumnWidth,
      child: LinuxSegmentedFieldChrome(
        enabled: enabled,
        padding: LinuxSegmentedFieldChrome.fieldWithButtonPadding,
        child: Row(
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
                    data: theme.copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        selectionColor: selectionColor,
                      ),
                    ),
                    child: segmentedField,
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Mouse/pointer only — keep Tab cycling through typed fields.
            ExcludeFocus(
              child: Semantics(
                button: true,
                enabled: enabled,
                label: buttonSemanticLabel,
                child: YaruIconButton(
                  onPressed: enabled ? onButtonPressed : null,
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(LinuxLayout.overlayButtonSize),
                    minimumSize:
                        const Size.square(LinuxLayout.overlayButtonSize),
                    padding: EdgeInsets.zero,
                    foregroundColor: enabled ? foreground : theme.disabledColor,
                  ),
                  icon: Icon(
                    buttonIcon,
                    size: LinuxLayout.overlayButtonIconSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

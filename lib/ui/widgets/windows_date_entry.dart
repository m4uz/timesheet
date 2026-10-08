import 'package:fluent_ui/fluent_ui.dart';
import 'package:timesheet/ui/widgets/segmented_entry/date_entry_controller.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_entry.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';
import 'package:timesheet/ui/widgets/segmented_entry/windows_segmented_field_chrome.dart';

/// A compact Windows-styled date entry: typeable `d.M` segments plus a
/// calendar button that opens a Fluent [CalendarView] flyout.
class WindowsDateEntry extends StatefulWidget {
  const WindowsDateEntry({
    super.key,
    required this.date,
    required this.minimumDate,
    required this.maximumDate,
    this.onChanged,
    this.style,
    this.enabled = true,
    this.firstDayOfWeek = 1,
    this.semanticLabel = 'Date',
    this.calendarSemanticLabel = 'Open calendar',
  });

  final DateTime date;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final ValueChanged<DateTime>? onChanged;
  final TextStyle? style;
  final bool enabled;

  /// Monday = 1 … Sunday = 7 (Fluent [CalendarView] convention).
  final int firstDayOfWeek;

  /// Screen-reader label for the segmented date field.
  final String semanticLabel;

  /// Screen-reader label for the calendar overlay button.
  final String calendarSemanticLabel;

  @override
  WindowsDateEntryState createState() => WindowsDateEntryState();
}

class WindowsDateEntryState extends State<WindowsDateEntry> {
  final GlobalKey<SegmentedEntryState> _segmentedKey =
      GlobalKey<SegmentedEntryState>();
  final _flyoutController = FlyoutController();

  late final DateEntryController _controller;

  /// Focus the day segment (`DD`).
  void focusDaySegment() => _segmentedKey.currentState?.focusSegment(0);

  /// Focus the month segment (`MM`).
  void focusMonthSegment() => _segmentedKey.currentState?.focusSegment(1);

  @override
  void initState() {
    super.initState();
    _controller = DateEntryController(initialDate: widget.date);
  }

  @override
  void didUpdateWidget(covariant WindowsDateEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateEntryController.isSameDate(oldWidget.date, widget.date)) {
      _controller.syncFromDate(widget.date);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flyoutController.dispose();
    super.dispose();
  }

  void _openCalendar() {
    _flyoutController.showFlyout<void>(
      barrierColor: Colors.transparent,
      additionalOffset: 8,
      builder: (context) {
        final theme = FluentTheme.of(context);
        return Mica(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 350, maxWidth: 320),
            decoration: BoxDecoration(
              color: theme.resources.controlFillColorDefault,
              borderRadius: BorderRadius.circular(6),
            ),
            child: CalendarView(
              initialStart: widget.date,
              minDate: widget.minimumDate,
              maxDate: widget.maximumDate,
              firstDayOfWeek: widget.firstDayOfWeek,
              onSelectionChanged: (selection) {
                final date = selection.startDate;
                if (date == null) return;
                _controller.applyPickedDate(
                  date,
                  currentDate: widget.date,
                  onChanged: widget.onChanged,
                );
                _flyoutController.close();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final fieldStyle = widget.style ?? theme.typography.body;

    return FlyoutTarget(
      controller: _flyoutController,
      child: WindowsSegmentedFieldWithButton(
        enabled: widget.enabled,
        semanticLabel: widget.semanticLabel,
        fieldValue: _controller.fieldValue,
        fieldWidth: SegmentedFieldMetrics.dateSegmentClusterWidth,
        buttonSemanticLabel: widget.calendarSemanticLabel,
        buttonIcon: FluentIcons.calendar,
        onButtonPressed: widget.enabled ? _openCalendar : null,
        segmentedField: SegmentedEntry(
          key: _segmentedKey,
          controller: _controller.entryController,
          segments: _controller.segments,
          delimiters: const ['.', '.'],
          style: fieldStyle,
          enabled: widget.enabled,
          onChanged: (_) => _controller.emitChanged(
            currentDate: widget.date,
            minimumDate: widget.minimumDate,
            maximumDate: widget.maximumDate,
            onChanged: widget.onChanged,
          ),
          onFocusLost: () => _controller.commitOrRestore(
            currentDate: widget.date,
            minimumDate: widget.minimumDate,
            maximumDate: widget.maximumDate,
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}

import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/widgets/segmented_entry/date_entry_controller.dart';
import 'package:timesheet/ui/widgets/segmented_entry/macos_segmented_field_chrome.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_entry.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';

/// A compact macOS-styled date entry: typeable `d.M` segments plus a calendar
/// button that opens the existing Cupertino calendar overlay.
class MacosDateEntry extends StatefulWidget {
  const MacosDateEntry({
    super.key,
    required this.date,
    required this.minimumDate,
    required this.maximumDate,
    this.onChanged,
    this.style,
    this.enabled = true,
    this.firstDayOfWeekIndex = 1,
    this.semanticLabel = 'Date',
    this.calendarSemanticLabel = 'Open calendar',
  });

  final DateTime date;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final ValueChanged<DateTime>? onChanged;
  final TextStyle? style;
  final bool enabled;
  final int firstDayOfWeekIndex;

  /// Screen-reader label for the segmented date field.
  final String semanticLabel;

  /// Screen-reader label for the calendar overlay button.
  final String calendarSemanticLabel;

  @override
  MacosDateEntryState createState() => MacosDateEntryState();
}

class MacosDateEntryState extends State<MacosDateEntry> {
  final GlobalKey _anchorKey = GlobalKey();
  final GlobalKey<SegmentedEntryState> _segmentedKey =
      GlobalKey<SegmentedEntryState>();

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
  void didUpdateWidget(covariant MacosDateEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateEntryController.isSameDate(oldWidget.date, widget.date)) {
      _controller.syncFromDate(widget.date);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCalendar() async {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final selected = await showCupertinoCalendarPicker(
      context,
      widgetRenderBox: box,
      minimumDateTime: widget.minimumDate,
      maximumDateTime: widget.maximumDate,
      initialDateTime: widget.date,
      firstDayOfWeekIndex: widget.firstDayOfWeekIndex,
      mode: CupertinoCalendarMode.date,
    );
    if (selected == null || !mounted) return;
    _controller.applyPickedDate(
      selected,
      currentDate: widget.date,
      onChanged: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final fieldStyle = widget.style ?? theme.typography.body;

    return MacosSegmentedFieldWithButton(
      key: _anchorKey,
      enabled: widget.enabled,
      semanticLabel: widget.semanticLabel,
      fieldValue: _controller.fieldValue,
      fieldWidth: SegmentedFieldMetrics.dateSegmentClusterWidth,
      buttonSemanticLabel: widget.calendarSemanticLabel,
      buttonIcon: CupertinoIcons.calendar,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:timesheet/ui/widgets/segmented_entry/date_entry_controller.dart';
import 'package:timesheet/ui/widgets/segmented_entry/linux_segmented_field_chrome.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_entry.dart';
import 'package:yaru/yaru.dart';

/// A compact Linux-styled date entry: typeable `d.M` segments plus a
/// calendar button that opens a Yaru-styled date dialog.
class LinuxDateEntry extends StatefulWidget {
  const LinuxDateEntry({
    super.key,
    required this.date,
    required this.minimumDate,
    required this.maximumDate,
    this.onChanged,
    this.style,
    this.enabled = true,
    this.semanticLabel = 'Date',
    this.calendarSemanticLabel = 'Open calendar',
  });

  final DateTime date;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final ValueChanged<DateTime>? onChanged;
  final TextStyle? style;
  final bool enabled;

  /// Screen-reader label for the segmented date field.
  final String semanticLabel;

  /// Screen-reader label for the calendar overlay button.
  final String calendarSemanticLabel;

  @override
  LinuxDateEntryState createState() => LinuxDateEntryState();
}

class LinuxDateEntryState extends State<LinuxDateEntry> {
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
  void didUpdateWidget(covariant LinuxDateEntry oldWidget) {
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
    var selected = widget.date;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(
            kYaruPagePadding,
            kYaruPagePadding,
            kYaruPagePadding,
            0,
          ),
          title: const YaruDialogTitleBar(title: Text('Select date')),
          content: SizedBox(
            width: 320,
            height: 320,
            child: CalendarDatePicker(
              initialDate: widget.date,
              firstDate: widget.minimumDate,
              lastDate: widget.maximumDate,
              onDateChanged: (value) => selected = value,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(selected),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
    if (picked == null || !mounted) return;
    _controller.applyPickedDate(
      picked,
      currentDate: widget.date,
      onChanged: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldStyle =
        (widget.style ?? theme.textTheme.bodyMedium)?.copyWith(
          color: LinuxSegmentedFieldChrome.foregroundColor(theme),
        );

    return LinuxSegmentedFieldWithButton(
      enabled: widget.enabled,
      semanticLabel: widget.semanticLabel,
      fieldValue: _controller.fieldValue,
      fieldWidth: LinuxSegmentedFieldChrome.dateSegmentClusterWidth,
      buttonSemanticLabel: widget.calendarSemanticLabel,
      buttonIcon: YaruIcons.calendar,
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

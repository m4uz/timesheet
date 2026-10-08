import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/widgets/segmented_entry/entry_segment.dart';
import 'package:timesheet/ui/widgets/segmented_entry/macos_segmented_field_chrome.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_entry.dart';

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

  late NumericSegment _daySegment;
  late NumericSegment _monthSegment;
  SegmentedEntryController? _entryController;
  bool _cancelOnChanged = false;

  /// Focus the day segment (`DD`).
  void focusDaySegment() => _segmentedKey.currentState?.focusSegment(0);

  /// Focus the month segment (`MM`).
  void focusMonthSegment() => _segmentedKey.currentState?.focusSegment(1);

  @override
  void initState() {
    super.initState();
    _createSegments();
  }

  @override
  void didUpdateWidget(covariant MacosDateEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDate(oldWidget.date, widget.date)) {
      _syncFromDate(widget.date);
    }
  }

  @override
  void dispose() {
    _daySegment.dispose();
    _monthSegment.dispose();
    _entryController?.dispose();
    super.dispose();
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _createSegments() {
    _daySegment = NumericSegment.fixed(
      length: 2,
      initialValue: widget.date.day,
      placeholderLetter: '-',
      minValue: 1,
      maxValue: 31,
      arrowStep: 1,
      onValueChange: _onDayValueChange,
      onInputCallback: _onDayDigitInput,
      onUpArrowKeyCallback: _onDayArrow,
      onDownArrowKeyCallback: _onDayArrow,
    );

    _monthSegment = NumericSegment.fixed(
      length: 2,
      initialValue: widget.date.month,
      placeholderLetter: '-',
      minValue: 1,
      maxValue: 12,
      arrowStep: 1,
      onValueChange: clampSegment(1, 12),
      onInputCallback: _onMonthDigitInput,
    );

    _entryController = SegmentedEntryController(length: 2);
  }

  /// Allow transient `0` while the day segment is still being typed.
  int? _onDayValueChange(String? input, int? value, int? oldValue) {
    if (value == null) return oldValue ?? 1;
    if (value > 31) return 31;
    if (value < 1) {
      if (input != null && input.length < 2) return value;
      return 1;
    }
    return value;
  }

  int? _onDayDigitInput(String? input, int? value, int? oldValue) {
    if (value == null) return oldValue;
    if (value > 31) return 31;
    if (value < 1) {
      if (input != null && input.length < 2) return value;
      return 1;
    }
    if (input?.length == 1 && value > 3 && value < 10) {
      _entryController?.maybeSelectNextSegment();
    }
    return value;
  }

  int? _onMonthDigitInput(String? input, int? value, int? oldValue) {
    if (value == null) return oldValue;
    if (value > 12) return 12;
    if (value < 1) {
      if (input != null && input.length < 2) return value;
      return 1;
    }
    if (input?.length == 1 && value > 1 && value < 10) {
      _entryController?.maybeSelectNextSegment();
    }
    return value;
  }

  int? _onDayArrow(String? input, int? value, int? oldValue) {
    if (value == null) return oldValue ?? 1;
    final month = _monthSegment.value ?? widget.date.month;
    final year = widget.date.year;
    final maxDay = DateTime(year, month + 1, 0).day;
    if (value > maxDay) return 1;
    if (value < 1) return maxDay;
    return value;
  }

  void _syncFromDate(DateTime date) {
    _cancelOnChanged = true;
    _daySegment.value = date.day;
    _monthSegment.value = date.month;
    _cancelOnChanged = false;
  }

  DateTime? _tryParse() {
    final day = _daySegment.value;
    final month = _monthSegment.value;
    if (day == null || month == null) return null;
    // Incomplete typing (e.g. day still "0") — do not emit yet.
    if (day < 1 || month < 1) return null;

    final year = widget.date.year;
    final maxDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, maxDay);

    final candidate = DateTime(year, month, safeDay);
    if (candidate.isBefore(_dateOnly(widget.minimumDate)) ||
        candidate.isAfter(_dateOnly(widget.maximumDate))) {
      return null;
    }
    return candidate;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _withPreservedTime(DateTime date) => date.copyWith(
    hour: widget.date.hour,
    minute: widget.date.minute,
    second: widget.date.second,
    millisecond: widget.date.millisecond,
    microsecond: widget.date.microsecond,
  );

  void _emitChanged() {
    if (_cancelOnChanged) return;
    final parsed = _tryParse();
    if (parsed == null) return;

    // Keep the day segment in sync if we clamped for month length.
    if (_daySegment.value != parsed.day) {
      _cancelOnChanged = true;
      _daySegment.value = parsed.day;
      _cancelOnChanged = false;
    }

    if (_isSameDate(parsed, widget.date)) return;

    widget.onChanged?.call(_withPreservedTime(parsed));
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
    if (_isSameDate(selected, widget.date)) return;

    _syncFromDate(selected);
    widget.onChanged?.call(_withPreservedTime(selected));
  }

  String get _fieldValue => '${_daySegment.text}.${_monthSegment.text}.';

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final fieldStyle = widget.style ?? theme.typography.body;

    return MacosSegmentedFieldWithButton(
      key: _anchorKey,
      enabled: widget.enabled,
      semanticLabel: widget.semanticLabel,
      fieldValue: _fieldValue,
      fieldWidth: MacosSegmentedFieldChrome.dateSegmentClusterWidth,
      buttonSemanticLabel: widget.calendarSemanticLabel,
      buttonIcon: CupertinoIcons.calendar,
      onButtonPressed: _openCalendar,
      segmentedField: SegmentedEntry(
        key: _segmentedKey,
        controller: _entryController,
        segments: [_daySegment, _monthSegment],
        delimiters: const ['.', '.'],
        style: fieldStyle,
        onChanged: (_) => _emitChanged(),
      ),
    );
  }
}

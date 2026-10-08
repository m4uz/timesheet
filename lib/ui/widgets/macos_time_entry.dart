import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/widgets/segmented_entry/entry_segment.dart';
import 'package:timesheet/ui/widgets/segmented_entry/macos_segmented_field_chrome.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_entry.dart';

/// Snaps [time] to the nearest [minuteInterval] step for Cupertino picker wheels.
TimeOfDay snapTimeToMinuteInterval(TimeOfDay time, int minuteInterval) {
  if (minuteInterval <= 1) return time;
  final totalMinutes = time.hour * 60 + time.minute;
  final snapped = (totalMinutes / minuteInterval).round() * minuteInterval;
  return TimeOfDay(hour: (snapped ~/ 60) % 24, minute: snapped % 60);
}

/// A compact macOS-styled HH:mm segmented time entry (Yaru-inspired) with an
/// optional Cupertino time-picker overlay button.
class MacosTimeEntry extends StatefulWidget {
  const MacosTimeEntry({
    super.key,
    required this.time,
    this.minuteInterval = 1,
    this.onChanged,
    this.style,
    this.enabled = true,
    this.semanticLabel = 'Time',
    this.pickerSemanticLabel = 'Open time picker',
    this.use24hFormat = true,
  }) : assert(minuteInterval > 0 && minuteInterval <= 60);

  final TimeOfDay time;
  final int minuteInterval;
  final ValueChanged<TimeOfDay>? onChanged;
  final TextStyle? style;
  final bool enabled;

  /// Screen-reader label for the segmented time field.
  final String semanticLabel;

  /// Screen-reader label for the time-picker overlay button.
  final String pickerSemanticLabel;

  /// Whether the overlay wheel uses 24-hour format.
  final bool use24hFormat;

  @override
  State<MacosTimeEntry> createState() => _MacosTimeEntryState();
}

class _MacosTimeEntryState extends State<MacosTimeEntry> {
  final GlobalKey _anchorKey = GlobalKey();

  late NumericSegment _hourSegment;
  late NumericSegment _minuteSegment;
  SegmentedEntryController? _entryController;
  bool _cancelOnChanged = false;

  @override
  void initState() {
    super.initState();
    _createSegments();
  }

  @override
  void didUpdateWidget(covariant MacosTimeEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minuteInterval != widget.minuteInterval) {
      _minuteSegment.arrowStep = widget.minuteInterval;
    }
    if (oldWidget.time != widget.time) {
      _syncFromTime(widget.time);
    }
  }

  @override
  void dispose() {
    _hourSegment.dispose();
    _minuteSegment.dispose();
    _entryController?.dispose();
    super.dispose();
  }

  void _createSegments() {
    _hourSegment = NumericSegment.fixed(
      length: 2,
      initialValue: widget.time.hour,
      placeholderLetter: '-',
      minValue: 0,
      maxValue: 23,
      arrowStep: 1,
      onValueChange: clampSegment(0, 23),
      onInputCallback: _onDigitInput(23),
    );

    _minuteSegment = NumericSegment.fixed(
      length: 2,
      initialValue: widget.time.minute,
      placeholderLetter: '-',
      minValue: 0,
      maxValue: 59,
      arrowStep: widget.minuteInterval,
      onValueChange: clampSegment(0, 59),
      onInputCallback: _onDigitInput(59),
    );

    _entryController = SegmentedEntryController(length: 2);
  }

  NumericSegmentCallback _onDigitInput(int maxValue) {
    return (input, value, oldValue) {
      if (value == null) return oldValue;
      if (value > maxValue) return maxValue;
      if (value < 0) return 0;

      // Auto-advance when a single digit already can't lead to a valid
      // continuation within maxValue (e.g. typing "3" for hours → 30+ invalid).
      if (input?.length == 1 && value > maxValue ~/ 10 && value < 10) {
        _entryController?.maybeSelectNextSegment();
      }
      return value;
    };
  }

  void _syncFromTime(TimeOfDay time) {
    _cancelOnChanged = true;
    _hourSegment.value = time.hour;
    _minuteSegment.value = time.minute;
    _cancelOnChanged = false;
  }

  void _emitChanged() {
    if (_cancelOnChanged) return;
    final hour = _hourSegment.value;
    final minute = _minuteSegment.value;
    if (hour == null || minute == null) return;
    if (hour == widget.time.hour && minute == widget.time.minute) return;
    widget.onChanged?.call(TimeOfDay(hour: hour, minute: minute));
  }

  Future<void> _openTimePicker() async {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final initialTime = snapTimeToMinuteInterval(
      widget.time,
      widget.minuteInterval,
    );
    final selected = await showCupertinoTimePicker(
      context,
      widgetRenderBox: box,
      initialTime: initialTime,
      minuteInterval: widget.minuteInterval,
      use24hFormat: widget.use24hFormat,
    );
    if (selected == null || !mounted) return;
    if (selected.hour == widget.time.hour &&
        selected.minute == widget.time.minute) {
      return;
    }

    _syncFromTime(selected);
    widget.onChanged?.call(selected);
  }

  String get _fieldValue => '${_hourSegment.text}:${_minuteSegment.text}';

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final fieldStyle = widget.style ?? theme.typography.body;

    return MacosSegmentedFieldWithButton(
      key: _anchorKey,
      enabled: widget.enabled,
      semanticLabel: widget.semanticLabel,
      fieldValue: _fieldValue,
      fieldWidth: MacosSegmentedFieldChrome.segmentClusterWidth,
      buttonSemanticLabel: widget.pickerSemanticLabel,
      buttonIcon: CupertinoIcons.clock,
      onButtonPressed: _openTimePicker,
      segmentedField: SegmentedEntry(
        controller: _entryController,
        segments: [_hourSegment, _minuteSegment],
        delimiters: const [':'],
        style: fieldStyle,
        onChanged: (_) => _emitChanged(),
      ),
    );
  }
}

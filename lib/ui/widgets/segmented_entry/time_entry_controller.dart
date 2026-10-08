import 'package:flutter/material.dart';
import 'package:timesheet/ui/widgets/segmented_entry/entry_segment.dart';

/// Shared hour/minute segment logic for `HH:mm` time entries (Yaru-inspired).
///
/// Platform widgets own chrome and time pickers; this controller owns typing
/// and emit. Typed minutes are not snapped to [minuteInterval] — only arrow
/// steps and picker overlays use the interval.
class TimeEntryController {
  TimeEntryController({
    required TimeOfDay initialTime,
    this.minuteInterval = 1,
  }) : assert(minuteInterval > 0 && minuteInterval <= 60),
       _time = initialTime {
    _createSegments();
  }

  TimeOfDay _time;
  int minuteInterval;

  late final NumericSegment hourSegment;
  late final NumericSegment minuteSegment;
  late final SegmentedEntryController entryController;

  bool _cancelOnChanged = false;

  List<EntrySegment> get segments => [hourSegment, minuteSegment];

  String get fieldValue => '${hourSegment.text}:${minuteSegment.text}';

  void _createSegments() {
    hourSegment = NumericSegment.fixed(
      length: 2,
      initialValue: _time.hour,
      placeholderLetter: '-',
      minValue: 0,
      maxValue: 23,
      arrowStep: 1,
      onValueChange: clampSegment(0, 23),
      onInputCallback: _onDigitInput(23),
    );

    minuteSegment = NumericSegment.fixed(
      length: 2,
      initialValue: _time.minute,
      placeholderLetter: '-',
      minValue: 0,
      maxValue: 59,
      arrowStep: minuteInterval,
      onValueChange: clampSegment(0, 59),
      onInputCallback: _onDigitInput(59),
    );

    entryController = SegmentedEntryController(length: 2);
  }

  NumericSegmentCallback _onDigitInput(int maxValue) {
    return (input, value, oldValue) {
      if (value == null) return oldValue;
      if (value > maxValue) return maxValue;
      if (value < 0) return 0;

      // Auto-advance when a single digit already can't lead to a valid
      // continuation within maxValue (e.g. typing "3" for hours → 30+ invalid).
      if (input?.length == 1 && value > maxValue ~/ 10 && value < 10) {
        entryController.maybeSelectNextSegment();
      }
      return value;
    };
  }

  void setMinuteInterval(int interval) {
    assert(interval > 0 && interval <= 60);
    minuteInterval = interval;
    minuteSegment.arrowStep = interval;
  }

  void syncFromTime(TimeOfDay time) {
    _cancelOnChanged = true;
    _time = time;
    hourSegment.value = time.hour;
    minuteSegment.value = time.minute;
    _cancelOnChanged = false;
  }

  void emitChanged({
    required TimeOfDay currentTime,
    required ValueChanged<TimeOfDay>? onChanged,
  }) {
    if (_cancelOnChanged) return;
    _time = currentTime;
    final hour = hourSegment.value;
    final minute = minuteSegment.value;
    if (hour == null || minute == null) return;
    if (hour == currentTime.hour && minute == currentTime.minute) return;
    onChanged?.call(TimeOfDay(hour: hour, minute: minute));
  }

  void applyPickedTime(
    TimeOfDay selected, {
    required TimeOfDay currentTime,
    required ValueChanged<TimeOfDay>? onChanged,
  }) {
    if (selected.hour == currentTime.hour &&
        selected.minute == currentTime.minute) {
      return;
    }
    syncFromTime(selected);
    onChanged?.call(selected);
  }

  void dispose() {
    hourSegment.dispose();
    minuteSegment.dispose();
    entryController.dispose();
  }
}

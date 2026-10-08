import 'package:flutter/material.dart';
import 'package:timesheet/ui/widgets/segmented_entry/entry_segment.dart';
import 'package:timesheet/utils/time_of_day_utils.dart';

/// Shared hour/minute segment logic for `HH:mm` time entries (Yaru-inspired).
///
/// Platform widgets own chrome and time pickers; this controller owns typing
/// and emit. [emitChanged] only fires when both segments are complete (not
/// mid-digit). [commitOrRestore] runs on focus loss. Typed minutes are snapped
/// to [minuteInterval] on commit; arrow steps also use the interval.
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
    hourSegment.input = null;
    minuteSegment.input = null;
    hourSegment.value = time.hour;
    minuteSegment.value = time.minute;
    _cancelOnChanged = false;
  }

  /// True while a segment still has a non-definitive partial digit buffer.
  bool get hasIncompleteInput =>
      _isMidEdit(hourSegment) || _isMidEdit(minuteSegment);

  static bool _isMidEdit(NumericSegment segment) {
    final input = segment.input;
    if (input == null || input.isEmpty) return false;
    if (input.length >= segment.minLength) return false;
    final value = int.tryParse(input);
    final max = segment.maxValue;
    // Same rule as auto-advance: a single digit that can't grow further is
    // already a complete value (e.g. hour "3" → 03).
    if (value != null && max != null && value > max ~/ 10) {
      return false;
    }
    return true;
  }

  void _clearDefinitivePartialInputs() {
    for (final segment in [hourSegment, minuteSegment]) {
      if (_isMidEdit(segment)) continue;
      final input = segment.input;
      if (input != null && input.length < segment.minLength) {
        segment.input = null;
      }
    }
  }

  TimeOfDay? _committedTime() {
    final hour = hourSegment.value;
    final minute = minuteSegment.value;
    if (hour == null || minute == null) return null;
    if (hasIncompleteInput) return null;
    _clearDefinitivePartialInputs();
    return snapTimeToMinuteInterval(
      TimeOfDay(hour: hour, minute: minute),
      minuteInterval,
    );
  }

  /// Emit when both segments are complete. No-op while mid-digit typing.
  void emitChanged({
    required TimeOfDay currentTime,
    required ValueChanged<TimeOfDay>? onChanged,
  }) {
    if (_cancelOnChanged) return;
    _time = currentTime;
    final next = _committedTime();
    if (next == null) return;

    if (next.minute != minuteSegment.value || next.hour != hourSegment.value) {
      syncFromTime(next);
    }

    if (next.hour == currentTime.hour && next.minute == currentTime.minute) {
      return;
    }
    onChanged?.call(next);
  }

  /// Focus-loss: commit a complete value, otherwise restore [currentTime].
  void commitOrRestore({
    required TimeOfDay currentTime,
    required ValueChanged<TimeOfDay>? onChanged,
  }) {
    if (_cancelOnChanged) return;
    _time = currentTime;
    final next = _committedTime();
    if (next == null) {
      syncFromTime(currentTime);
      return;
    }

    if (next.minute != minuteSegment.value || next.hour != hourSegment.value) {
      syncFromTime(next);
    }

    if (next.hour == currentTime.hour && next.minute == currentTime.minute) {
      // Still refresh display in case placeholders were showing.
      if (hourSegment.value != next.hour || minuteSegment.value != next.minute) {
        syncFromTime(currentTime);
      }
      return;
    }
    onChanged?.call(next);
  }

  void applyPickedTime(
    TimeOfDay selected, {
    required TimeOfDay currentTime,
    required ValueChanged<TimeOfDay>? onChanged,
  }) {
    final snapped = snapTimeToMinuteInterval(selected, minuteInterval);
    if (snapped.hour == currentTime.hour &&
        snapped.minute == currentTime.minute) {
      syncFromTime(snapped);
      return;
    }
    syncFromTime(snapped);
    onChanged?.call(snapped);
  }

  void dispose() {
    hourSegment.dispose();
    minuteSegment.dispose();
    entryController.dispose();
  }
}

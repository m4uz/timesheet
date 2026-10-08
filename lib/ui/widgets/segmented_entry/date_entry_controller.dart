import 'package:flutter/widgets.dart';
import 'package:timesheet/ui/widgets/segmented_entry/entry_segment.dart';

/// Shared day/month segment logic for `DD.MM.` date entries (Yaru-inspired).
///
/// Platform widgets own chrome and calendar overlays; this controller owns
/// typing, clamping, parse, and emit. [emitChanged] only fires when both
/// segments are complete (not mid-digit). [commitOrRestore] runs on focus loss.
class DateEntryController {
  DateEntryController({required DateTime initialDate}) : _date = initialDate {
    _createSegments();
  }

  DateTime _date;
  late final NumericSegment daySegment;
  late final NumericSegment monthSegment;
  late final SegmentedEntryController entryController;

  bool _cancelOnChanged = false;

  List<EntrySegment> get segments => [daySegment, monthSegment];

  /// Display value including the trailing German-style `.`.
  String get fieldValue => '${daySegment.text}.${monthSegment.text}.';

  static bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime withPreservedTime(DateTime date, DateTime from) =>
      date.copyWith(
        hour: from.hour,
        minute: from.minute,
        second: from.second,
        millisecond: from.millisecond,
        microsecond: from.microsecond,
      );

  void _createSegments() {
    daySegment = NumericSegment.fixed(
      length: 2,
      initialValue: _date.day,
      placeholderLetter: '-',
      minValue: 1,
      maxValue: 31,
      arrowStep: 1,
      onValueChange: _onDayValueChange,
      onInputCallback: _onDayDigitInput,
      onUpArrowKeyCallback: _onDayArrow,
      onDownArrowKeyCallback: _onDayArrow,
    );

    monthSegment = NumericSegment.fixed(
      length: 2,
      initialValue: _date.month,
      placeholderLetter: '-',
      minValue: 1,
      maxValue: 12,
      arrowStep: 1,
      onValueChange: clampSegment(1, 12),
      onInputCallback: _onMonthDigitInput,
    );

    entryController = SegmentedEntryController(length: 2);
  }

  /// Allow transient `0` while the day segment is still being typed.
  int? _onDayValueChange(String? input, int? value, int? oldValue) {
    if (value == null) return null;
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
      entryController.maybeSelectNextSegment();
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
      entryController.maybeSelectNextSegment();
    }
    return value;
  }

  int? _onDayArrow(String? input, int? value, int? oldValue) {
    if (value == null) return oldValue ?? 1;
    final month = monthSegment.value ?? _date.month;
    final year = _date.year;
    final maxDay = DateTime(year, month + 1, 0).day;
    if (value > maxDay) return 1;
    if (value < 1) return maxDay;
    return value;
  }

  void syncFromDate(DateTime date) {
    _cancelOnChanged = true;
    _date = date;
    daySegment.input = null;
    monthSegment.input = null;
    daySegment.value = date.day;
    monthSegment.value = date.month;
    _cancelOnChanged = false;
  }

  /// True while a segment still has a non-definitive partial digit buffer.
  bool get hasIncompleteInput =>
      _isMidEdit(daySegment) || _isMidEdit(monthSegment);

  static bool _isMidEdit(NumericSegment segment) {
    final input = segment.input;
    if (input == null || input.isEmpty) return false;
    if (input.length >= segment.minLength) return false;
    final value = int.tryParse(input);
    final max = segment.maxValue;
    if (value != null && max != null && value > max ~/ 10) {
      return false;
    }
    return true;
  }

  void _clearDefinitivePartialInputs() {
    for (final segment in [daySegment, monthSegment]) {
      if (_isMidEdit(segment)) continue;
      final input = segment.input;
      if (input != null && input.length < segment.minLength) {
        segment.input = null;
      }
    }
  }

  /// Date-only parse of the segments; null when incomplete or out of range.
  DateTime? tryParse({
    required DateTime minimumDate,
    required DateTime maximumDate,
  }) {
    if (hasIncompleteInput) return null;
    final day = daySegment.value;
    final month = monthSegment.value;
    if (day == null || month == null) return null;
    // Incomplete typing (e.g. day still "0") — do not emit yet.
    if (day < 1 || month < 1) return null;

    _clearDefinitivePartialInputs();

    final year = _date.year;
    final maxDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, maxDay);

    final candidate = DateTime(year, month, safeDay);
    if (candidate.isBefore(dateOnly(minimumDate)) ||
        candidate.isAfter(dateOnly(maximumDate))) {
      return null;
    }
    return candidate;
  }

  /// Emit when both segments are complete. No-op while mid-digit typing.
  void emitChanged({
    required DateTime currentDate,
    required DateTime minimumDate,
    required DateTime maximumDate,
    required ValueChanged<DateTime>? onChanged,
  }) {
    if (_cancelOnChanged) return;
    _date = currentDate;
    final parsed = tryParse(
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    );
    if (parsed == null) return;

    // Keep the day segment in sync if we clamped for month length.
    if (daySegment.value != parsed.day) {
      _cancelOnChanged = true;
      daySegment.value = parsed.day;
      _cancelOnChanged = false;
    }

    if (isSameDate(parsed, currentDate)) return;

    onChanged?.call(withPreservedTime(parsed, currentDate));
  }

  /// Focus-loss: commit a complete value, otherwise restore [currentDate].
  void commitOrRestore({
    required DateTime currentDate,
    required DateTime minimumDate,
    required DateTime maximumDate,
    required ValueChanged<DateTime>? onChanged,
  }) {
    if (_cancelOnChanged) return;
    _date = currentDate;
    final parsed = tryParse(
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    );
    if (parsed == null) {
      syncFromDate(currentDate);
      return;
    }

    if (daySegment.value != parsed.day) {
      _cancelOnChanged = true;
      daySegment.value = parsed.day;
      _cancelOnChanged = false;
    }

    if (isSameDate(parsed, currentDate)) {
      // Refresh display if placeholders were showing.
      if (daySegment.value != currentDate.day ||
          monthSegment.value != currentDate.month) {
        syncFromDate(currentDate);
      }
      return;
    }
    onChanged?.call(withPreservedTime(parsed, currentDate));
  }

  /// Apply a calendar-picked date (already validated by the picker).
  void applyPickedDate(
    DateTime selected, {
    required DateTime currentDate,
    required ValueChanged<DateTime>? onChanged,
  }) {
    if (isSameDate(selected, currentDate)) return;
    syncFromDate(selected);
    onChanged?.call(withPreservedTime(selected, currentDate));
  }

  void dispose() {
    daySegment.dispose();
    monthSegment.dispose();
    entryController.dispose();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:timesheet/ui/widgets/segmented_entry/date_entry_controller.dart';

void main() {
  group('DateEntryController', () {
    test('fieldValue formats day.month with trailing dot', () {
      final controller = DateEntryController(
        initialDate: DateTime(2026, 10, 7),
      );
      expect(controller.fieldValue, '07.10.');
      controller.dispose();
    });

    test('allows transient 0 before second day digit', () {
      final controller = DateEntryController(
        initialDate: DateTime(2026, 10, 7),
      );
      final day = controller.daySegment;

      day.onSelect(true);
      day.onInput('0');
      expect(day.value, 0);
      expect(day.input, '0');

      day.onInput('1');
      expect(day.value, 1);
      controller.dispose();
    });

    test('tryParse clamps day to month length', () {
      final controller = DateEntryController(
        initialDate: DateTime(2026, 1, 31),
      );
      controller.monthSegment.value = 2;
      controller.daySegment.value = 31;

      final parsed = controller.tryParse(
        minimumDate: DateTime(2025, 1, 1),
        maximumDate: DateTime(2027, 12, 31),
      );
      expect(parsed, DateTime(2026, 2, 28));
      controller.dispose();
    });

    test('tryParse rejects out-of-range dates', () {
      final controller = DateEntryController(
        initialDate: DateTime(2026, 6, 15),
      );
      expect(
        controller.tryParse(
          minimumDate: DateTime(2027, 1, 1),
          maximumDate: DateTime(2027, 12, 31),
        ),
        isNull,
      );
      controller.dispose();
    });

    test('emitChanged preserves time-of-day and skips same calendar day', () {
      final current = DateTime(2026, 10, 7, 9, 30);
      final controller = DateEntryController(initialDate: current);
      DateTime? emitted;

      controller.emitChanged(
        currentDate: current,
        minimumDate: DateTime(2025, 1, 1),
        maximumDate: DateTime(2027, 12, 31),
        onChanged: (d) => emitted = d,
      );
      expect(emitted, isNull);

      controller.daySegment.value = 8;
      controller.emitChanged(
        currentDate: current,
        minimumDate: DateTime(2025, 1, 1),
        maximumDate: DateTime(2027, 12, 31),
        onChanged: (d) => emitted = d,
      );
      expect(emitted, DateTime(2026, 10, 8, 9, 30));
      controller.dispose();
    });

    test('applyPickedDate syncs segments and preserves time', () {
      final current = DateTime(2026, 10, 7, 14, 15);
      final controller = DateEntryController(initialDate: current);
      DateTime? emitted;

      controller.applyPickedDate(
        DateTime(2026, 11, 1),
        currentDate: current,
        onChanged: (d) => emitted = d,
      );

      expect(controller.fieldValue, '01.11.');
      expect(emitted, DateTime(2026, 11, 1, 14, 15));
      controller.dispose();
    });

    test('emitChanged skips mid-digit day typing', () {
      final current = DateTime(2026, 10, 7, 9, 30);
      final controller = DateEntryController(initialDate: current);
      var calls = 0;
      final day = controller.daySegment;
      day.onSelect(true);
      day.onInput('1');
      controller.emitChanged(
        currentDate: current,
        minimumDate: DateTime(2025, 1, 1),
        maximumDate: DateTime(2027, 12, 31),
        onChanged: (_) => calls++,
      );
      expect(calls, 0);
      expect(controller.hasIncompleteInput, isTrue);

      day.onInput('5');
      controller.emitChanged(
        currentDate: current,
        minimumDate: DateTime(2025, 1, 1),
        maximumDate: DateTime(2027, 12, 31),
        onChanged: (_) => calls++,
      );
      expect(calls, 1);
      controller.dispose();
    });

    test('commitOrRestore restores cleared segments', () {
      final current = DateTime(2026, 10, 7, 9, 30);
      final controller = DateEntryController(initialDate: current);
      var calls = 0;
      controller.daySegment.onSelect(true);
      controller.daySegment.onBackspaceKey();
      expect(controller.daySegment.value, isNull);

      controller.commitOrRestore(
        currentDate: current,
        minimumDate: DateTime(2025, 1, 1),
        maximumDate: DateTime(2027, 12, 31),
        onChanged: (_) => calls++,
      );
      expect(calls, 0);
      expect(controller.fieldValue, '07.10.');
      controller.dispose();
    });
  });
}

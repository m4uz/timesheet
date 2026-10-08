import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timesheet/ui/widgets/segmented_entry/time_entry_controller.dart';

void main() {
  group('TimeEntryController', () {
    test('fieldValue formats HH:mm', () {
      final controller = TimeEntryController(
        initialTime: const TimeOfDay(hour: 14, minute: 30),
      );
      expect(controller.fieldValue, '14:30');
      controller.dispose();
    });

    test('arrow up on minutes respects minuteInterval', () {
      final controller = TimeEntryController(
        initialTime: const TimeOfDay(hour: 10, minute: 0),
        minuteInterval: 15,
      );

      controller.minuteSegment.onSelect(true);
      controller.minuteSegment.onUpArrowKey();
      expect(controller.minuteSegment.value, 15);
      controller.dispose();
    });

    test('setMinuteInterval updates arrowStep', () {
      final controller = TimeEntryController(
        initialTime: const TimeOfDay(hour: 10, minute: 0),
        minuteInterval: 1,
      );
      controller.setMinuteInterval(15);
      controller.minuteSegment.onSelect(true);
      controller.minuteSegment.onUpArrowKey();
      expect(controller.minuteSegment.value, 15);
      controller.dispose();
    });

    test('emitChanged skips when value unchanged', () {
      final controller = TimeEntryController(
        initialTime: const TimeOfDay(hour: 14, minute: 30),
      );
      var calls = 0;
      controller.emitChanged(
        currentTime: const TimeOfDay(hour: 14, minute: 30),
        onChanged: (_) => calls++,
      );
      expect(calls, 0);
      controller.dispose();
    });

    test('emitChanged reports typed hour/minute', () {
      final controller = TimeEntryController(
        initialTime: const TimeOfDay(hour: 14, minute: 30),
      );
      TimeOfDay? emitted;
      controller.hourSegment.value = 15;
      controller.emitChanged(
        currentTime: const TimeOfDay(hour: 14, minute: 30),
        onChanged: (t) => emitted = t,
      );
      expect(emitted, const TimeOfDay(hour: 15, minute: 30));
      controller.dispose();
    });

    test('clamps typed hour above 23', () {
      final controller = TimeEntryController(
        initialTime: const TimeOfDay(hour: 0, minute: 0),
      );
      final hour = controller.hourSegment;
      hour.onSelect(true);
      hour.onInput('9');
      hour.onInput('9');
      expect(hour.value, 23);
      controller.dispose();
    });
  });
}

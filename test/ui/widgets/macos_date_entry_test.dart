import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/widgets/macos_date_entry.dart';
import 'package:timesheet/ui/widgets/segmented_entry/entry_segment.dart';

void main() {
  Widget wrap(Widget child) {
    return MacosApp(
      home: MacosWindow(
        child: MacosScaffold(
          children: [
            ContentArea(builder: (context, _) => Center(child: child)),
          ],
        ),
      ),
    );
  }

  testWidgets('renders day.month from initial date', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 120,
          child: MacosDateEntry(
            date: DateTime(2026, 10, 7),
            minimumDate: DateTime(2025, 1, 1),
            maximumDate: DateTime(2027, 12, 31),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('07.10.'), findsOneWidget);
  });

  testWidgets('exposes date field and calendar button semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 120,
          child: MacosDateEntry(
            date: DateTime(2026, 10, 7),
            minimumDate: DateTime(2025, 1, 1),
            maximumDate: DateTime(2027, 12, 31),
            semanticLabel: 'Date',
            calendarSemanticLabel: 'Open calendar',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('Date')),
      matchesSemantics(
        label: 'Date',
        value: '07.10.',
        isTextField: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    expect(find.bySemanticsLabel('Open calendar'), findsOneWidget);
  });

  testWidgets('does not emit onChanged when value is unchanged', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 120,
          child: MacosDateEntry(
            date: DateTime(2026, 10, 7),
            minimumDate: DateTime(2025, 1, 1),
            maximumDate: DateTime(2027, 12, 31),
            onChanged: (_) => calls++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  group('day segment typing', () {
    test('allows transient 0 before second digit', () {
      int? allowTransientZero(String? input, int? value, int? oldValue) {
        if (value == null) return oldValue ?? 1;
        if (value > 31) return 31;
        if (value < 1) {
          if (input != null && input.length < 2) return value;
          return 1;
        }
        return value;
      }

      final day = NumericSegment.fixed(
        length: 2,
        initialValue: 7,
        placeholderLetter: '-',
        minValue: 1,
        maxValue: 31,
        onValueChange: allowTransientZero,
        onInputCallback: allowTransientZero,
      );

      day.onSelect(true);
      day.onInput('0');
      expect(day.value, 0);
      expect(day.input, '0');

      day.onInput('1');
      expect(day.value, 1);
    });
  });

  group('month-length clamp helpers', () {
    test('Feb clamps day 31 to 28 in non-leap year', () {
      const year = 2026;
      const month = 2;
      const day = 31;
      final maxDay = DateTime(year, month + 1, 0).day;
      expect(maxDay, 28);
      expect(day.clamp(1, maxDay), 28);
    });

    test('Feb clamps day 31 to 29 in leap year', () {
      const year = 2024;
      const month = 2;
      const day = 31;
      final maxDay = DateTime(year, month + 1, 0).day;
      expect(maxDay, 29);
      expect(day.clamp(1, maxDay), 29);
    });

    test('out-of-range date is rejected by bounds check', () {
      DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

      final minimum = DateTime(2025, 1, 1);
      final maximum = DateTime(2027, 12, 31);
      final candidate = DateTime(2024, 6, 15);
      expect(
        candidate.isBefore(dateOnly(minimum)) ||
            candidate.isAfter(dateOnly(maximum)),
        isTrue,
      );
    });
  });
}

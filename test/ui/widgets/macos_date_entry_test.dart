import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/widgets/macos_date_entry.dart';

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
}

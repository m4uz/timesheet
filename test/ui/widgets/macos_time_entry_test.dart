import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/widgets/macos_time_entry.dart';
void main() {
  group('snapTimeToMinuteInterval', () {
    test('returns time unchanged when interval is 1', () {
      const time = TimeOfDay(hour: 8, minute: 7);
      expect(snapTimeToMinuteInterval(time, 1), time);
    });

    test('snaps to nearest 15-minute step', () {
      expect(
        snapTimeToMinuteInterval(const TimeOfDay(hour: 8, minute: 7), 15),
        const TimeOfDay(hour: 8, minute: 0),
      );
      expect(
        snapTimeToMinuteInterval(const TimeOfDay(hour: 8, minute: 8), 15),
        const TimeOfDay(hour: 8, minute: 15),
      );
    });
  });

  group('MacosTimeEntry', () {
    Widget wrap(Widget child) {
      return MacosApp(
        home: MacosWindow(
          child: MacosScaffold(
            children: [
              ContentArea(
                builder: (context, _) => Center(child: child),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders initial time', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 100,
            child: MacosTimeEntry(time: TimeOfDay(hour: 14, minute: 30)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('exposes semantic label and picker button', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 100,
            child: MacosTimeEntry(
              time: TimeOfDay(hour: 14, minute: 30),
              semanticLabel: 'Start time',
              pickerSemanticLabel: 'Open start time picker',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Start time')),
        matchesSemantics(
          label: 'Start time',
          value: '14:30',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      expect(find.bySemanticsLabel('Open start time picker'), findsOneWidget);
    });

    testWidgets('does not emit onChanged when value is unchanged', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 100,
            child: MacosTimeEntry(
              time: const TimeOfDay(hour: 14, minute: 30),
              onChanged: (_) => calls++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MacosTimeEntry));
      await tester.pumpAndSettle();
      expect(calls, 0);
    });

    testWidgets('minute arrow respects minuteInterval', (tester) async {
      TimeOfDay? emitted;
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 100,
            child: MacosTimeEntry(
              time: const TimeOfDay(hour: 10, minute: 0),
              minuteInterval: 15,
              onChanged: (t) => emitted = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(emitted, isNotNull);
      expect(emitted!.hour, 10);
      expect(emitted!.minute, 15);
    });
  });
}

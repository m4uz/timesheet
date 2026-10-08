import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_tab_navigation.dart';

void main() {
  group('TimetrackerRowKeyMap', () {
    test('reuses the same GlobalKey for an id', () {
      final map = TimetrackerRowKeyMap<_DummyState>();
      final a = map.forId(1);
      final b = map.forId(1);
      expect(identical(a, b), isTrue);
    });

    test('pruneTo drops keys for removed ids', () {
      final map = TimetrackerRowKeyMap<_DummyState>();
      final keep = map.forId(1);
      map.forId(2);
      map.pruneTo([1]);
      expect(identical(map.forId(1), keep), isTrue);
      expect(identical(map.forId(2), keep), isFalse);
    });
  });

  group('onDescriptionTabKeyEvent', () {
    testWidgets('handles Tab and invokes callback', (tester) async {
      var called = 0;
      await tester.pumpWidget(const SizedBox());

      final result = onDescriptionTabKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.tab,
          logicalKey: LogicalKeyboardKey.tab,
          timeStamp: Duration.zero,
        ),
        onTabFromDescription: () async {
          called++;
        },
      );

      expect(result, KeyEventResult.handled);
      await tester.pump();
      expect(called, 1);
    });

    testWidgets('ignores Shift+Tab', (tester) async {
      var called = 0;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);

      final result = onDescriptionTabKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.tab,
          logicalKey: LogicalKeyboardKey.tab,
          timeStamp: Duration.zero,
        ),
        onTabFromDescription: () async {
          called++;
        },
      );

      expect(result, KeyEventResult.ignored);
      expect(called, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    });

    test('ignores when handler is null', () {
      final result = onDescriptionTabKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.tab,
          logicalKey: LogicalKeyboardKey.tab,
          timeStamp: Duration.zero,
        ),
        onTabFromDescription: null,
      );
      expect(result, KeyEventResult.ignored);
    });
  });
}

class _DummyState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/widgets/macos_keyboard_search_field.dart';

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

  List<SearchResultItem> subjects() => [
    const SearchResultItem('Alpha urn:alpha', child: Text('Alpha')),
    const SearchResultItem('Beta urn:beta', child: Text('Beta')),
    const SearchResultItem('Gamma urn:gamma', child: Text('Gamma')),
  ];

  testWidgets('arrow keys highlight and Enter selects a result', (
    tester,
  ) async {
    SearchResultItem? selected;
    final controller = TextEditingController();

    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 220,
          child: MacosKeyboardSearchField(
            controller: controller,
            results: subjects(),
            placeholder: 'Subject',
            onResultSelected: (item) => selected = item,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MacosTextField));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.searchKey, 'Beta urn:beta');
  });

  testWidgets('Escape dismisses overlay without selecting', (tester) async {
    SearchResultItem? selected;
    final controller = TextEditingController();

    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 220,
          child: MacosKeyboardSearchField(
            controller: controller,
            results: subjects(),
            onResultSelected: (item) => selected = item,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MacosTextField));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(find.text('Alpha'), findsNothing);
  });
}

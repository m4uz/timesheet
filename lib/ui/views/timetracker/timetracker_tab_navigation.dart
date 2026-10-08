import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timesheet/providers/timetracker_provider.dart';

/// Stable [GlobalKey]s for timetracker rows, keyed by item id.
class TimetrackerRowKeyMap<T extends State> {
  final Map<int, GlobalKey<T>> _keys = {};

  GlobalKey<T> forId(int itemId) {
    return _keys.putIfAbsent(itemId, () => GlobalKey<T>());
  }

  void pruneTo(Iterable<int> itemIds) {
    final keep = itemIds.toSet();
    _keys.removeWhere((id, _) => !keep.contains(id));
  }
}

/// Tab (not Shift+Tab) in a description field: move to the next row's date, or
/// add a row when already on the last item.
///
/// Focus always runs post-frame so newly built rows are mounted.
Future<void> handleTimetrackerTabFromDescription({
  required TimetrackerProvider provider,
  required int index,
  required bool Function() isMounted,
  required void Function(int itemId) focusDateMonth,
}) async {
  final isLast = index >= provider.items.length - 1;
  if (isLast) {
    final beforeCount = provider.items.length;
    await provider.addItem();
    if (!isMounted() || provider.items.length <= beforeCount) return;
    final newItemId = provider.items.last.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusDateMonth(newItemId);
    });
    return;
  }

  final nextItemId = provider.items[index + 1].id;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    focusDateMonth(nextItemId);
  });
}

/// Description-field Tab interceptor shared by macOS and Windows rows.
KeyEventResult onDescriptionTabKeyEvent(
  KeyEvent event, {
  required Future<void> Function()? onTabFromDescription,
}) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }
  if (event.logicalKey != LogicalKeyboardKey.tab) {
    return KeyEventResult.ignored;
  }
  if (HardwareKeyboard.instance.isShiftPressed) {
    return KeyEventResult.ignored;
  }
  final handler = onTabFromDescription;
  if (handler == null) return KeyEventResult.ignored;
  unawaited(handler());
  return KeyEventResult.handled;
}

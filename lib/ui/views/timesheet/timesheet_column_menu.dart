import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:timesheet/ui/views/timesheet/macos/timesheet_column_menu.dart'
    as mac_timesheet_column_menu;
import 'package:timesheet/ui/views/timesheet/windows/timesheet_column_menu.dart'
    as win_timesheet_column_menu;

Future<void> showTimesheetColumnMenu(
  BuildContext context,
  Offset globalPosition,
) {
  if (Platform.isWindows) {
    return win_timesheet_column_menu.showTimesheetColumnMenu(
      context,
      globalPosition,
    );
  }

  return mac_timesheet_column_menu.showTimesheetColumnMenu(
    context,
    globalPosition,
  );
}

import 'package:flutter/material.dart';
import 'package:timesheet/models/timesheet_item.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_column.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_table_body.dart';

class TimesheetTable extends StatelessWidget {
  const TimesheetTable({
    super.key,
    required this.items,
    required this.visibleColumns,
    this.scrollController,
  });

  final List<TimesheetItem> items;
  final List<TimesheetColumn> visibleColumns;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TimesheetTableBody(
      items: items,
      visibleColumns: visibleColumns,
      scrollController: scrollController,
      cellStyle: LinuxLayout.tableCellStyle(theme),
      headerStyle: LinuxLayout.tableHeaderStyle(theme),
      stripeColor: theme.brightness == Brightness.light
          ? const Color.fromRGBO(0, 0, 0, 0.04)
          : const Color.fromRGBO(255, 255, 255, 0.04),
      headerColor: theme.brightness == Brightness.light
          ? const Color.fromRGBO(0, 0, 0, 0.05)
          : const Color.fromRGBO(255, 255, 255, 0.05),
      dividerColor: LinuxLayout.dividerColor(theme),
    );
  }
}

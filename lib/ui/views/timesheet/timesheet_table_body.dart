import 'package:flutter/material.dart';
import 'package:timesheet/models/timesheet_item.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_column.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_column_menu.dart';

class TimesheetTableBody extends StatelessWidget {
  const TimesheetTableBody({
    super.key,
    required this.items,
    required this.visibleColumns,
    required this.scrollController,
    required this.cellStyle,
    required this.headerStyle,
    required this.stripeColor,
    required this.headerColor,
    required this.dividerColor,
  });

  final List<TimesheetItem> items;
  final List<TimesheetColumn> visibleColumns;
  final ScrollController? scrollController;
  final TextStyle cellStyle;
  final TextStyle headerStyle;
  final Color stripeColor;
  final Color headerColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    if (visibleColumns.isEmpty) {
      return const Center(child: Text('No columns selected'));
    }

    final columnWidths = {
      for (var index = 0; index < visibleColumns.length; index++)
        index: visibleColumns[index].tableColumnWidth,
    };

    return SingleChildScrollView(
      controller: scrollController,
      child: Table(
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside: BorderSide(color: dividerColor),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(bottom: BorderSide(color: dividerColor)),
            ),
            children: [
              for (final column in visibleColumns)
                _headerCell(context, column.label),
            ],
          ),
          for (var index = 0; index < items.length; index++)
            TableRow(
              decoration: index.isOdd
                  ? BoxDecoration(color: stripeColor)
                  : null,
              children: [
                for (final column in visibleColumns)
                  _dataCell(column.buildCell(items[index], cellStyle)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        showTimesheetColumnMenu(context, details.globalPosition);
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(label, style: headerStyle, maxLines: 1),
      ),
    );
  }

  Widget _dataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }
}

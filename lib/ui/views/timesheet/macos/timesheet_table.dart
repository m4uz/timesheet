import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/models/timesheet_item.dart';
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
    final theme = MacosTheme.of(context);

    return TimesheetTableBody(
      items: items,
      visibleColumns: visibleColumns,
      scrollController: scrollController,
      cellStyle: theme.typography.title3,
      headerStyle: theme.typography.headline.copyWith(
        fontWeight: FontWeight.w600,
      ),
      stripeColor: theme.brightness == Brightness.light
          ? const Color.fromRGBO(0, 0, 0, 0.04)
          : const Color.fromRGBO(255, 255, 255, 0.04),
      headerColor: theme.brightness == Brightness.light
          ? const Color.fromRGBO(0, 0, 0, 0.05)
          : const Color.fromRGBO(255, 255, 255, 0.05),
      dividerColor: theme.dividerColor,
    );
  }
}

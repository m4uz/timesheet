import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/models/timesheet_item.dart';
import 'package:timesheet/utils/duration_utils.dart';

const _dateW = 120.0;
const _timeW = 80.0;
const _workedW = 80.0;

class TimesheetTable extends StatelessWidget {
  const TimesheetTable({
    super.key,
    required this.items,
    this.scrollController,
  });

  final List<TimesheetItem> items;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final cellStyle = theme.typography.title3;
    final headerStyle = theme.typography.headline.copyWith(
      fontWeight: FontWeight.w600,
    );
    final stripeColor = theme.brightness == Brightness.light
        ? const Color.fromRGBO(0, 0, 0, 0.04)
        : const Color.fromRGBO(255, 255, 255, 0.04);
    final headerColor = theme.brightness == Brightness.light
        ? const Color.fromRGBO(0, 0, 0, 0.05)
        : const Color.fromRGBO(255, 255, 255, 0.05);

    return SingleChildScrollView(
      controller: scrollController,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(_dateW),
          1: FixedColumnWidth(_timeW),
          2: FixedColumnWidth(_timeW),
          3: FixedColumnWidth(_workedW),
          4: FlexColumnWidth(),
          5: FlexColumnWidth(),
          6: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside: BorderSide(color: theme.dividerColor),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            children: [
              _headerCell('Date', headerStyle),
              _headerCell('From', headerStyle),
              _headerCell('To', headerStyle),
              _headerCell('Worked', headerStyle),
              _headerCell('Subject', headerStyle),
              _headerCell('Category', headerStyle),
              _headerCell('Description', headerStyle),
            ],
          ),
          for (int index = 0; index < items.length; index++)
            TableRow(
              decoration: index.isOdd
                  ? BoxDecoration(color: stripeColor)
                  : null,
              children: _dataCells(items[index], cellStyle),
            ),
        ],
      ),
    );
  }

  List<Widget> _dataCells(TimesheetItem item, TextStyle style) {
    final date = DateFormat('yyyy-MM-dd').format(item.from);
    final from = DateFormat('HH:mm').format(item.from);
    final to = DateFormat('HH:mm').format(item.to);
    final worked = toHmString(item.to.difference(item.from));

    return [
      _dataCell(Text(date, style: style)),
      _dataCell(Text(from, style: style)),
      _dataCell(Text(to, style: style)),
      _dataCell(Text(worked, style: style)),
      _dataCell(SelectableText(item.subject, style: style)),
      _dataCell(SelectableText(item.category, style: style)),
      _dataCell(SelectableText(item.description, style: style)),
    ];
  }

  Widget _headerCell(String label, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(label, style: style, maxLines: 1),
    );
  }

  Widget _dataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timesheet/models/timesheet_item.dart';
import 'package:timesheet/utils/duration_utils.dart';

enum TimesheetColumn {
  date('Date', defaultVisible: true, fixedWidth: 120),
  from('From', defaultVisible: false, fixedWidth: 80),
  to('To', defaultVisible: false, fixedWidth: 80),
  worked('Worked', defaultVisible: true, fixedWidth: 80),
  subject('Subject', defaultVisible: true),
  category('Category', defaultVisible: false),
  description('Description', defaultVisible: true);

  const TimesheetColumn(
    this.label, {
    required this.defaultVisible,
    this.fixedWidth,
  });

  final String label;
  final bool defaultVisible;
  final double? fixedWidth;

  bool get isFlex => fixedWidth == null;

  TableColumnWidth get tableColumnWidth =>
      isFlex ? const FlexColumnWidth() : FixedColumnWidth(fixedWidth!);

  Widget buildCell(TimesheetItem item, TextStyle style) {
    return switch (this) {
      TimesheetColumn.date => Text(
        DateFormat('yyyy-MM-dd').format(item.from),
        style: style,
      ),
      TimesheetColumn.from => Text(
        DateFormat('HH:mm').format(item.from),
        style: style,
      ),
      TimesheetColumn.to => Text(
        DateFormat('HH:mm').format(item.to),
        style: style,
      ),
      TimesheetColumn.worked => Text(
        toHmString(item.to.difference(item.from)),
        style: style,
      ),
      TimesheetColumn.subject => SelectableText(item.subject, style: style),
      TimesheetColumn.category => SelectableText(item.category, style: style),
      TimesheetColumn.description => SelectableText(
        item.description,
        style: style,
      ),
    };
  }
}

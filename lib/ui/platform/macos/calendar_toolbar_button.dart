import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/platform/macos/macos_layout.dart';
import 'package:timesheet/ui/widgets/macos_date_entry.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';

class CalendarToolbarButton extends ToolbarItem {
  const CalendarToolbarButton({
    super.key,
    required this.label,
    required this.date,
    required this.minimumDate,
    required this.maximumDate,
    this.onChanged,
  });

  final String label;
  final DateTime date;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final ValueChanged<DateTime>? onChanged;

  @override
  Widget build(BuildContext context, ToolbarItemDisplayMode displayMode) {
    return Padding(
      padding: MacosLayout.toolbarItemPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: MacosTheme.of(context).typography.caption1.copyWith(
                color: MacosColors.systemGrayColor,
              ),
            ),
            const SizedBox(width: MacosLayout.space8),
          ],
          SizedBox(
            width: SegmentedFieldMetrics.dateColumnWidth,
            child: MacosDateEntry(
              date: date,
              minimumDate: minimumDate,
              maximumDate: maximumDate,
              semanticLabel: label.isEmpty ? 'Date' : label,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_item_field_controllers.dart';
import 'package:timesheet/ui/widgets/weekday_label.dart';
import 'package:timesheet/utils/duration_utils.dart';

class TimetrackerItemRow extends StatefulWidget {
  const TimetrackerItemRow({
    super.key,
    required this.timeTrackerProvider,
    required this.userConfigProvider,
    required this.index,
    required this.item,
    required this.canReorder,
  });

  final TimetrackerProvider timeTrackerProvider;
  final SubjectsCategoriesProvider userConfigProvider;
  final int index;
  final TimetrackerItem item;
  final bool canReorder;

  @override
  State<TimetrackerItemRow> createState() => _TimetrackerItemRowState();
}

class _TimetrackerItemRowState extends State<TimetrackerItemRow> {
  static const double _btnW = 30.0;
  static const double _dayW = 40.0;
  static const double _timeW = 70.0;
  static const double _workedW = 55.0;
  static const double _spacingW = 8.0;

  final _fieldControllers = TimetrackerItemFieldControllers();

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat('EEE', locale).format(widget.item.from);
    final dividerColor =
        FluentTheme.of(context).resources.dividerStrokeColorDefault;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: _buildRow(context, dayLabel),
    );
  }

  Widget _buildRow(BuildContext context, String dayLabel) {
    return Row(
      spacing: _spacingW,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _btnW,
          child: widget.canReorder
              ? ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(FluentIcons.move),
                )
              : Icon(
                  FluentIcons.move,
                  color: FluentTheme.of(
                    context,
                  ).resources.textFillColorDisabled,
                ),
        ),
        SizedBox(
          width: _dayW,
          child: WeekdayLabel(
            date: widget.item.from,
            label: dayLabel,
            textStyle: const TextStyle(),
          ),
        ),
        SizedBox(
          width: _timeW,
          child: CalendarDatePicker(
            initialStart: widget.item.from,
            onSelectionChanged: (calendarSelection) {
              final date = calendarSelection.startDate!;
              final newFrom = DateTime(
                date.year,
                date.month,
                date.day,
                widget.item.from.hour,
                widget.item.from.minute,
                widget.item.from.second,
              );
              final newTo = DateTime(
                date.year,
                date.month,
                date.day,
                widget.item.to.hour,
                widget.item.to.minute,
                widget.item.to.second,
              );
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(from: newFrom, to: newTo),
              );
            },
            minDate: DateTime.now().subtract(const Duration(days: 365)),
            maxDate: DateTime.now().add(const Duration(days: 365)),
            firstDayOfWeek: 1,
            dateFormatter: DateFormat('d.M.'),
          ),
        ),
        SizedBox(
          width: _timeW,
          child: TimePicker(
            selected: widget.item.from,
            minuteIncrement: 15,
            hourFormat: material.HourFormat.HH,
            onChanged: (time) {
              final newFrom = DateTime(
                widget.item.from.year,
                widget.item.from.month,
                widget.item.from.day,
                time.hour,
                time.minute,
                widget.item.from.second,
              );
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(from: newFrom),
              );
            },
          ),
        ),
        SizedBox(
          width: _timeW,
          child: TimePicker(
            selected: widget.item.to,
            minuteIncrement: 15,
            hourFormat: material.HourFormat.HH,
            onChanged: (time) {
              final newTo = DateTime(
                widget.item.to.year,
                widget.item.to.month,
                widget.item.to.day,
                time.hour,
                time.minute,
                widget.item.to.second,
              );
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(to: newTo),
              );
            },
          ),
        ),
        SizedBox(
          width: _workedW,
          child: Text(
            toHmString(widget.item.to.difference(widget.item.from)),
          ),
        ),
        Expanded(
          child: AutoSuggestBox<String>(
            controller: _fieldControllers.subject,
            onChanged: (value, _) {
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(subject: value),
              );
            },
            onSelected: (selected) {
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(subject: selected.value),
              );
            },
            clearButtonEnabled: false,
            placeholder: 'Subject',
            items: widget.userConfigProvider.subjects
                .map(
                  (s) => AutoSuggestBoxItem<String>(value: s.uri, label: s.uri),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: TextBox(
            controller: _fieldControllers.description,
            placeholder: 'Description',
            maxLines: null,
            onChanged: (text) {
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(description: text),
              );
            },
          ),
        ),
        SizedBox(
          width: _btnW,
          child: widget.timeTrackerProvider.isSavingItem(widget.item)
              ? Center(
                  child: SizedBox.square(
                    dimension: 16,
                    child: const ProgressRing(strokeWidth: 3),
                  ),
                )
              : switch (widget.item.status) {
                  TimetrackerItemStatus.staged => Icon(
                    FluentIcons.cloud,
                    color: material.Colors.grey,
                  ),
                  TimetrackerItemStatus.saved => Icon(
                    FluentIcons.cloud,
                    color: material.Colors.green,
                  ),
                  TimetrackerItemStatus.error => Icon(
                    FluentIcons.cloud,
                    color: material.Colors.red,
                  ),
                },
        ),
        SizedBox(
          width: _btnW,
          child: IconButton(
            icon: const Icon(FluentIcons.delete, size: 16),
            onPressed: () {
              widget.timeTrackerProvider.deleteItem(widget.item);
            },
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _fieldControllers.initFrom(widget.item);
  }

  @override
  void didUpdateWidget(TimetrackerItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fieldControllers.syncFrom(widget.item, oldWidget.item);
  }

  @override
  void dispose() {
    _fieldControllers.dispose();
    super.dispose();
  }
}

import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_item_field_controllers.dart';
import 'package:timesheet/ui/widgets/overflow_clip_box.dart';
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
  static const double _btnPrefW = 30.0;
  static const double _dayPrefW = 40.0;
  static const double _timePickerPrefW = 80.0;
  static const double _workedPrefW = 55.0;
  static const double _spacingPrefW = 8.0;
  static const double _flexMinW = 120.0;

  static const double _fixedTotalW =
      _btnPrefW * 3 + // drag, status, delete
      _dayPrefW +
      _timePickerPrefW * 3 + // date, from, to
      _workedPrefW +
      _spacingPrefW * 9;

  static const double _minRowW = _fixedTotalW + _flexMinW * 2;

  final _fieldControllers = TimetrackerItemFieldControllers();

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.all(10);
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat('EEE', locale).format(widget.item.from);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: OverflowClipBox(
        axis: Axis.horizontal,
        minExtent: _minRowW,
        childBuilder: (rowW) => _buildRow(context, dayLabel, rowW),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String dayLabel, double rowW) {
    final flexW = (rowW - _fixedTotalW) / 2;
    final fieldStyle = MacosTheme.of(context).typography.title3;

    return SizedBox(
      width: rowW,
      child: Row(
        spacing: _spacingPrefW,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _btnPrefW,
            child: widget.canReorder
                ? ReorderableDragStartListener(
                    index: widget.index,
                    child: MacosIcon(
                      CupertinoIcons.bars,
                      color: MacosTheme.of(context).primaryColor,
                    ),
                  )
                : MacosIcon(CupertinoIcons.bars, color: Colors.grey),
          ),
          SizedBox(
            width: _dayPrefW,
            child: WeekdayLabel(
              date: widget.item.from,
              label: dayLabel,
              textStyle: fieldStyle,
            ),
          ),
          SizedBox(
            width: _timePickerPrefW,
            child: CupertinoCalendarPickerButton(
              firstDayOfWeekIndex: 1,
              initialDateTime: widget.item.from,
              minimumDateTime: DateTime.now().subtract(const Duration(days: 365)),
              maximumDateTime: DateTime.now().add(const Duration(days: 365)),
              formatter: (date) => DateFormat('d.M.').format(date),
              onCompleted: (value) async {
                if (value == null) {
                  return;
                }
                final newFrom = value.copyWith(
                  hour: widget.item.from.hour,
                  minute: widget.item.from.minute,
                  second: widget.item.from.second,
                );
                final newTo = value.copyWith(
                  hour: widget.item.to.hour,
                  minute: widget.item.to.minute,
                  second: widget.item.to.second,
                );
                widget.timeTrackerProvider.updateItem(
                  widget.item.copyWith(from: newFrom, to: newTo),
                );
              },
              buttonDecoration: PickerButtonDecoration(
                textStyle: fieldStyle,
              ),
            ),
          ),
          SizedBox(
            width: _timePickerPrefW,
            child: CupertinoTimePickerButton(
              initialTime: TimeOfDay.fromDateTime(widget.item.from),
              minuteInterval: 15,
              onCompleted: (value) {
                if (value == null) {
                  return;
                }
                final newFrom = widget.item.from.copyWith(
                  hour: value.hour,
                  minute: value.minute,
                );
                widget.timeTrackerProvider.updateItem(
                  widget.item.copyWith(from: newFrom),
                );
              },
              buttonDecoration: PickerButtonDecoration(
                textStyle: fieldStyle,
              ),
            ),
          ),
          SizedBox(
            width: _timePickerPrefW,
            child: CupertinoTimePickerButton(
              initialTime: TimeOfDay.fromDateTime(widget.item.to),
              minuteInterval: 15,
              onCompleted: (value) {
                if (value == null) {
                  return;
                }
                final newTo = widget.item.to.copyWith(
                  hour: value.hour,
                  minute: value.minute,
                );
                widget.timeTrackerProvider.updateItem(
                  widget.item.copyWith(to: newTo),
                );
              },
              buttonDecoration: PickerButtonDecoration(
                textStyle: fieldStyle,
              ),
            ),
          ),
          SizedBox(
            width: _workedPrefW,
            child: Text(
              toHmString(widget.item.to.difference(widget.item.from)),
            ),
          ),
          SizedBox(
            width: flexW,
            child: MacosSearchField(
              results: widget.userConfigProvider.subjects
                  .map(
                    (e) => SearchResultItem(
                      e.uri,
                      child: Text(e.uri, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              maxLines: 1,
              maxResultsToShow: 10,
              controller: _fieldControllers.subject,
              placeholder: 'Subject',
              onChanged: (value) {
                widget.timeTrackerProvider.updateItem(
                  widget.item.copyWith(subject: value),
                );
              },
              onResultSelected: (value) {
                widget.timeTrackerProvider.updateItem(
                  widget.item.copyWith(subject: value.searchKey),
                );
              },
            ),
          ),
          SizedBox(
            width: flexW,
            child: MacosTextField(
              controller: _fieldControllers.description,
              placeholder: 'Description',
              maxLines: null,
              minLines: null,
              expands: true,
              style: fieldStyle,
              onChanged: (value) {
                widget.timeTrackerProvider.updateItem(
                  widget.item.copyWith(description: value),
                );
              },
            ),
          ),
          SizedBox(
            width: _btnPrefW,
            child: widget.timeTrackerProvider.isSavingItem(widget.item)
                ? const ProgressCircle()
                : switch (widget.item.status) {
                    TimetrackerItemStatus.staged => MacosIcon(
                      CupertinoIcons.cloud_fill,
                      color: Colors.grey,
                    ),
                    TimetrackerItemStatus.saved => MacosIcon(
                      CupertinoIcons.cloud_fill,
                      color: Colors.green,
                    ),
                    TimetrackerItemStatus.error => MacosIcon(
                      CupertinoIcons.cloud_fill,
                      color: Colors.red,
                    ),
                  },
          ),
          SizedBox(
            width: _btnPrefW,
            child: MacosIconButton(
              icon: MacosIcon(
                CupertinoIcons.delete,
                color: MacosTheme.of(context).primaryColor,
              ),
              onPressed: () {
                widget.timeTrackerProvider.deleteItem(widget.item);
              },
            ),
          ),
        ],
      ),
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

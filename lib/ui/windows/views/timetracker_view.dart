import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/windows/dialog.dart';
import 'package:timesheet/ui/windows/infobar.dart';
import 'package:timesheet/utils/duration_utils.dart';

class TimetrackerView extends StatelessWidget {
  const TimetrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimetrackerProvider, SubjectsCategoriesProvider>(
      builder: (context, timeTrackerProvider, subjectsCategoriesProvider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (timeTrackerProvider.successMsg != null) {
            InfoBarManager.success(timeTrackerProvider.successMsg!);
            timeTrackerProvider.clearSuccessMsg();
          }
          if (timeTrackerProvider.errorMsg != null) {
            InfoBarManager.error(timeTrackerProvider.errorMsg!);
            timeTrackerProvider.clearErrorMsg();
          }
        });

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Timetracker'),
            commandBar: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Add timesheet item',
                  child: IconButton(
                    icon: const Icon(FluentIcons.add),
                    onPressed: () => timeTrackerProvider.addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Send timesheet items to WTM',
                  child: IconButton(
                    icon: const Icon(FluentIcons.cloud_upload),
                    onPressed: () async {
                      await timeTrackerProvider.saveToWTM();
                      await subjectsCategoriesProvider
                          .loadSubjectsAndCategories();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Clear all timesheet items',
                  child: IconButton(
                    icon: const Icon(FluentIcons.delete),
                    onPressed: () {
                      DialogManager.warningConfirmation(
                        title: 'Warning',
                        message: 'Are you sure you want to delete all items?',
                        confirmText: 'Yes',
                        cancelText: 'No',
                        onResult: (confirmed) {
                          if (confirmed) {
                            timeTrackerProvider.deleteAll();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            children: [
              Expanded(
                child: material.ReorderableListView(
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) async {
                    await timeTrackerProvider.reorderItems(oldIndex, newIndex);
                  },
                  children: [
                    for (int i = 0; i < timeTrackerProvider.items.length; i++)
                      _TimetrackerItemRow(
                        key: ValueKey(timeTrackerProvider.items[i].itemIndex),
                        timeTrackerProvider: timeTrackerProvider,
                        userConfigProvider: subjectsCategoriesProvider,
                        index: i,
                        item: timeTrackerProvider.items[i],
                      ),
                  ],
                ),
              ),
              _buildFooter(context, timeTrackerProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, TimetrackerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Items: ${provider.itemCount}'),
          const SizedBox(width: 8),
          Text('Worked: ${toHmString(provider.totalDuration)}'),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TimetrackerItemRow extends StatefulWidget {
  final TimetrackerProvider timeTrackerProvider;
  final SubjectsCategoriesProvider userConfigProvider;
  final int index;
  final TimetrackerItem item;

  const _TimetrackerItemRow({
    required super.key,
    required this.timeTrackerProvider,
    required this.userConfigProvider,
    required this.index,
    required this.item,
  });

  @override
  State<_TimetrackerItemRow> createState() => _TimetrackerItemRowState();
}

class _TimetrackerItemRowState extends State<_TimetrackerItemRow> {
  static const double _btnW = 30.0;
  static const double _dayW = 40.0;
  static const double _dateW = 100.0;
  static const double _timeW = 70.0;
  static const double _workedW = 55.0;
  static const double _spacingW = 8.0;

  late TextEditingController _subjectController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.item.subject);
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
  }

  @override
  void didUpdateWidget(_TimetrackerItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controllers if the item changed from external source
    // (not from our own typing)
    if (widget.item.id != oldWidget.item.id ||
        widget.item.itemIndex != oldWidget.item.itemIndex) {
      // Item was replaced (e.g., reordered, deleted and recreated)
      _subjectController.text = widget.item.subject;
      _descriptionController.text = widget.item.description;
    } else {
      // Check if subject changed externally (not from our controller)
      if (widget.item.subject != _subjectController.text) {
        _subjectController.text = widget.item.subject;
      }
      // Check if description changed externally (not from our controller)
      if (widget.item.description != _descriptionController.text) {
        _descriptionController.text = widget.item.description;
      }
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat('EEE', locale).format(widget.item.from);

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --------------------------------------------------
          // Drag handle
          // --------------------------------------------------
          SizedBox(
            width: _btnW,
            child: ReorderableDragStartListener(
              index: widget.index,
              child: Icon(FluentIcons.move),
            ),
          ),
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // Day
          // --------------------------------------------------
          SizedBox(width: _dayW, child: Text(dayLabel)),
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // Date
          // --------------------------------------------------
          SizedBox(
            width: _dateW + 10,
            child: CalendarDatePicker(
              initialStart: widget.item.from,
              onSelectionChanged: (calendarSelection) {
                // if (calendarSelection.startDate == null) {
                //   return;
                // }
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
              dateFormatter: DateFormat('d.M.yyyy'),
            ),
          ),
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // From
          // --------------------------------------------------
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
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // To
          // --------------------------------------------------
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
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // Worked
          // --------------------------------------------------
          SizedBox(
            width: _workedW,
            child: Text(
              toHmString(widget.item.to.difference(widget.item.from)),
            ),
          ),
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // Subject
          // --------------------------------------------------
          Expanded(
            child: AutoSuggestBox<String>(
              controller: _subjectController,
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
                    (s) =>
                        AutoSuggestBoxItem<String>(value: s.uri, label: s.uri),
                  )
                  .toList(),
            ),
          ),
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // Description
          // --------------------------------------------------
          Expanded(
            child: TextBox(
              controller: _descriptionController,
              placeholder: 'Description',
              maxLines: null,
              onChanged: (text) {
                widget.timeTrackerProvider.updateItem(
                  widget.item.copyWith(description: text),
                );
              },
            ),
          ),
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // Status
          // --------------------------------------------------
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
          SizedBox(width: _spacingW),
          // --------------------------------------------------
          // Delete button
          // --------------------------------------------------
          SizedBox(
            width: _btnW,
            child: IconButton(
              icon: const Icon(FluentIcons.delete, size: 16),
              onPressed: () =>
                  widget.timeTrackerProvider.deleteItem(widget.item),
            ),
          ),
        ],
      ),
    );
  }
}

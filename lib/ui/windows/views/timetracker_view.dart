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
      builder: (context, timeTrackerProvider, userConfigProvider, _) {
        final successMsg = timeTrackerProvider.successMsg;
        final errorMsg = timeTrackerProvider.errorMsg;
        if (successMsg != null || errorMsg != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (successMsg != null) {
              InfoBarManager.success(successMsg);
              timeTrackerProvider.clearSuccessMsg();
            }
            if (errorMsg != null) {
              InfoBarManager.error(errorMsg);
              timeTrackerProvider.clearErrorMsg();
            }
          });
        }

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
                  message: 'Save timesheet items to WTM',
                  child: FilledButton(
                    onPressed: () async {
                      await timeTrackerProvider.saveToWTM();
                      await userConfigProvider.loadSubjectsAndCategories();
                    },
                    child: const Text('Save to WTM'),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Clear all timesheet items',
                  child: Button(
                    onPressed: () {
                      DialogManager.warningConfirmation(
                        title: 'Warning',
                        message:
                            'Are you sure you want to delete all items?',
                        confirmText: 'Yes',
                        cancelText: 'No',
                        onResult: (confirmed) {
                          if (confirmed) {
                            timeTrackerProvider.deleteAll();
                          }
                        },
                      );
                    },
                    child: const Text('Clear timesheet'),
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
                        userConfigProvider: userConfigProvider,
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

  Widget _buildFooter(
    BuildContext context,
    TimetrackerProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFE1E1E1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Items: ${provider.itemCount}',
            style: FluentTheme.of(context).typography.body,
          ),
          const SizedBox(width: 8),
          SelectableText(
            'Worked: ${toHmString(provider.totalDuration)}',
            style: FluentTheme.of(context).typography.body,
          ),
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
    _descriptionController = TextEditingController(text: widget.item.description);
  }

  @override
  void didUpdateWidget(_TimetrackerItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.id != oldWidget.item.id ||
        widget.item.itemIndex != oldWidget.item.itemIndex) {
      _subjectController.text = widget.item.subject;
      _descriptionController.text = widget.item.description;
    } else {
      if (widget.item.subject != _subjectController.text) {
        _subjectController.text = widget.item.subject;
      }
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
    final bodyStyle = FluentTheme.of(context).typography.body;

    return Container(
      key: widget.key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE1E1E1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _btnW,
            child: material.ReorderableDragStartListener(
              index: widget.index,
              child: const Icon(FluentIcons.move, size: 16),
            ),
          ),
          SizedBox(width: _spacingW),
          SizedBox(
            width: _dayW,
            child: Text(dayLabel, style: bodyStyle),
          ),
          SizedBox(width: _spacingW),
          SizedBox(
            width: _dateW,
            child: DatePicker(
              selected: widget.item.from,
              startDate: DateTime.now().subtract(const Duration(days: 365)),
              endDate: DateTime.now().add(const Duration(days: 365)),
              onChanged: (date) {
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
            ),
          ),
          SizedBox(width: _spacingW),
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
          SizedBox(
            width: _workedW,
            child: Text(
              toHmString(widget.item.to.difference(widget.item.from)),
              style: bodyStyle,
            ),
          ),
          SizedBox(width: _spacingW),
          Expanded(
            child: AutoSuggestBox<String>(
              controller: _subjectController,
              placeholder: 'Subject',
              items: widget.userConfigProvider.subjects
                  .map(
                    (s) => AutoSuggestBoxItem<String>(
                      value: s.uri,
                      label: s.uri,
                    ),
                  )
                  .toList(),
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
            ),
          ),
          SizedBox(width: _spacingW),
          Expanded(
            child: TextBox(
              controller: _descriptionController,
              placeholder: 'Description',
              maxLines: 1,
              onChanged: (text) {
                widget.timeTrackerProvider.updateItem(
                  widget.item.copyWith(description: text),
                );
              },
            ),
          ),
          SizedBox(width: _spacingW),
          SizedBox(
            width: _btnW,
            child: widget.timeTrackerProvider.isSavingItem(widget.item)
                ? const ProgressRing()
                : _statusIcon(widget.item.status),
          ),
          SizedBox(width: _spacingW),
          SizedBox(
            width: _btnW,
            child: IconButton(
              icon: const Icon(FluentIcons.delete, size: 16),
              onPressed: () => widget.timeTrackerProvider.deleteItem(widget.item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(TimetrackerItemStatus status) {
    switch (status) {
      case TimetrackerItemStatus.staged:
        return Icon(FluentIcons.cloud, size: 16, color: material.Colors.grey);
      case TimetrackerItemStatus.saved:
        return Icon(FluentIcons.cloud, size: 16, color: material.Colors.green);
      case TimetrackerItemStatus.error:
        return Icon(FluentIcons.cloud, size: 16, color: material.Colors.red);
    }
  }
}

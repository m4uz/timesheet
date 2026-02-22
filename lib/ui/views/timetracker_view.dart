import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/ui/dialog.dart';
import 'package:timesheet/ui/snackbar.dart';
import 'package:timesheet/utils/duration_utils.dart';

class TimetrackerView extends StatefulWidget {
  const TimetrackerView({super.key});

  @override
  State<TimetrackerView> createState() => _TimetrackerViewState();
}

class _TimetrackerViewState extends State<TimetrackerView> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<TimetrackerProvider, SubjectsCategoriesProvider>(
      builder: (context, timeTrackerProvider, userConfigProvider, child) {
        if (timeTrackerProvider.successMsg != null) {
          SnackBarManager.success(timeTrackerProvider.successMsg!);
          timeTrackerProvider.clearSuccessMsg();
        }
        if (timeTrackerProvider.errorMsg != null) {
          SnackBarManager.error(timeTrackerProvider.errorMsg!);
          timeTrackerProvider.clearErrorMsg();
        }
        return MacosScaffold(
          toolBar: ToolBar(
            title: Text(
              'Timetracker',
              style: MacosTheme.of(context).typography.title2,
            ),
            titleWidth: 100.0,
            leading: MacosTooltip(
              message: 'Toggle Sidebar',
              useMousePosition: false,
              child: MacosIconButton(
                icon: MacosIcon(
                  CupertinoIcons.sidebar_left,
                  color: MacosTheme.brightnessOf(context).resolve(
                    const Color.fromRGBO(0, 0, 0, 0.5),
                    const Color.fromRGBO(255, 255, 255, 0.5),
                  ),
                  size: 20.0,
                ),
                boxConstraints: const BoxConstraints(
                  minHeight: 20,
                  minWidth: 20,
                  maxWidth: 48,
                  maxHeight: 38,
                ),
                onPressed: () => MacosWindowScope.of(context).toggleSidebar(),
              ),
            ),
            actions: [
              ToolBarIconButton(
                label: 'Add item',
                showLabel: false,
                icon: const MacosIcon(CupertinoIcons.plus_circle),
                tooltipMessage: 'Add timesheet item',
                onPressed: () async {
                  timeTrackerProvider.addItem();
                },
              ),
              ToolBarIconButton(
                label: 'Save to WTM',
                showLabel: false,
                icon: const MacosIcon(CupertinoIcons.cloud_upload),
                tooltipMessage: 'Save timesheet items to WTM',
                onPressed: () async {
                  await timeTrackerProvider.saveToWTM();
                  await userConfigProvider.loadSubjectsAndCategories();
                },
              ),
              ToolBarIconButton(
                label: 'Clear timesheet',
                showLabel: false,
                icon: const MacosIcon(CupertinoIcons.trash),
                tooltipMessage: 'Clear all timesheet items',
                onPressed: () async {
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
            ],
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Expanded(
                      child: ReorderableListView(
                        buildDefaultDragHandles: false,
                        children: [
                          for (
                            int index = 0;
                            index < timeTrackerProvider.items.length;
                            index++
                          )
                            _TimetrackerItem(
                              key: ValueKey(
                                timeTrackerProvider.items[index].itemIndex,
                              ),
                              timeTrackerProvider: timeTrackerProvider,
                              userConfigProvider: userConfigProvider,
                              index: index,
                              item: timeTrackerProvider.items[index],
                            ),
                        ],
                        onReorder: (oldIndex, newIndex) async {
                          await timeTrackerProvider.reorderItems(
                            oldIndex,
                            newIndex,
                          );
                        },
                      ),
                    ),
                    _buildFooter(context, timeTrackerProvider),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, TimetrackerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Items: ${provider.itemCount}',
            style: MacosTheme.of(context).typography.body,
          ),
          SizedBox(width: 8),
          SelectableText(
            'Worked: ${toHmString(provider.totalDuration)}',
            style: MacosTheme.of(context).typography.body,
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TimetrackerItem extends StatefulWidget {
  final TimetrackerProvider timeTrackerProvider;
  final SubjectsCategoriesProvider userConfigProvider;
  final int index;
  final TimetrackerItem item;

  const _TimetrackerItem({
    required super.key,
    required this.timeTrackerProvider,
    required this.userConfigProvider,
    required this.index,
    required this.item,
  });

  @override
  State<_TimetrackerItem> createState() => _TimetrackerItemState();
}

class _TimetrackerItemState extends State<_TimetrackerItem> {
  static const double _btnPrefW = 30.0;
  static const double _dayPrefW = 40.0;
  static const double _datePickerPrefW = 120.0;
  static const double _timePickerPrefW = 80.0;
  static const double _workedPrefW = 55.0;
  static const double _spacingPrefW = 10.0;
  static const int _spacingCount = 9;

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
  void didUpdateWidget(_TimetrackerItem oldWidget) {
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

  ({
    double btnW,
    double dayW,
    double datePickerW,
    double timePickerW,
    double workedW,
    double spacingW,
  })
  _calculateLayoutDimensions(BoxConstraints constraints) {
    const fixedPrefTotal =
        _btnPrefW +
        _dayPrefW +
        _datePickerPrefW +
        _timePickerPrefW +
        _timePickerPrefW +
        _workedPrefW +
        _btnPrefW +
        _btnPrefW +
        _spacingPrefW * _spacingCount;

    final scale = ((constraints.maxWidth - 0.001) / fixedPrefTotal).clamp(
      0.0,
      1.0,
    );

    return (
      btnW: _btnPrefW * scale,
      dayW: _dayPrefW * scale,
      datePickerW: _datePickerPrefW * scale,
      timePickerW: _timePickerPrefW * scale,
      workedW: _workedPrefW * scale,
      spacingW: _spacingPrefW * scale,
    );
  }

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dimensions = _calculateLayoutDimensions(constraints);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --------------------------------------------------
              // Drag handle
              // --------------------------------------------------
              SizedBox(
                width: dimensions.btnW,
                child: ReorderableDragStartListener(
                  index: widget.index,
                  child: MacosIcon(
                    CupertinoIcons.bars,
                    color: MacosTheme.of(context).primaryColor,
                  ),
                ),
              ),
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // Day
              // --------------------------------------------------
              SizedBox(
                width: dimensions.dayW,
                child: Text(
                  dayLabel,
                  style: MacosTheme.of(context).typography.title3,
                ),
              ),
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // Date
              // --------------------------------------------------
              SizedBox(
                width: dimensions.datePickerW,
                child: CupertinoCalendarPickerButton(
                  firstDayOfWeekIndex: 1,
                  initialDateTime: widget.item.from,
                  minimumDateTime: DateTime.now().subtract(Duration(days: 365)),
                  maximumDateTime: DateTime.now().add(Duration(days: 365)),
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
                    textStyle: MacosTheme.of(context).typography.title3,
                  ),
                ),
              ),
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // From
              // --------------------------------------------------
              SizedBox(
                width: dimensions.timePickerW,
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
                    textStyle: MacosTheme.of(context).typography.title3,
                  ),
                ),
              ),
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // To
              // --------------------------------------------------
              SizedBox(
                width: dimensions.timePickerW,
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
                    textStyle: MacosTheme.of(context).typography.title3,
                  ),
                ),
              ),
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // Worked
              // --------------------------------------------------
              SizedBox(
                child: Text(
                  toHmString(widget.item.to.difference(widget.item.from)),
                ),
              ),
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // Subject
              // --------------------------------------------------
              Expanded(
                child: MacosSearchField(
                  results: widget.userConfigProvider.subjects
                      .map(
                        (e) => SearchResultItem(
                          e.uri,
                          child: Text(e.uri, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  maxResultsToShow: 10,
                  controller: _subjectController,
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
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // Description
              // --------------------------------------------------
              Expanded(
                child: MacosTextField(
                  controller: _descriptionController,
                  placeholder: 'Description',
                  maxLines: null,
                  minLines: null,
                  expands: true,
                  style: MacosTheme.of(context).typography.title3,
                  onChanged: (value) async {
                    widget.timeTrackerProvider.updateItem(
                      widget.item.copyWith(description: value),
                    );
                  },
                ),
              ),
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // Status
              // --------------------------------------------------
              SizedBox(
                width: dimensions.btnW,
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
              SizedBox(width: dimensions.spacingW),
              // --------------------------------------------------
              // Delete button
              // --------------------------------------------------
              SizedBox(
                width: dimensions.btnW,
                child: MacosIconButton(
                  icon: MacosIcon(
                    CupertinoIcons.delete,
                    color: MacosTheme.of(context).primaryColor,
                  ),
                  onPressed: () async {
                    widget.timeTrackerProvider.deleteItem(widget.item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

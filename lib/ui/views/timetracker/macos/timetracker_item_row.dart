import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/providers/subjects_and_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_item_field_controllers.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_tab_navigation.dart';
import 'package:timesheet/ui/widgets/macos_date_entry.dart';
import 'package:timesheet/ui/widgets/macos_time_entry.dart';
import 'package:timesheet/ui/widgets/overflow_clip_box.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';
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
    this.onTabFromDescription,
  });

  final TimetrackerProvider timeTrackerProvider;
  final SubjectsAndCategoriesProvider userConfigProvider;
  final int index;
  final TimetrackerItem item;
  final bool canReorder;

  /// Called when Tab is pressed in the description field (not Shift+Tab).
  final Future<void> Function()? onTabFromDescription;

  @override
  TimetrackerItemRowState createState() => TimetrackerItemRowState();
}

class TimetrackerItemRowState extends State<TimetrackerItemRow> {
  static const double _btnPrefW = 30.0;
  static const double _dayPrefW = 40.0;
  static const double _datePickerPrefW = SegmentedFieldMetrics.dateColumnWidth;
  static const double _timePickerPrefW = SegmentedFieldMetrics.timeColumnWidth;
  static const double _workedPrefW = 55.0;
  static const double _spacingPrefW = 8.0;
  static const double _flexMinW = 120.0;

  static const double _fixedTotalW =
      _btnPrefW * 3 + // drag, status, delete
      _dayPrefW +
      _datePickerPrefW +
      _timePickerPrefW * 2 + // from, to
      _workedPrefW +
      _spacingPrefW * 9;

  static const double _minRowW = _fixedTotalW + _flexMinW * 2;

  final _fieldControllers = TimetrackerItemFieldControllers();
  final _dateEntryKey = GlobalKey<MacosDateEntryState>();
  late final FocusNode _descriptionFocusNode;
  Timer? _subjectFetchDebounce;

  /// Focus the month segment (`MM`) — used when Tabbing from the previous
  /// row's description so the caret lands mid-date for quick edits.
  void focusDateMonth() {
    final state = _dateEntryKey.currentState;
    if (state == null) return;
    final ctx = _dateEntryKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 150),
        alignment: 0.2,
      );
    }
    state.focusMonthSegment();
  }

  KeyEventResult _onDescriptionKey(FocusNode node, KeyEvent event) {
    return onDescriptionTabKeyEvent(
      event,
      onTabFromDescription: widget.onTabFromDescription,
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
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
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
              width: _datePickerPrefW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: MacosDateEntry(
                  key: _dateEntryKey,
                  date: widget.item.from,
                  minimumDate: DateTime.now().subtract(
                    const Duration(days: 365),
                  ),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  style: fieldStyle,
                  semanticLabel: 'Date',
                  calendarSemanticLabel: 'Open calendar',
                  onChanged: (value) {
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
                ),
              ),
            ),
            SizedBox(
              width: _timePickerPrefW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: MacosTimeEntry(
                  time: TimeOfDay.fromDateTime(widget.item.from),
                  minuteInterval: 15,
                  style: fieldStyle,
                  semanticLabel: 'Start time',
                  pickerSemanticLabel: 'Open start time picker',
                  onChanged: (value) {
                    final newFrom = widget.item.from.copyWith(
                      hour: value.hour,
                      minute: value.minute,
                    );
                    widget.timeTrackerProvider.updateItem(
                      widget.item.copyWith(from: newFrom),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: _timePickerPrefW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                child: MacosTimeEntry(
                  time: TimeOfDay.fromDateTime(widget.item.to),
                  minuteInterval: 15,
                  style: fieldStyle,
                  semanticLabel: 'End time',
                  pickerSemanticLabel: 'Open end time picker',
                  onChanged: (value) {
                    final newTo = widget.item.to.copyWith(
                      hour: value.hour,
                      minute: value.minute,
                    );
                    widget.timeTrackerProvider.updateItem(
                      widget.item.copyWith(to: newTo),
                    );
                  },
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
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(4),
                child: MacosSearchField(
                  results: widget.userConfigProvider.subjects
                      .map(
                        (e) => SearchResultItem(
                          // Include name and URI so MacosSearchField matches either.
                          e.name.isNotEmpty ? '${e.name} ${e.uri}' : e.uri,
                          child: Text(
                            e.name.isNotEmpty ? e.name : e.uri,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  maxLines: 1,
                  maxResultsToShow: 10,
                  controller: _fieldControllers.subject,
                  placeholder: 'Subject',
                  onChanged: _onSubjectChanged,
                  onResultSelected: (value) {
                    Subject? subject;
                    for (final s in widget.userConfigProvider.subjects) {
                      if (value.searchKey.contains(s.uri)) {
                        subject = s;
                        break;
                      }
                    }
                    if (subject == null) {
                      return;
                    }
                    final subjectName = subject.name;
                    widget.timeTrackerProvider.updateItem(
                      widget.item.copyWith(
                        subject: subject.uri,
                        subjectName: subjectName,
                      ),
                    );
                    _fieldControllers.subject.text =
                        subjectName.isNotEmpty ? subjectName : subject.uri;
                  },
                ),
              ),
            ),
            SizedBox(
              width: flexW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(5),
                child: MacosTextField(
                  focusNode: _descriptionFocusNode,
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
              child: ExcludeFocus(
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
            ),
          ],
        ),
      ),
    );
  }

  void _onSubjectChanged(String value) {
    if (value.isEmpty &&
        (widget.item.subject.isNotEmpty || widget.item.subjectName.isNotEmpty)) {
      widget.timeTrackerProvider.updateItem(
        widget.item.copyWith(subject: '', subjectName: ''),
      );
    }

    _subjectFetchDebounce?.cancel();
    if (!widget.userConfigProvider.isFetchableSubjectUri(value)) {
      return;
    }
    final requested = value.trim();
    final item = widget.item;
    final timeTrackerProvider = widget.timeTrackerProvider;
    final userConfigProvider = widget.userConfigProvider;
    _subjectFetchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final subject = await userConfigProvider.ensureSubjectForInput(requested);
      if (subject == null) {
        return;
      }
      await timeTrackerProvider.updateItem(
        item.copyWith(subject: subject.uri, subjectName: subject.name),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _fieldControllers.initFrom(widget.item);
    _descriptionFocusNode = FocusNode(onKeyEvent: _onDescriptionKey);
  }

  @override
  void didUpdateWidget(TimetrackerItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fieldControllers.syncFrom(widget.item, oldWidget.item);
  }

  @override
  void dispose() {
    _subjectFetchDebounce?.cancel();
    _descriptionFocusNode.dispose();
    _fieldControllers.dispose();
    super.dispose();
  }
}

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/providers/subjects_and_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/platform/windows/windows_layout.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_item_field_controllers.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_tab_navigation.dart';
import 'package:timesheet/ui/widgets/overflow_clip_box.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';
import 'package:timesheet/ui/widgets/weekday_label.dart';
import 'package:timesheet/ui/widgets/windows_date_entry.dart';
import 'package:timesheet/ui/widgets/windows_time_entry.dart';
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
  static const double _btnW = WindowsLayout.rowActionWidth;
  static const double _dayW = WindowsLayout.dayColumnWidth;
  static const double _dateW = SegmentedFieldMetrics.dateColumnWidth;
  static const double _timeW = SegmentedFieldMetrics.timeColumnWidth;
  static const double _workedW = WindowsLayout.workedColumnWidth;
  static const double _spacingW = WindowsLayout.space8;
  static const double _flexMinW = WindowsLayout.flexFieldMinWidth;

  static const double _fixedTotalW =
      _btnW * 3 + // drag, status, delete
      _dayW +
      _dateW +
      _timeW * 2 + // from, to
      _workedW +
      _spacingW * 9;

  static const double _minRowW = _fixedTotalW + _flexMinW * 2;

  final _fieldControllers = TimetrackerItemFieldControllers();
  final _dateEntryKey = GlobalKey<WindowsDateEntryState>();
  final _subjectSuggestKey = GlobalKey<AutoSuggestBoxState<String>>();
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
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat('EEE', locale).format(widget.item.from);
    final dividerColor =
        FluentTheme.of(context).resources.dividerStrokeColorDefault;

    return Container(
      padding: WindowsLayout.rowCellPadding,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dividerColor,
            width: WindowsLayout.rowDividerWidth,
          ),
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
    final theme = FluentTheme.of(context);
    final fieldStyle = WindowsLayout.rowFieldStyle(theme);
    final flexW = (rowW - _fixedTotalW) / 2;

    return SizedBox(
      width: rowW,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          spacing: _spacingW,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _btnW,
              child: widget.canReorder
                  ? ReorderableDragStartListener(
                      index: widget.index,
                      child: Icon(
                        FluentIcons.move,
                        size: WindowsLayout.rowIconSize,
                        color: theme.accentColor,
                      ),
                    )
                  : Icon(
                      FluentIcons.move,
                      size: WindowsLayout.rowIconSize,
                      color: material.Colors.grey,
                    ),
            ),
            SizedBox(
              width: _dayW,
              child: WeekdayLabel(
                date: widget.item.from,
                label: dayLabel,
                textStyle: fieldStyle,
              ),
            ),
            SizedBox(
              width: _dateW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: WindowsDateEntry(
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
              width: _timeW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: WindowsTimeEntry(
                  time: material.TimeOfDay.fromDateTime(widget.item.from),
                  minuteInterval: 15,
                  style: fieldStyle,
                  semanticLabel: 'Start time',
                  pickerSemanticLabel: 'Open start time picker',
                  onChanged: (value) {
                    widget.timeTrackerProvider.updateItem(
                      widget.item.copyWith(
                        from: widget.item.from.copyWith(
                          hour: value.hour,
                          minute: value.minute,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: _timeW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                child: WindowsTimeEntry(
                  time: material.TimeOfDay.fromDateTime(widget.item.to),
                  minuteInterval: 15,
                  style: fieldStyle,
                  semanticLabel: 'End time',
                  pickerSemanticLabel: 'Open end time picker',
                  onChanged: (value) {
                    widget.timeTrackerProvider.updateItem(
                      widget.item.copyWith(
                        to: widget.item.to.copyWith(
                          hour: value.hour,
                          minute: value.minute,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: _workedW,
              child: Text(
                toHmString(widget.item.to.difference(widget.item.from)),
                style: fieldStyle,
              ),
            ),
            SizedBox(
              width: flexW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(4),
                child: AutoSuggestBox<String>(
                  key: _subjectSuggestKey,
                  controller: _fieldControllers.subject,
                  style: fieldStyle,
                  // Enter confirms a suggestion; move on instead of the Fluent
                  // default (done → unfocus), which left focus nowhere.
                  textInputAction: TextInputAction.next,
                  onChanged: (value, _) => _onSubjectChanged(value),
                  onSelected: _onSubjectSelected,
                  clearButtonEnabled: false,
                  placeholder: 'Subject',
                  sorter: (text, items) {
                    final query = text.trim().toLowerCase();
                    if (query.isEmpty) {
                      return items;
                    }
                    return items.where((item) {
                      final label = item.label.toLowerCase();
                      final uri = (item.value ?? '').toLowerCase();
                      return label.contains(query) || uri.contains(query);
                    }).toList();
                  },
                  items: widget.userConfigProvider.subjects
                      .map(
                        (s) => AutoSuggestBoxItem<String>(
                          value: s.uri,
                          label: s.name.isNotEmpty ? s.name : s.uri,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            SizedBox(
              width: flexW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(5),
                child: TextBox(
                  focusNode: _descriptionFocusNode,
                  controller: _fieldControllers.description,
                  style: fieldStyle,
                  placeholder: 'Description',
                  maxLines: null,
                  onChanged: (text) {
                    widget.timeTrackerProvider.updateItem(
                      widget.item.copyWith(description: text),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: _btnW,
              child: widget.timeTrackerProvider.isSavingItem(widget.item)
                  ? const Center(
                      child: SizedBox.square(
                        dimension: WindowsLayout.rowIconSize,
                        child: ProgressRing(strokeWidth: 3),
                      ),
                    )
                  : switch (widget.item.status) {
                      TimetrackerItemStatus.staged => Icon(
                        FluentIcons.cloud,
                        size: WindowsLayout.rowIconSize,
                        color: material.Colors.grey,
                      ),
                      TimetrackerItemStatus.saved => Icon(
                        FluentIcons.cloud,
                        size: WindowsLayout.rowIconSize,
                        color: material.Colors.green,
                      ),
                      TimetrackerItemStatus.error => Icon(
                        FluentIcons.cloud,
                        size: WindowsLayout.rowIconSize,
                        color: material.Colors.red,
                      ),
                    },
            ),
            SizedBox(
              width: _btnW,
              // HoverButton avoids Fluent BaseButton's AnimatedDefaultTextStyle,
              // which asserts under Material ReorderableListView drag proxies.
              // ExcludeFocus so Tab from description skips delete (macOS parity).
              child: ExcludeFocus(
                child: HoverButton(
                  onPressed: () =>
                      widget.timeTrackerProvider.deleteItem(widget.item),
                  builder: (context, states) {
                    final resources = theme.resources;
                    final color = states.isDisabled
                        ? resources.textFillColorDisabled
                        : theme.accentColor;
                    return Padding(
                      padding: const EdgeInsets.all(WindowsLayout.space6),
                      child: Icon(
                        FluentIcons.delete,
                        size: WindowsLayout.rowIconSize,
                        color: color,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubjectSelected(AutoSuggestBoxItem<String> selected) {
    final uri = selected.value;
    if (uri == null) {
      return;
    }
    final subject = widget.userConfigProvider.findByUri(uri);
    final subjectName = subject?.name ?? '';
    final display = subjectName.isNotEmpty ? subjectName : uri;
    widget.timeTrackerProvider.updateItem(
      widget.item.copyWith(subject: uri, subjectName: subjectName),
    );
    if (_fieldControllers.subject.text != display) {
      _fieldControllers.subject.text = display;
    }

    // Enter selection does not dismiss the overlay or keep focus; restore a
    // usable caret on description after Fluent finishes its submit path.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subjectSuggestKey.currentState?.dismissOverlay();
      _descriptionFocusNode.requestFocus();
    });
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

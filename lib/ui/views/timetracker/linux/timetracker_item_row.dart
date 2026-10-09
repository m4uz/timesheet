import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/providers/subjects_and_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_item_field_controllers.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_tab_navigation.dart';
import 'package:timesheet/ui/widgets/linux_date_entry.dart';
import 'package:timesheet/ui/widgets/linux_time_entry.dart';
import 'package:timesheet/ui/widgets/overflow_clip_box.dart';
import 'package:timesheet/ui/widgets/weekday_label.dart';
import 'package:timesheet/utils/duration_utils.dart';
import 'package:yaru/yaru.dart';

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
  static const double _btnW = LinuxLayout.rowActionWidth;
  static const double _dayW = LinuxLayout.dayColumnWidth;
  static const double _dateW = LinuxLayout.dateTimeColumnWidth;
  static const double _timeW = LinuxLayout.dateTimeColumnWidth;
  static const double _workedW = LinuxLayout.workedColumnWidth;
  static const double _spacingW = LinuxLayout.space8;
  static const double _flexMinW = LinuxLayout.flexFieldMinWidth;

  static const double _fixedTotalW =
      _btnW * 3 + // drag, status, delete
      _dayW +
      _dateW +
      _timeW * 2 + // from, to
      _workedW +
      _spacingW * 9;

  static const double _minRowW = _fixedTotalW + _flexMinW * 2;

  final _fieldControllers = TimetrackerItemFieldControllers();
  final _dateEntryKey = GlobalKey<LinuxDateEntryState>();
  late final FocusNode _subjectFocusNode;
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
    final dividerColor = LinuxLayout.dividerColor(Theme.of(context));

    return Container(
      padding: LinuxLayout.rowCellPadding,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dividerColor,
            width: LinuxLayout.rowDividerWidth,
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
    final theme = Theme.of(context);
    final fieldStyle = LinuxLayout.rowFieldStyle(theme);
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
                        YaruIcons.drag_handle,
                        size: LinuxLayout.rowIconSize,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      YaruIcons.drag_handle,
                      size: LinuxLayout.rowIconSize,
                      color: Colors.grey,
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
                child: LinuxDateEntry(
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
                child: LinuxTimeEntry(
                  time: TimeOfDay.fromDateTime(widget.item.from),
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
                child: LinuxTimeEntry(
                  time: TimeOfDay.fromDateTime(widget.item.to),
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
                child: _buildSubjectField(fieldStyle),
              ),
            ),
            SizedBox(
              width: flexW,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(5),
                child: TextField(
                  focusNode: _descriptionFocusNode,
                  controller: _fieldControllers.description,
                  style: fieldStyle,
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    isDense: true,
                  ),
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
                        dimension: LinuxLayout.rowIconSize,
                        child: YaruCircularProgressIndicator(strokeWidth: 3),
                      ),
                    )
                  : switch (widget.item.status) {
                      TimetrackerItemStatus.staged => Icon(
                        YaruIcons.cloud,
                        size: LinuxLayout.rowIconSize,
                        color: Colors.grey,
                      ),
                      TimetrackerItemStatus.saved => Icon(
                        YaruIcons.cloud,
                        size: LinuxLayout.rowIconSize,
                        color: Colors.green,
                      ),
                      TimetrackerItemStatus.error => Icon(
                        YaruIcons.cloud,
                        size: LinuxLayout.rowIconSize,
                        color: Colors.red,
                      ),
                    },
            ),
            SizedBox(
              width: _btnW,
              child: ExcludeFocus(
                child: IconButton(
                  tooltip: 'Delete item',
                  iconSize: LinuxLayout.rowIconSize,
                  padding: const EdgeInsets.all(LinuxLayout.space6),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    YaruIcons.trash,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () =>
                      widget.timeTrackerProvider.deleteItem(widget.item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectField(TextStyle fieldStyle) {
    return RawAutocomplete<String>(
      textEditingController: _fieldControllers.subject,
      focusNode: _subjectFocusNode,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        final subjects = widget.userConfigProvider.subjects;
        Iterable<String> labels() => subjects.map(
          (s) => s.name.isNotEmpty ? s.name : s.uri,
        );
        if (query.isEmpty) {
          return labels();
        }
        return subjects
            .where((s) {
              final label = s.name.toLowerCase();
              final uri = s.uri.toLowerCase();
              return label.contains(query) || uri.contains(query);
            })
            .map((s) => s.name.isNotEmpty ? s.name : s.uri);
      },
      onSelected: _onSubjectSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: fieldStyle,
          decoration: const InputDecoration(
            hintText: 'Subject',
            isDense: true,
          ),
          textInputAction: TextInputAction.next,
          onChanged: _onSubjectChanged,
          onSubmitted: (_) {
            onFieldSubmitted();
            _descriptionFocusNode.requestFocus();
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final theme = Theme.of(context);
        final menuColor = theme.colorScheme.surfaceContainerHigh;
        return Align(
          alignment: Alignment.topLeft,
          child: ExcludeFocus(
            child: Material(
              elevation: 6,
              type: MaterialType.card,
              color: menuColor,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(kYaruContainerRadius),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240, minWidth: 180),
                child: ColoredBox(
                  color: menuColor,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return Builder(
                        builder: (context) {
                          final highlighted =
                              AutocompleteHighlightedOption.of(context) ==
                              index;
                          if (highlighted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                Scrollable.ensureVisible(
                                  context,
                                  alignment: 0.5,
                                );
                              }
                            });
                          }
                          return MenuItemButton(
                            requestFocusOnHover: false,
                            onPressed: () => onSelected(option),
                            style: MenuItemButton.styleFrom(
                              backgroundColor: highlighted
                                  ? theme.focusColor
                                  : menuColor,
                            ),
                            child: Text(option, style: fieldStyle),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSubjectSelected(String display) {
    Subject? subject;
    for (final s in widget.userConfigProvider.subjects) {
      final label = s.name.isNotEmpty ? s.name : s.uri;
      if (label == display) {
        subject = s;
        break;
      }
    }
    final uri = subject?.uri ?? display;
    final subjectName = subject?.name ?? '';
    final resolvedDisplay = subjectName.isNotEmpty ? subjectName : uri;
    widget.timeTrackerProvider.updateItem(
      widget.item.copyWith(subject: uri, subjectName: subjectName),
    );
    if (_fieldControllers.subject.text != resolvedDisplay) {
      _fieldControllers.subject.text = resolvedDisplay;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    _subjectFocusNode = FocusNode();
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
    _subjectFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _fieldControllers.dispose();
    super.dispose();
  }
}

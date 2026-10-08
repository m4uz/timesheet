import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/providers/subjects_and_categories_provider.dart';
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
  final SubjectsAndCategoriesProvider userConfigProvider;
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
  Timer? _subjectFetchDebounce;

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
          child: _DateFlyoutButton(
            date: widget.item.from,
            onDateSelected: _onDateSelected,
          ),
        ),
        SizedBox(
          width: _timeW,
          child: TimePicker(
            selected: widget.item.from,
            minuteIncrement: 15,
            hourFormat: material.HourFormat.HH,
            onChanged: (time) {
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(
                  from: widget.item.from.copyWith(
                    hour: time.hour,
                    minute: time.minute,
                  ),
                ),
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
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(
                  to: widget.item.to.copyWith(
                    hour: time.hour,
                    minute: time.minute,
                  ),
                ),
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
            onChanged: (value, _) => _onSubjectChanged(value),
            onSelected: (selected) {
              final uri = selected.value;
              if (uri == null) {
                return;
              }
              final subject = widget.userConfigProvider.findByUri(uri);
              final subjectName = subject?.name ?? '';
              widget.timeTrackerProvider.updateItem(
                widget.item.copyWith(
                  subject: uri,
                  subjectName: subjectName,
                ),
              );
              _fieldControllers.subject.text =
                  subjectName.isNotEmpty ? subjectName : uri;
            },
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
              ? const Center(
                  child: SizedBox.square(
                    dimension: 16,
                    child: ProgressRing(strokeWidth: 3),
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
          // HoverButton avoids Fluent BaseButton's AnimatedDefaultTextStyle,
          // which asserts under Material ReorderableListView drag proxies.
          child: HoverButton(
            onPressed: () =>
                widget.timeTrackerProvider.deleteItem(widget.item),
            builder: (context, states) {
              final resources = FluentTheme.of(context).resources;
              final color = states.isDisabled
                  ? resources.textFillColorDisabled
                  : states.isHovered || states.isPressed
                  ? FluentTheme.of(context).accentColor
                  : resources.textFillColorPrimary;
              return Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(FluentIcons.delete, size: 16, color: color),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onDateSelected(DateTime date) {
    widget.timeTrackerProvider.updateItem(
      widget.item.copyWith(
        from: widget.item.from.copyWith(
          year: date.year,
          month: date.month,
          day: date.day,
        ),
        to: widget.item.to.copyWith(
          year: date.year,
          month: date.month,
          day: date.day,
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
  }

  @override
  void didUpdateWidget(TimetrackerItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fieldControllers.syncFrom(widget.item, oldWidget.item);
  }

  @override
  void dispose() {
    _subjectFetchDebounce?.cancel();
    _fieldControllers.dispose();
    super.dispose();
  }
}

/// Date trigger for reorderable rows. Uses [HoverButton] instead of
/// [CalendarDatePicker] (Fluent [Button]/[BaseButton]) to avoid text-style
/// lerp asserts while dragging.
class _DateFlyoutButton extends StatefulWidget {
  const _DateFlyoutButton({
    required this.date,
    required this.onDateSelected,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_DateFlyoutButton> createState() => _DateFlyoutButtonState();
}

class _DateFlyoutButtonState extends State<_DateFlyoutButton> {
  final _flyoutController = FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  void _showFlyout() {
    _flyoutController.showFlyout<void>(
      barrierColor: Colors.transparent,
      additionalOffset: 8,
      builder: (context) {
        final theme = FluentTheme.of(context);
        return Mica(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 350, maxWidth: 320),
            decoration: BoxDecoration(
              color: theme.resources.controlFillColorDefault,
              borderRadius: BorderRadius.circular(6),
            ),
            child: CalendarView(
              initialStart: widget.date,
              minDate: DateTime.now().subtract(const Duration(days: 365)),
              maxDate: DateTime.now().add(const Duration(days: 365)),
              firstDayOfWeek: 1,
              onSelectionChanged: (selection) {
                final date = selection.startDate;
                if (date == null) {
                  return;
                }
                widget.onDateSelected(date);
                _flyoutController.close();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      controller: _flyoutController,
      child: HoverButton(
        onPressed: _showFlyout,
        builder: (context, states) {
          final resources = FluentTheme.of(context).resources;
          final color = states.isDisabled
              ? resources.textFillColorDisabled
              : resources.textFillColorSecondary;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(
                  DateFormat('d.M.').format(widget.date),
                  style: TextStyle(color: color),
                ),
                Icon(FluentIcons.calendar, size: 12, color: color),
              ],
            ),
          );
        },
      ),
    );
  }
}

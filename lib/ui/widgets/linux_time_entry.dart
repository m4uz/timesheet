import 'package:flutter/material.dart';
import 'package:timesheet/ui/widgets/segmented_entry/linux_segmented_field_chrome.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_entry.dart';
import 'package:timesheet/ui/widgets/segmented_entry/time_entry_controller.dart';
import 'package:timesheet/utils/time_of_day_utils.dart';
import 'package:yaru/yaru.dart';

/// A compact Linux-styled HH:mm segmented time entry with a Yaru time dialog.
class LinuxTimeEntry extends StatefulWidget {
  const LinuxTimeEntry({
    super.key,
    required this.time,
    this.minuteInterval = 1,
    this.onChanged,
    this.style,
    this.enabled = true,
    this.semanticLabel = 'Time',
    this.pickerSemanticLabel = 'Open time picker',
  }) : assert(minuteInterval > 0 && minuteInterval <= 60);

  final TimeOfDay time;
  final int minuteInterval;
  final ValueChanged<TimeOfDay>? onChanged;
  final TextStyle? style;
  final bool enabled;

  /// Screen-reader label for the segmented time field.
  final String semanticLabel;

  /// Screen-reader label for the time-picker overlay button.
  final String pickerSemanticLabel;

  @override
  State<LinuxTimeEntry> createState() => _LinuxTimeEntryState();
}

class _LinuxTimeEntryState extends State<LinuxTimeEntry> {
  late final TimeEntryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimeEntryController(
      initialTime: widget.time,
      minuteInterval: widget.minuteInterval,
    );
  }

  @override
  void didUpdateWidget(covariant LinuxTimeEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minuteInterval != widget.minuteInterval) {
      _controller.setMinuteInterval(widget.minuteInterval);
    }
    if (oldWidget.time != widget.time) {
      _controller.syncFromTime(widget.time);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openTimePicker() async {
    final initial = snapTimeToMinuteInterval(
      widget.time,
      widget.minuteInterval,
    );
    var selectedHour = initial.hour;
    var selectedMinute = initial.minute;
    final minutes = [
      for (var m = 0; m < 60; m += widget.minuteInterval) m,
    ];

    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              titlePadding: EdgeInsets.zero,
              title: const YaruDialogTitleBar(title: Text('Select time')),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 96,
                    child: DropdownMenu<int>(
                      initialSelection: selectedHour,
                      label: const Text('Hour'),
                      dropdownMenuEntries: [
                        for (var h = 0; h < 24; h++)
                          DropdownMenuEntry(
                            value: h,
                            label: h.toString().padLeft(2, '0'),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedHour = value);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':'),
                  ),
                  SizedBox(
                    width: 96,
                    child: DropdownMenu<int>(
                      initialSelection: selectedMinute,
                      label: const Text('Minute'),
                      dropdownMenuEntries: [
                        for (final m in minutes)
                          DropdownMenuEntry(
                            value: m,
                            label: m.toString().padLeft(2, '0'),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedMinute = value);
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(
                    TimeOfDay(hour: selectedHour, minute: selectedMinute),
                  ),
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked == null || !mounted) return;
    _controller.applyPickedTime(
      picked,
      currentTime: widget.time,
      onChanged: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldStyle =
        (widget.style ?? theme.textTheme.bodyMedium)?.copyWith(
          color: LinuxSegmentedFieldChrome.foregroundColor(theme),
        );

    return LinuxSegmentedFieldWithButton(
      enabled: widget.enabled,
      semanticLabel: widget.semanticLabel,
      fieldValue: _controller.fieldValue,
      fieldWidth: LinuxSegmentedFieldChrome.segmentClusterWidth,
      buttonSemanticLabel: widget.pickerSemanticLabel,
      buttonIcon: YaruIcons.clock,
      onButtonPressed: widget.enabled ? _openTimePicker : null,
      segmentedField: SegmentedEntry(
        controller: _controller.entryController,
        segments: _controller.segments,
        delimiters: const [':'],
        style: fieldStyle,
        enabled: widget.enabled,
        onChanged: (_) => _controller.emitChanged(
          currentTime: widget.time,
          onChanged: widget.onChanged,
        ),
        onFocusLost: () => _controller.commitOrRestore(
          currentTime: widget.time,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

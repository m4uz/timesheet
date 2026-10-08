import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:timesheet/ui/widgets/segmented_entry/segmented_entry.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';
import 'package:timesheet/ui/widgets/segmented_entry/time_entry_controller.dart';
import 'package:timesheet/ui/widgets/segmented_entry/windows_segmented_field_chrome.dart';
import 'package:timesheet/utils/time_of_day_utils.dart';

/// A compact Windows-styled HH:mm segmented time entry (Yaru-inspired) with a
/// Fluent flyout time picker button.
class WindowsTimeEntry extends StatefulWidget {
  const WindowsTimeEntry({
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
  State<WindowsTimeEntry> createState() => _WindowsTimeEntryState();
}

class _WindowsTimeEntryState extends State<WindowsTimeEntry> {
  final _flyoutController = FlyoutController();
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
  void didUpdateWidget(covariant WindowsTimeEntry oldWidget) {
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
    _flyoutController.dispose();
    super.dispose();
  }

  void _openTimePicker() {
    final initial = snapTimeToMinuteInterval(
      widget.time,
      widget.minuteInterval,
    );
    var selectedHour = initial.hour;
    var selectedMinute = initial.minute;

    _flyoutController.showFlyout<void>(
      barrierColor: Colors.transparent,
      additionalOffset: 8,
      builder: (context) {
        final theme = FluentTheme.of(context);
        final minutes = [
          for (var m = 0; m < 60; m += widget.minuteInterval) m,
        ];

        return StatefulBuilder(
          builder: (context, setFlyoutState) {
            return Mica(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.resources.controlFillColorDefault,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 72,
                      child: ComboBox<int>(
                        value: selectedHour,
                        items: [
                          for (var h = 0; h < 24; h++)
                            ComboBoxItem(
                              value: h,
                              child: Text(h.toString().padLeft(2, '0')),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setFlyoutState(() => selectedHour = value);
                          final next = TimeOfDay(
                            hour: value,
                            minute: selectedMinute,
                          );
                          _controller.applyPickedTime(
                            next,
                            currentTime: widget.time,
                            onChanged: widget.onChanged,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(':', style: theme.typography.body),
                    ),
                    SizedBox(
                      width: 72,
                      child: ComboBox<int>(
                        value: selectedMinute,
                        items: [
                          for (final m in minutes)
                            ComboBoxItem(
                              value: m,
                              child: Text(m.toString().padLeft(2, '0')),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setFlyoutState(() => selectedMinute = value);
                          final next = TimeOfDay(
                            hour: selectedHour,
                            minute: value,
                          );
                          _controller.applyPickedTime(
                            next,
                            currentTime: widget.time,
                            onChanged: widget.onChanged,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final fieldStyle = widget.style ?? theme.typography.body;

    return FlyoutTarget(
      controller: _flyoutController,
      child: WindowsSegmentedFieldWithButton(
        enabled: widget.enabled,
        semanticLabel: widget.semanticLabel,
        fieldValue: _controller.fieldValue,
        fieldWidth: SegmentedFieldMetrics.segmentClusterWidth,
        buttonSemanticLabel: widget.pickerSemanticLabel,
        buttonIcon: FluentIcons.clock,
        onButtonPressed: _openTimePicker,
        segmentedField: SegmentedEntry(
          controller: _controller.entryController,
          segments: _controller.segments,
          delimiters: const [':'],
          style: fieldStyle,
          onChanged: (_) => _controller.emitChanged(
            currentTime: widget.time,
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}

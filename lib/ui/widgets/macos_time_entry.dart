import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/widgets/segmented_entry/macos_segmented_field_chrome.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_entry.dart';
import 'package:timesheet/ui/widgets/segmented_entry/segmented_field_metrics.dart';
import 'package:timesheet/ui/widgets/segmented_entry/time_entry_controller.dart';
import 'package:timesheet/utils/time_of_day_utils.dart';

export 'package:timesheet/utils/time_of_day_utils.dart'
    show snapTimeToMinuteInterval;

/// A compact macOS-styled HH:mm segmented time entry (Yaru-inspired) with an
/// optional Cupertino time-picker overlay button.
class MacosTimeEntry extends StatefulWidget {
  const MacosTimeEntry({
    super.key,
    required this.time,
    this.minuteInterval = 1,
    this.onChanged,
    this.style,
    this.enabled = true,
    this.semanticLabel = 'Time',
    this.pickerSemanticLabel = 'Open time picker',
    this.use24hFormat = true,
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

  /// Whether the overlay wheel uses 24-hour format.
  final bool use24hFormat;

  @override
  State<MacosTimeEntry> createState() => _MacosTimeEntryState();
}

class _MacosTimeEntryState extends State<MacosTimeEntry> {
  final GlobalKey _anchorKey = GlobalKey();
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
  void didUpdateWidget(covariant MacosTimeEntry oldWidget) {
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
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final initialTime = snapTimeToMinuteInterval(
      widget.time,
      widget.minuteInterval,
    );
    final selected = await showCupertinoTimePicker(
      context,
      widgetRenderBox: box,
      initialTime: initialTime,
      minuteInterval: widget.minuteInterval,
      use24hFormat: widget.use24hFormat,
    );
    if (selected == null || !mounted) return;
    _controller.applyPickedTime(
      selected,
      currentTime: widget.time,
      onChanged: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final fieldStyle = widget.style ?? theme.typography.body;

    return MacosSegmentedFieldWithButton(
      key: _anchorKey,
      enabled: widget.enabled,
      semanticLabel: widget.semanticLabel,
      fieldValue: _controller.fieldValue,
      fieldWidth: SegmentedFieldMetrics.segmentClusterWidth,
      buttonSemanticLabel: widget.pickerSemanticLabel,
      buttonIcon: CupertinoIcons.clock,
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

import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class CupertinoCalendarPickerToolbarButton extends ToolbarItem {
  const CupertinoCalendarPickerToolbarButton({
    super.key,
    required this.label,
    required this.initialDateTime,
    required this.minimumDateTime,
    required this.maximumDateTime,
    this.onCompleted,
    this.buttonDecoration,
  });

  final String label;
  final DateTime initialDateTime;
  final DateTime minimumDateTime;
  final DateTime maximumDateTime;
  final ValueChanged<DateTime?>? onCompleted;
  final PickerButtonDecoration? buttonDecoration;

  @override
  Widget build(BuildContext context, ToolbarItemDisplayMode displayMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: MacosTheme.of(context).typography.caption1.copyWith(
                    color: MacosColors.systemGrayColor,
                  ),
            ),
            const SizedBox(width: 8.0),
          ],
          SizedBox(
            height: 30,
            width: 140,
            child: CupertinoCalendarPickerButton(
              initialDateTime: initialDateTime,
              minimumDateTime: minimumDateTime,
              maximumDateTime: maximumDateTime,
              onCompleted: onCompleted,
              buttonDecoration: buttonDecoration,
              firstDayOfWeekIndex: 1,
            ),
          ),
        ],
      ),
    );
  }
}

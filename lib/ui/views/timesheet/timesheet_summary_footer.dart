import 'package:flutter/material.dart';
import 'package:timesheet/utils/duration_utils.dart';

class TimesheetSummaryFooter extends StatelessWidget {
  const TimesheetSummaryFooter({
    super.key,
    required this.itemCount,
    required this.totalDuration,
    required this.textStyle,
    required this.dividerColor,
  });

  // Match TimetrackerSummaryFooter: padding (8×2) + text line must fit inside
  // PinnedFooterLayout's fixed height without clipping glyphs.
  static const double reservedHeight = 48.0;

  final int itemCount;
  final Duration totalDuration;
  final TextStyle textStyle;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Items: $itemCount', style: textStyle),
          const SizedBox(width: 8),
          SelectableText(
            'Worked: ${toHmString(totalDuration)}',
            style: textStyle,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

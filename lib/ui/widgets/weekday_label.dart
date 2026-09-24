import 'package:flutter/material.dart';
import 'package:timesheet/utils/weekday_colors.dart';

class WeekdayLabel extends StatelessWidget {
  const WeekdayLabel({
    super.key,
    required this.date,
    required this.label,
    required this.textStyle,
  });

  final DateTime date;
  final String label;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = weekdayLabelBackgroundColor(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: textStyle.copyWith(
          color: weekdayLabelForegroundColor(backgroundColor),
        ),
      ),
    );
  }
}

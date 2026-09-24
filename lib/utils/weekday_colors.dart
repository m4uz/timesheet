import 'package:flutter/material.dart';

Color weekdayLabelBackgroundColor(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => Colors.blue.shade100,
    DateTime.tuesday => Colors.blue.shade200,
    DateTime.wednesday => Colors.blue.shade300,
    DateTime.thursday => Colors.blue.shade400,
    DateTime.friday => Colors.blue.shade500,
    DateTime.saturday => Colors.blue.shade600,
    DateTime.sunday => Colors.blue.shade700,
    _ => Colors.blue.shade500,
  };
}

Color weekdayLabelForegroundColor(Color backgroundColor) {
  return backgroundColor.computeLuminance() > 0.5
      ? Colors.black87
      : Colors.white;
}

import 'package:flutter/material.dart';

/// Snaps [time] to the nearest [minuteInterval] step for picker wheels.
TimeOfDay snapTimeToMinuteInterval(TimeOfDay time, int minuteInterval) {
  if (minuteInterval <= 1) return time;
  final totalMinutes = time.hour * 60 + time.minute;
  final snapped = (totalMinutes / minuteInterval).round() * minuteInterval;
  return TimeOfDay(hour: (snapped ~/ 60) % 24, minute: snapped % 60);
}

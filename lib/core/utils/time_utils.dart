import 'package:flutter/material.dart';

TimeOfDay parseTime(String timeString) {
  final parts = timeString.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

double timeToPixels(TimeOfDay time, double hourHeight) {
  return (time.hour - 7 + time.minute / 60.0) * hourHeight;
}

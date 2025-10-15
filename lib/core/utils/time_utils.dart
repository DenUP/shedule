import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

TimeOfDay parseTime(String timeString) {
  final parts = timeString.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

double timeToPixels(TimeOfDay time, double hourHeight) {
  return (time.hour - 7 + time.minute / 60.0) * hourHeight;
}

// Четная или не четная неделя

// Создаем расширение для удобства
extension on DateTime {
  int get weekOfYear {
    final startOfYear = DateTime(year, 1, 1);
    final weekNumber =
        ((difference(startOfYear).inDays + startOfYear.weekday) / 7).ceil();
    return weekNumber;
  }
}

bool isEvenWeek([DateTime? date]) {
  final targetDate = date ?? DateTime.now();

  final weekNumber = targetDate.weekOfYear;
  return weekNumber % 2 == 0;
}

String get getEvenWeekString =>
    isEvenWeek() ? 'Четная неделя' : 'Нечетная неделя';

extension DateTimeX on DateTime {
  int get dayOfYear => int.parse(DateFormat("D").format(this));
}

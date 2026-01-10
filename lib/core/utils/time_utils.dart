import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

TimeOfDay parseTime(String timeString) {
  final parts = timeString.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

double timeToPixels(TimeOfDay time, double hourHeight) {
  return (time.hour - 8 + time.minute / 60.0) * hourHeight;
}

// Функция для получения номера учебной недели от 1 сентября
int getAcademicWeekNumber(DateTime date) {
  // Определяем начало учебного года (1 сентября)
  DateTime academicYearStart;
  if (date.month >= 9) {
    // Если текущая дата после сентября, учебный год начался в этом году
    academicYearStart = DateTime(date.year, 9, 1);
  } else {
    // Если текущая дата до сентября, учебный год начался в прошлом году
    academicYearStart = DateTime(date.year - 1, 9, 1);
  }

  // Вычисляем разницу в днях
  int differenceInDays = date.difference(academicYearStart).inDays;

  // Если дата раньше начала учебного года
  if (differenceInDays < 0) {
    return 1;
  }

  // Вычисляем номер недели (начиная с 1)
  int weekNumber = (differenceInDays ~/ 7) + 1;
  return weekNumber;
}

bool isEvenWeek([DateTime? date]) {
  final targetDate = date ?? DateTime.now();
  final weekNumber = getAcademicWeekNumber(targetDate);
  return weekNumber % 2 == 0;
}

String get getEvenWeekString =>
    isEvenWeek() ? 'Четная неделя' : 'Нечетная неделя';

extension DateTimeX on DateTime {
  int get dayOfYear => int.parse(DateFormat("D").format(this));
}

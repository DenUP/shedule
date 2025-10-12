import 'package:flutter/material.dart';

class Task {
  final String title;
  final String project;
  final TimeOfDay start;
  final TimeOfDay end;
  final Color color;

  Task({
    required this.title,
    required this.project,
    required this.start,
    required this.end,
    required this.color,
  });
}

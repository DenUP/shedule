class Shedule {
  final String subjectName;
  final String? teacherName;
  final String? classroom;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Shedule({
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.teacherName,
    this.classroom,
  });

  factory Shedule.fromJson(Map<String, dynamic> e) {
    final ts = e['time_slots'];

    if (ts == null) {
      print(e);
    }
    return Shedule(
      subjectName: e['subject_name'],
      teacherName: e['teacher_name'],
      dayOfWeek: ts['day_of_week'],
      startTime: ts['start_time'],
      endTime: ts['end_time'],
    );
  }
  Map<String, dynamic> toJson() => {
    'subject_name': subjectName,
    'teacher_name': teacherName,
    'time_slots': {
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
    },
  };
}

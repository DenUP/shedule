import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class ShedulePage extends StatelessWidget {
  const ShedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double hourHeight = 100.0;

    String formatTime24(TimeOfDay time) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat('HH:mm').format(dt);
    }

    final List<Task> tasks = [
      Task(
        title: 'Design 2 App Screens',
        project: 'Crypto Wallet App',
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 30),
        color: Colors.deepPurpleAccent,
      ),
      Task(
        title: 'Design Landing Page',
        project: 'Crypto Wallet App',
        start: const TimeOfDay(hour: 11, minute: 0),
        end: const TimeOfDay(hour: 12, minute: 0),
        color: Colors.pinkAccent,
      ),
      Task(
        title: 'Design Landing Page',
        project: 'Crypto Wallet App',
        start: const TimeOfDay(hour: 11, minute: 0),
        end: const TimeOfDay(hour: 12, minute: 0),
        color: Colors.pinkAccent,
      ),

      Task(
        title: 'Design Landing Page',
        project: 'Crypto Wallet App',
        start: const TimeOfDay(hour: 14, minute: 0),
        end: const TimeOfDay(hour: 16, minute: 0),
        color: Colors.pinkAccent,
      ),
    ];

    double timeToPixels(TimeOfDay time) {
      return (time.hour - 7 + time.minute / 60.0) * hourHeight;
    }

    final now = TimeOfDay.now();
    final currentTop = timeToPixels(now);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: SizedBox(
          height: 10 * hourHeight, // высота для всех часов
          child: Stack(
            children: [
              // 1 Фон с часами
              Column(
                children: List.generate(10, (index) {
                  final label = DateFormat(
                    'H:mm',
                  ).format(DateTime(0, 0, 0, index + 7));
                  return SizedBox(
                    height: hourHeight,
                    child: Stack(
                      children: [
                        // Линия
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(height: 1, color: Color(0xFFDFDFDF)),
                        ),
                        Positioned(
                          top:
                              hourHeight / 2 -
                              8, // центрируем текст относительно часа
                          left: 25,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Color(0xFF7B7B7B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              // 2️⃣ Карточки задач
              ...tasks.map((task) {
                final top = timeToPixels(task.start);
                final bottom = timeToPixels(task.end);
                final height = bottom - top;

                return Positioned(
                  top: top,
                  left: 80,
                  right: 20,
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: task.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          task.project,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        const Spacer(),
                        Row(
                          children: [
                            SvgPicture.asset('assets/icons/clock.svg'),
                            SizedBox(width: 6),
                            Text(
                              '${formatTime24(task.start)} - ${formatTime24(task.end)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // 3️⃣ Линия текущего времени
              Positioned(
                top: currentTop - 1,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.circle,
                      size: 10,
                      color: Colors.blueAccent,
                    ),
                    Container(
                      height: 2,
                      color: Colors.blueAccent,
                      width: MediaQuery.of(context).size.width - 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

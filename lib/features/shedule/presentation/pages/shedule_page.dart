import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shedule_test/core/utils/time_utils.dart';
import 'package:shedule_test/features/shedule/presentation/bloc/shedule_bloc.dart';

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

    final taskColors = [
      const Color(0xFF42A5F5), // насыщенный синий
      const Color(0xFFFFA726), // ярко-оранжевый
      const Color(0xFF66BB6A), // зелёный
      const Color(0xFFAB47BC), // фиолетовый
    ];
    final now = TimeOfDay.now();
    final currentTop = timeToPixels(now, hourHeight);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: SizedBox(
          height: 10 * hourHeight, // высота для всех часов
          child: BlocConsumer<SheduleBloc, SheduleState>(
            listener: (context, state) {},
            builder: (context, state) {
              print(state);
              return state is SheduleLoading
                  ? Center(child: CircularProgressIndicator())
                  : state is SheduleSuccess
                  ? Stack(
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
                                    child: Container(
                                      height: 1,
                                      color: Color(0xFFDFDFDF),
                                    ),
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
                        ...state.shedule.map((task) {
                          final index = state.shedule.indexOf(task);
                          final start = parseTime(task.startTime);
                          final end = parseTime(task.endTime);

                          final top = timeToPixels(start, hourHeight);
                          final bottom = timeToPixels(end, hourHeight);
                          final height = bottom - top;

                          return Positioned(
                            top: top,
                            left: 80,
                            right: 20,
                            child: Container(
                              height: height,
                              decoration: BoxDecoration(
                                color: taskColors[index % taskColors.length],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.subjectName,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    task.teacherName ?? '',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const Spacer(),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/clock.svg',
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '${formatTime24(start)} - ${formatTime24(end)}',
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
                          top: currentTop - 9,
                          left: -5,
                          right: 0,
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              SvgPicture.asset(
                                'assets/icons/Polygon.svg',
                                width: 15,
                                colorFilter: ColorFilter.mode(
                                  Colors.blueAccent,
                                  BlendMode.srcATop,
                                ),
                              ),
                              Container(
                                height: 2,
                                color: Colors.blueAccent,
                                width: MediaQuery.of(context).size.width - 15,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

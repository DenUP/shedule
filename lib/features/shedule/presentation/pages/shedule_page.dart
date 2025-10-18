import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shedule_test/core/utils/time_utils.dart';
import 'package:shedule_test/features/shedule/presentation/bloc/shedule_bloc.dart';

class ShedulePage extends StatefulWidget {
  const ShedulePage({super.key});

  @override
  State<ShedulePage> createState() => _ShedulePageState();
}

class _ShedulePageState extends State<ShedulePage> {
  DateTime _selectedDate = DateTime.now();

  String formatTime24(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  String formatTimeMonthDay(DateTime date) {
    final formatted = DateFormat('d MMMM, y', 'ru_RU').format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  void initState() {
    context.read<SheduleBloc>().add(
      SheduleLoadEvent(groupName: "22-2ИСП", selectedDate: _selectedDate),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double hourHeight = 100.0;

    final taskColors = [
      const Color(0xFF42A5F5), // насыщенный синий
      const Color(0xFFFFA726), // ярко-оранжевый
      const Color(0xFF66BB6A), // зелёный
      const Color(0xFFAB47BC), // фиолетовый
    ];

    final now = TimeOfDay.now();
    final currentTop = timeToPixels(now, hourHeight);

    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      body: BlocConsumer<SheduleBloc, SheduleState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Column(
            children: [
              // ---------- Верхний блок ----------
              Container(
                height: 180,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 36,
                        bottom: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatTimeMonthDay(DateTime.now()),
                            style: const TextStyle(
                              color: Color(0xFF131313),
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(getEvenWeekString),
                        ],
                      ),
                    ),
                    // ---------- DatePicker ----------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: DatePicker(
                        DateTime.now().subtract(const Duration(days: 0)),
                        initialSelectedDate: _selectedDate,
                        selectionColor: const Color(0xFF01021D),
                        selectedTextColor: Colors.white,
                        locale: 'ru_RU',
                        daysCount: 30,
                        height: 90,
                        onDateChange: (date) {
                          // Отправляем событие в BLoC
                          context.read<SheduleBloc>().add(
                            SheduleLoadEvent(
                              groupName: "22-2ИСП",
                              selectedDate: date,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- Контент с расписанием ----------
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 10 * hourHeight,
                    child: Builder(
                      builder: (context) {
                        if (state is SheduleLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is SheduleSuccess) {
                          return Stack(
                            children: [
                              // 1️⃣ Фон с часами
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
                                            color: const Color(0xFFB0B0B0),
                                          ),
                                        ),
                                        Positioned(
                                          top: hourHeight / 2 - 8,
                                          left: 25,
                                          child: Text(
                                            label,
                                            style: const TextStyle(
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
                                final maxHeight = 10 * hourHeight - top;
                                final height = (bottom - top).clamp(
                                  0.0,
                                  maxHeight,
                                );

                                return Positioned(
                                  top: top,
                                  left: 80,
                                  right: 20,
                                  child: Container(
                                    height: height + 9,
                                    decoration: BoxDecoration(
                                      color:
                                          taskColors[index % taskColors.length],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.subjectName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "${task.teacherName}",
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          getClassRoom(task.classroom),
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/clock.svg',
                                              width: 14,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Colors.white70,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
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
                                      colorFilter: const ColorFilter.mode(
                                        Colors.blueAccent,
                                        BlendMode.srcATop,
                                      ),
                                    ),
                                    Container(
                                      height: 2,
                                      color: Colors.blueAccent,
                                      width:
                                          MediaQuery.of(context).size.width -
                                          15,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String getClassRoom(String? value) {
    if (value == 'None') {
      return '';
    } else {
      return "Кабинет: $value";
    }
  }
}

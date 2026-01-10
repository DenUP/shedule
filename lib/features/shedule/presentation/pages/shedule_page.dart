import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shedule_test/core/utils/time_utils.dart';
import 'package:shedule_test/dependecy_injection.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_local_data_source.dart';
import 'package:shedule_test/features/shedule/presentation/bloc/shedule_bloc.dart';

class ShedulePage extends StatefulWidget {
  const ShedulePage({super.key});

  @override
  State<ShedulePage> createState() => _ShedulePageState();
}

class _ShedulePageState extends State<ShedulePage> {
  String? _selectedGroup;
  final DateTime _selectedDate = DateTime.now();

  _addDateBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 15),
      child: Expanded(
        child: DatePicker(
          locale: 'ru_RU',
          DateTime.now(),
          height: 100,
          width: 80,
          initialSelectedDate: DateTime.now(),
          selectionColor: Color(0xFF4e5ae8),
          selectedTextColor: Colors.white,
          dateTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          dayTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          monthTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          onDateChange: (date) {
            // Отправляем событие в BLoC
            if (_selectedGroup != null) {
              context.read<SheduleBloc>().add(
                SheduleLoadEvent(
                  groupName: _selectedGroup!,
                  selectedDate: date,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  _appBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: GestureDetector(
        onTap: () async {
          getIt<SheduleLocalDataSource>().clearSelectedGroup();
          await _showGroupPicker();
        },
        child: Row(
          children: [
            Text(
              _selectedGroup ?? '',
              style: const TextStyle(
                color: Color(0xFF1F2024),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      actions: [
        Text(getEvenWeekString, style: TextStyle(color: Color(0xFF71727A))),
        SizedBox(width: 20),
      ],
    );
  }

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
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final savedGroup = getIt<SheduleLocalDataSource>().getSelectedGroup();

      if (savedGroup == null) {
        await _showGroupPicker();
      } else {
        _selectedGroup = savedGroup; // <-- присвоение состояния
        context.read<SheduleBloc>().add(
          SheduleLoadEvent(groupName: savedGroup, selectedDate: DateTime.now()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double hourHeight = 120.0;

    final taskColors = [
      const Color(0xFF4e5ae8), // насыщенный синий
      const Color(0xFFFFB746), // ярко-оранжевый
      const Color(0xFF66BB6A), // зелёный
      const Color(0xFFff4667), // фиолетовый
    ];

    final now = TimeOfDay.now();
    final currentTop = timeToPixels(now, hourHeight);

    return BlocConsumer<SheduleBloc, SheduleState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: _appBar(),
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // ---------- Верхний блок ----------
              _addDateBar(),
              SizedBox(height: 10),

              // ---------- Контент с расписанием ----------
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 10 * hourHeight,
                    child: Builder(
                      builder: (context) {
                        if (state is SheduleLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFA726),
                            ),
                          );
                        } else if (state is SheduleSuccess) {
                          return Stack(
                            children: [
                              // 1️⃣ Фон с часами
                              Column(
                                children: List.generate(10, (index) {
                                  final label = DateFormat(
                                    'H:mm',
                                  ).format(DateTime(0, 0, 0, index + 8));
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
                                            color: const Color(0xFFC5C6CC),
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
                                          maxLines: height < 100
                                              ? 1
                                              : height < 140
                                              ? 2
                                              : height < 200
                                              ? 4
                                              : null,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        height > 100
                                            ? Text(
                                                "${task.teacherName}",
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            : SizedBox(),
                                        const Spacer(),
                                        getClassRoom(task.classroom),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              color: Colors.grey[200],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${formatTime24(start)} - ${formatTime24(end)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[100],
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
                        } else if (state is SheduleError) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Нет интернета',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Пожалуйста, подключитесь к сети и попробуйте снова.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        } else {
                          return SizedBox();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGroupPicker() async {
    final List<String> groups = [
      "11",
      "12",
      "21",
      "22",
      "22-27ТМ",
      "22-2ИСП",
      "23-29ТМ",
      "23-3ИСП",
      "24-31ТМ",
      "25-33ТМ",
    ];
    String selectedGroup = groups[0];

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      builder: (BuildContext context) {
        return Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height / 2,
            child: Column(
              children: [
                const Text(
                  "Выберите группу",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 60,
                    onSelectedItemChanged: (index) {
                      selectedGroup = groups[index];
                      _selectedGroup = selectedGroup;
                    },
                    children: groups
                        .map((e) => Center(child: Text(e)))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 60,
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                        backgroundColor: Color(0xFF1957FE),
                      ),
                      onPressed: () async {
                        // Сохраняем выбранную группу
                        await getIt<SheduleLocalDataSource>().saveSelectedGroup(
                          selectedGroup,
                        );
                        _selectedGroup = selectedGroup;
                        if (!context.mounted) return;
                        Navigator.pop(context); // закрываем модалку
                        // Загружаем расписание
                        context.read<SheduleBloc>().add(
                          SheduleLoadEvent(
                            groupName: selectedGroup,
                            selectedDate: DateTime.now(),
                          ),
                        );
                      },
                      child: const Text(
                        "Подтвердить",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget getClassRoom(String? value) {
    if (value == 'None' && value != null) {
      return SizedBox();
    } else {
      return Text(
        "Кабинет: $value",
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }
}

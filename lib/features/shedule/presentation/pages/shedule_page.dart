import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shedule_test/core/network/updatechecker.dart';
import 'package:shedule_test/core/utils/time_utils.dart';
import 'package:shedule_test/dependecy_injection.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_local_data_source.dart';
import 'package:shedule_test/features/shedule/domain/repositories/groups_repository.dart';
import 'package:shedule_test/features/shedule/presentation/bloc/shedule_bloc.dart';

// Импортируем модель Shedule
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';

// Цветовая палитра
class AppColors {
  static const Color primary = Color(0xFF4E5AE8);
  static const Color primaryDark = Color(0xFF4048C9);
  static const Color secondary = Color(0xFFFFB746);
  static const Color accent = Color(0xFF66BB6A);
  static const Color error = Color(0xFFFF4667);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1F2024);
  static const Color textSecondary = Color(0xFF71727A);
  static const Color textTertiary = Color(0xFFA0A1A8);
  static const Color textOnPrimary = Colors.white;

  static const Color divider = Color(0xFFE8E9ED);
  static const Color border = Color(0xFFE1E2E6);
  static const Color shadow = Color(0x1A000000);

  static const List<Color> taskColors = [
    primary,
    secondary,
    accent,
    Color(0xFF9C27B0), // фиолетовый
    Color(0xFFFF7043), // коралловый
  ];
}

// Текстовая тема
class AppTextStyles {
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.lato(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.lato(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.lato(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static TextStyle caption(BuildContext context) => GoogleFonts.lato(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}

class ShedulePage extends StatefulWidget {
  const ShedulePage({super.key});

  @override
  State<ShedulePage> createState() => _ShedulePageState();
}

class _ShedulePageState extends State<ShedulePage> {
  String? _selectedGroup;
  DateTime _selectedDate = DateTime.now();
  bool _isSelectingGroup = false;
  String?
  _tempSelectedGroup; // Временная переменная для выбора в модальном окне

  // Добавляем контроллер для DatePicker
  late DatePickerController _datePickerController;

  @override
  void initState() {
    super.initState();
    _datePickerController = DatePickerController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Предварительно загружаем группы
      await getIt<GroupsRepository>().preloadGroups();

      final savedGroup = getIt<SheduleLocalDataSource>().getSelectedGroup();
      if (savedGroup == null) {
        await _showGroupPicker();
      } else {
        setState(() {
          _selectedGroup = savedGroup;
        });
        context.read<SheduleBloc>().add(
          SheduleLoadEvent(groupName: savedGroup, selectedDate: _selectedDate),
        );
      }
      UpdateChecker.showUpdateDialog(context);
    });
  }

  @override
  void dispose() {
    _datePickerController;
    super.dispose();
  }

  Widget _buildDateBar() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DatePicker(
        locale: 'ru_RU',
        DateTime.now(),
        height: 100,
        width: 70,
        initialSelectedDate: _selectedDate,
        selectionColor: AppColors.primary,
        selectedTextColor: AppColors.textOnPrimary,
        dateTextStyle: GoogleFonts.lato(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        dayTextStyle: GoogleFonts.lato(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        monthTextStyle: GoogleFonts.lato(
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
        controller: _datePickerController, // Добавляем контроллер
        onDateChange: (date) {
          setState(() {
            _selectedDate = date;
          });
          if (_selectedGroup != null) {
            context.read<SheduleBloc>().add(
              SheduleLoadEvent(groupName: _selectedGroup!, selectedDate: date),
            );
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.background,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: IconButton(
          icon: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          onPressed: () {
            // Перелистывается на сегодняшнюю дату с анимацией
            _scrollToToday();
          },
        ),
      ),
      title: GestureDetector(
        onTap: () async {
          await _showGroupPicker();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                _selectedGroup ?? 'Выберите группу',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _selectedGroup != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
      centerTitle: true,
      actions: _selectedGroup != null
          ? [
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  // Используем _selectedDate вместо текущей даты
                  isEvenWeek(_selectedDate)
                      ? 'Четная неделя'
                      : 'Нечетная неделя',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
          : null,
    );
  }

  // Метод для прокрутки к сегодняшней дате
  void _scrollToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDate = today;
    });

    _datePickerController.setDateAndAnimate(
      _selectedDate,
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
    );

    // Анимируем прокрутку к сегодняшней дате

    // Загружаем расписание на сегодня
    if (_selectedGroup != null) {
      context.read<SheduleBloc>().add(
        SheduleLoadEvent(groupName: _selectedGroup!, selectedDate: today),
      );
    }
  }

  // Остальной код остается без изменений...
  Widget _buildTimeIndicator(double hourHeight, TimeOfDay now) {
    final currentTop = timeToPixels(now, hourHeight);

    return Positioned(
      top: currentTop - 1,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 20, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Shedule task, int index, double hourHeight) {
    final start = parseTime(task.startTime);
    final end = parseTime(task.endTime);
    final top = timeToPixels(start, hourHeight);
    final bottom = timeToPixels(end, hourHeight);
    final maxHeight = 10 * hourHeight - top;
    final height = (bottom - top).clamp(0.0, maxHeight);
    final color = AppColors.taskColors[index % AppColors.taskColors.length];

    return Positioned(
      top: top,
      left: 80,
      right: 16,
      child: Container(
        height: height - 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.subjectName,
                    maxLines: height > 120 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            if (height > 100 &&
                task.teacherName != null &&
                task.teacherName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.textOnPrimary.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.teacherName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textOnPrimary.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (height > 120 &&
                task.classroom != null &&
                task.classroom != 'None' &&
                task.classroom!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textOnPrimary.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ауд. ${task.classroom}',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${formatTime24(start)} - ${formatTime24(end)}',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: 60,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Расписание отсутствует',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'На выбранную дату нет занятий',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SheduleError state) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 60,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Нет подключения',
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Проверьте интернет-соединение\nи попробуйте снова',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              if (_selectedGroup != null) {
                context.read<SheduleBloc>().add(
                  SheduleLoadEvent(
                    groupName: _selectedGroup!,
                    selectedDate: _selectedDate,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Повторить попытку',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double hourHeight = 120.0;
    final now = TimeOfDay.now();

    return BlocConsumer<SheduleBloc, SheduleState>(
      listener: (context, state) {},
      builder: (context, state) {
        // Вычисляем количество пар для отображения
        int lessonCount = 0;
        if (state is SheduleSuccess) {
          lessonCount = state.shedule.length;
        }

        return Scaffold(
          appBar: _buildAppBar(),
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Дата-бар
              _buildDateBar(),
              const SizedBox(height: 16),

              // Заголовок дня
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatTimeMonthDay(_selectedDate),
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (lessonCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timeline_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$lessonCount ${_getLessonWord(lessonCount)}',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Расписание
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: Builder(
                      builder: (context) {
                        if (state is SheduleLoading) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Загружаем расписание...',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (state is SheduleSuccess) {
                          if (state.shedule.isEmpty) {
                            return _buildEmptyState();
                          }

                          return SingleChildScrollView(
                            child: SizedBox(
                              height: 10 * hourHeight,
                              child: Stack(
                                children: [
                                  // Временные метки
                                  Column(
                                    children: List.generate(10, (index) {
                                      final label = DateFormat(
                                        'H:mm',
                                      ).format(DateTime(0, 0, 0, index + 8));
                                      return SizedBox(
                                        height: hourHeight,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 1,
                                                color: AppColors.divider,
                                              ),
                                            ),
                                            Positioned(
                                              top: hourHeight / 2 - 10,
                                              left: 32,
                                              child: Container(
                                                width: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  label,
                                                  style: GoogleFonts.lato(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textTertiary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),

                                  // Карточки занятий - теперь передаем объекты Shedule
                                  ...state.shedule
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => _buildScheduleCard(
                                          entry.value,
                                          entry.key,
                                          hourHeight,
                                        ),
                                      )
                                      .toList(),

                                  // Индикатор текущего времени (только для сегодня)
                                  if (_isToday(_selectedDate))
                                    _buildTimeIndicator(hourHeight, now),
                                ],
                              ),
                            ),
                          );
                        } else if (state is SheduleError) {
                          return _buildErrorState(state);
                        }
                        return _buildEmptyState();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _selectedGroup != null
              ? FloatingActionButton(
                  onPressed: () {
                    if (_selectedGroup != null) {
                      // Используем RefreshEvent для принудительного обновления
                      context.read<SheduleBloc>().add(
                        SheduleRefreshEvent(
                          groupName: _selectedGroup!,
                          selectedDate: _selectedDate,
                        ),
                      );
                    }
                  },
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white),
                )
              : null,
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

    // Устанавливаем начальное значение
    _tempSelectedGroup = _selectedGroup ?? groups[0];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "№ группа",
                      style: GoogleFonts.lato(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final isSelected = group == _tempSelectedGroup;

                        return ListTile(
                          onTap: () {
                            setState(() {
                              _tempSelectedGroup = group;
                            });
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.groups_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                          ),
                          title: Text(
                            group,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          tileColor: isSelected
                              ? AppColors.primary.withOpacity(0.05)
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: AppColors.border),
                            ),
                            child: Text(
                              "Отмена",
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final selectedGroup = _tempSelectedGroup!;
                              await getIt<SheduleLocalDataSource>()
                                  .saveSelectedGroup(selectedGroup);

                              // Обновляем состояние
                              if (mounted) {
                                setState(() {
                                  _selectedGroup = selectedGroup;
                                  _isSelectingGroup = false;
                                });
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context);

                              // Загружаем расписание для выбранной группы и текущей даты
                              context.read<SheduleBloc>().add(
                                SheduleLoadEvent(
                                  groupName: selectedGroup,
                                  selectedDate: _selectedDate,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Выбрать",
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
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

  String _getLessonWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'пара';
    } else if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'пары';
    } else {
      return 'пар';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

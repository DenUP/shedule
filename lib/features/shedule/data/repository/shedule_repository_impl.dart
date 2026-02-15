import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shedule_test/core/utils/time_utils.dart';
import 'package:shedule_test/dependecy_injection.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_local_data_source.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_remote_data_source.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';
import 'package:shedule_test/features/shedule/domain/repositories/shedule_repository.dart';

class SheduleRepositoryImpl implements SheduleRepository {
  final SheduleRemoteDataSource remoteDataSource;
  final SheduleLocalDataSource localDataSource;

  SheduleRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Shedule>> getShedule({
    required String groupName,
    required DateTime selectedDate,
    required bool forceRefresh,
  }) async {
    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd';
    final currentWeekDay = selectedDate.weekday;

    // Ключ для кэша: группа + дата
    final cacheKey =
        '${groupName}_${selectedDate.toIso8601String().substring(0, 10)}';

    try {
      // 1. Сначала пробуем получить данные из локальной базы
      List<Shedule>? cachedData = localDataSource.getCache(cacheKey);

      // 2. Проверяем, нужно ли обновлять из интернета
      final isInternet = await getIt<InternetConnection>().hasInternetAccess;

      if (isInternet && (forceRefresh || cachedData == null)) {
        // Получаем измененное расписание
        final changedData = await remoteDataSource.getChangedShedule(
          groupName: groupName,
          selectedDate: selectedDate,
        );

        // Если есть измененное расписание, используем только его
        if (changedData.isNotEmpty) {
          // Сохраняем в локальную базу
          await localDataSource.saveCache(cacheKey, changedData);

          // Фильтруем по текущему дню недели (хотя changedData уже должна содержать только на эту дату)
          final filtered = _filterByDay(changedData, currentWeekDay);
          return _sortByTime(filtered);
        }

        // Если измененного расписания нет, берем основное
        final baseData = await remoteDataSource.getShedule(
          groupName: groupName,
          selectedDate: selectedDate,
        );

        // Фильтруем основное расписание по текущему дню недели
        final filteredBaseData = _filterByDay(baseData, currentWeekDay);

        // Сохраняем в локальную базу
        await localDataSource.saveCache(cacheKey, filteredBaseData);

        return _sortByTime(filteredBaseData);
      }

      // 3. Если есть кэшированные данные, используем их
      if (cachedData != null) {
        return _sortByTime(cachedData);
      }

      // 4. Если данных нет вообще
      throw Exception('Нет данных в кэше и нет подключения к интернету');
    } catch (e) {
      // 5. В случае ошибки пробуем получить хотя бы кэш
      final cachedData = localDataSource.getCache(cacheKey);
      if (cachedData != null) {
        return _sortByTime(cachedData);
      }

      throw Exception('Ошибка при загрузке расписания: $e');
    }
  }

  // Вспомогательные методы для фильтрации и сортировки
  List<Shedule> _filterByDay(List<Shedule> data, int dayOfWeek) {
    return data.where((schedule) => schedule.dayOfWeek == dayOfWeek).toList();
  }

  List<Shedule> _sortByTime(List<Shedule> data) {
    data.sort((a, b) {
      final timeA = parseTime(a.startTime);
      final timeB = parseTime(b.startTime);
      return timeA.hour * 60 + timeA.minute - (timeB.hour * 60 + timeB.minute);
    });
    return data;
  }

  // Метод для получения полного расписания на неделю
  @override
  Future<List<Shedule>> getFullShedule({
    required String groupName,
    required DateTime selectedDate,
  }) async {
    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd';

    // Ключ для кэша полного расписания: группа + четность недели + дата начала недели
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    final cacheKey =
        'full_${groupName}_${parity}_${startOfWeek.toIso8601String().substring(0, 10)}';

    final isInternet = await getIt<InternetConnection>().hasInternetAccess;
    final cache = localDataSource.getCache(cacheKey);

    try {
      if (isInternet) {
        // Получаем основное расписание на неделю
        final baseData = await remoteDataSource.getShedule(
          groupName: groupName,
          selectedDate: selectedDate,
        );

        // Создаем карту изменений по дням недели
        final Map<int, List<Shedule>> changedDataByDay = {};

        // Для каждого дня недели проверяем есть ли изменения
        for (int day = 1; day <= 7; day++) {
          final dateForDay = startOfWeek.add(Duration(days: day - 1));
          final changedData = await remoteDataSource.getChangedShedule(
            groupName: groupName,
            selectedDate: dateForDay,
          );

          if (changedData.isNotEmpty) {
            changedDataByDay[day] = changedData;
          }
        }

        // Объединяем расписание
        final List<Shedule> result = [];

        for (final schedule in baseData) {
          // Если для этого дня есть изменения, пропускаем основное расписание
          if (!changedDataByDay.containsKey(schedule.dayOfWeek)) {
            result.add(schedule);
          }
        }

        // Добавляем все изменения
        for (final changedList in changedDataByDay.values) {
          result.addAll(changedList);
        }

        final sortedResult = _sortByTime(result);
        await localDataSource.saveCache(cacheKey, sortedResult);
        return sortedResult;
      } else if (cache != null) {
        return cache;
      } else {
        throw Exception('Нет доступа к данным');
      }
    } catch (e) {
      if (cache != null) return cache;
      throw Exception('Ошибка при загрузке полного расписания: $e');
    }
  }

  @override
  Future<List<Shedule>?> getCachedShedule({
    required String groupName,
    required DateTime selectedDate,
  }) async {
    final cacheKey =
        '${groupName}_${selectedDate.toIso8601String().substring(0, 10)}';
    final cachedData = localDataSource.getCache(cacheKey);
    return cachedData != null ? _sortByTime(cachedData) : null;
  }
}

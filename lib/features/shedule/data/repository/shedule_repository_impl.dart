// lib/features/shedule/data/repository/shedule_repository_impl.dart
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
    required bool
    forceRefresh, // Добавляем параметр для принудительного обновления
  }) async {
    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd';
    final currentWeekDay = selectedDate.weekday;

    // Ключ для кэша: группа + четность недели
    final cacheKey = '${groupName}_$parity';

    try {
      // 1. Сначала пробуем получить данные из локальной базы
      List<Shedule>? cachedData = localDataSource.getCache(cacheKey);

      // 2. Проверяем, нужно ли обновлять из интернета
      final isInternet = await getIt<InternetConnection>().hasInternetAccess;

      if (isInternet && (forceRefresh || cachedData == null)) {
        // Загружаем из интернета только если:
        // - есть интернет И (принудительное обновление ИЛИ нет кэша)
        final baseData = await remoteDataSource.getShedule(
          groupName: groupName,
          selectedDate: selectedDate,
        );

        final changedData = await remoteDataSource.getChangedShedule(
          groupName: groupName,
          selectedDate: selectedDate,
        );

        final data = applyChanges(baseData, changedData);

        // Сохраняем в локальную базу
        await localDataSource.saveCache(cacheKey, data);

        // Фильтруем по текущему дню недели
        final filtered = _filterByDay(data, currentWeekDay);
        return _sortByTime(filtered);
      }

      // 3. Если есть кэшированные данные, используем их
      if (cachedData != null) {
        final filtered = _filterByDay(cachedData, currentWeekDay);
        return _sortByTime(filtered);
      }

      // 4. Если данных нет вообще
      throw Exception('Нет данных в кэше и нет подключения к интернету');
    } catch (e) {
      // 5. В случае ошибки пробуем получить хотя бы кэш
      final cachedData = localDataSource.getCache(cacheKey);
      if (cachedData != null) {
        final filtered = _filterByDay(cachedData, currentWeekDay);
        return _sortByTime(filtered);
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

  List<Shedule> applyChanges(List<Shedule> base, List<Shedule> changed) {
    if (changed.isEmpty) return base;

    final modifiedList = List<Shedule>.from(base);

    for (final change in changed) {
      final index = modifiedList.indexWhere(
        (schedule) =>
            schedule.startTime == change.startTime &&
            schedule.dayOfWeek == change.dayOfWeek,
      );

      if (index != -1) {
        modifiedList[index] = change;
      } else {
        modifiedList.add(change);
      }
    }

    return _sortByTime(modifiedList);
  }

  // Опционально: метод для получения полного расписания без фильтрации по дню
  @override
  Future<List<Shedule>> getFullShedule({
    required String groupName,
    required DateTime selectedDate,
  }) async {
    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd';
    final cacheKey = 'full_${groupName}_$parity';

    final isInternet = await getIt<InternetConnection>().hasInternetAccess;
    final cache = localDataSource.getCache(cacheKey);

    try {
      if (isInternet) {
        final baseData = await remoteDataSource.getShedule(
          groupName: groupName,
          selectedDate: selectedDate,
        );

        final changedData = await remoteDataSource.getChangedShedule(
          groupName: groupName,
          selectedDate: selectedDate,
        );

        final data = applyChanges(baseData, changedData);
        await localDataSource.saveCache(cacheKey, data);
        return data;
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
}

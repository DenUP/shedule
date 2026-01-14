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
    required String groupName,  // Изменено: теперь принимаем имя группы вместо ID
    required DateTime selectedDate,
  }) async {
    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd';
    final List<Shedule> data;
    
    // Создаем ключ для кэша: группа + четность недели + дата
    final cacheKey = '${groupName}_${parity}_${selectedDate.toIso8601String().split('T')[0]}';
    
    final isInternet = await getIt<InternetConnection>().hasInternetAccess;
    final cache = localDataSource.getCache(cacheKey);
    
    try {
      if (isInternet) {
        // Получаем обычное расписание
        final baseData = await remoteDataSource.getShedule(
          groupName: groupName,  // Передаем имя группы
          selectedDate: selectedDate,
        );
        
        // Получаем изменения в расписании
        final changedData = await remoteDataSource.getChangedShedule(
          groupName: groupName,  // Передаем имя группы
          selectedDate: selectedDate,
        );
        
        // Применяем изменения
        data = applyChanges(baseData, changedData);
        
        // Сохраняем в кэш
        await localDataSource.saveCache(cacheKey, data);
      } else if (cache != null) {
        // Используем кэш, если нет интернета
        data = cache;
      } else {
        throw Exception('Нет доступа к интернету и данные не найдены в кэше');
      }

      // Фильтруем по дню недели выбранной даты
      final currentWeekDay = selectedDate.weekday;
      
      final filtered = data.where((schedule) {
        return schedule.dayOfWeek == currentWeekDay;
      }).toList();
      
      // Сортируем по времени начала
      filtered.sort((a, b) {
        final timeA = parseTime(a.startTime);
        final timeB = parseTime(b.startTime);
        return timeA.hour * 60 + timeA.minute - (timeB.hour * 60 + timeB.minute);
      });
      
      return filtered;
    } catch (e) {
      // Пробуем получить данные из кэша в случае ошибки
      final cacheData = localDataSource.getCache(cacheKey);
      if (cacheData != null) {
        // Фильтруем кэшированные данные
        final currentWeekDay = selectedDate.weekday;
        final filtered = cacheData.where((schedule) {
          return schedule.dayOfWeek == currentWeekDay;
        }).toList();
        
        if (filtered.isNotEmpty) {
          return filtered;
        }
      }
      
      throw Exception('Ошибка при загрузке расписания: $e');
    }
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
        // Заменяем существующую пару
        modifiedList[index] = change;
      } else {
        // Добавляем новую пару
        modifiedList.add(change);
      }
    }

    // Сортируем по времени начала
    modifiedList.sort((a, b) {
      final timeA = parseTime(a.startTime);
      final timeB = parseTime(b.startTime);
      return timeA.hour * 60 + timeA.minute - (timeB.hour * 60 + timeB.minute);
    });
    
    return modifiedList;
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
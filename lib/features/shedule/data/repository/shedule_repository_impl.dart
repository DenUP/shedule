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
    required int groupId,
    required DateTime selectedDate,
  }) async {
    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd';
    final List<Shedule> data;
    final isInternet = await getIt<InternetConnection>().hasInternetAccess;
    final cache = localDataSource.getCache(parity);
    try {
      if (isInternet) {
        final baseData = await remoteDataSource.getShedule(
          groupId: groupId,
          selectedDate: selectedDate,
        );
        final changedData = await remoteDataSource.getChangedShedule(
          groupId: groupId,
          selectedDate: selectedDate,
        );
        data = applyChanges(baseData, changedData);
        await localDataSource.saveCache(parity, data);
      } else if (cache != null) {
        data = cache;
      } else {
        throw Exception('Нету КЭША и Интернета');
      }

      final currentWeek = selectedDate.weekday;

      final filtered = data.where((e) {
        return e.dayOfWeek == currentWeek;
      }).toList();
      return filtered;
    } catch (e) {
      throw Exception('Данные пришли с ошибкой - $e');
    }
  }

  List<Shedule> applyChanges(List<Shedule> base, List<Shedule> changed) {
    if (changed.isEmpty) return base;

    final modifiedList = List<Shedule>.from(base);

    for (final change in changed) {
      final index = modifiedList.indexWhere(
        (e) =>
            e.startTime == change.startTime && e.dayOfWeek == change.dayOfWeek,
      );

      if (index != -1) {
        // замена
        modifiedList[index] = change;
      } else {
        // добавление новой пары
        modifiedList.add(change);
      }
    }

    return modifiedList;
  }
}

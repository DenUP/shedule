import 'package:shedule_test/core/utils/time_utils.dart';
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
  }) async {
    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd';
    final List<Shedule> data;
    final cache = localDataSource.getCache(parity);
    if (cache != null && cache.isNotEmpty) {
      data = cache;
    } else {
      data = await remoteDataSource.getShedule(
        groupName: groupName,
        selectedDate: selectedDate,
      );
      localDataSource.saveCache(parity, data);
    }
    final currentWeek = selectedDate.weekday;

    final filtered = data.where((e) {
      return e.dayOfWeek == currentWeek;
    }).toList();
    return filtered;
  }
}

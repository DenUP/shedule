import 'package:shedule_test/features/shedule/domain/dataSource/shedule_remote_data_source.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';
import 'package:shedule_test/features/shedule/domain/repositories/shedule_repository.dart';

class SheduleRepositoryImpl implements SheduleRepository {
  final SheduleRemoteDataSource remoteDataSource;

  SheduleRepositoryImpl({required this.remoteDataSource});
  @override
  Future<List<Shedule>> getShedule({
    required String groupName,
    required int dayOfWeek,
  }) async {
    final result = remoteDataSource.getShedule(
      groupName: groupName,
      dayOfWeek: dayOfWeek,
    );
    return result;
  }
}

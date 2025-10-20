import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';

abstract class SheduleRemoteDataSource {
  Future<List<Shedule>> getShedule({
    required int groupId,
    required DateTime selectedDate,
  });
}

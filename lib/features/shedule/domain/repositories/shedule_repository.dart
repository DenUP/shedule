import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';

abstract class SheduleRepository {
  Future<List<Shedule>> getShedule({
    required String groupName,
    required int dayOfWeek,
  });
}

import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';

abstract class SheduleRepository {
  Future<List<Shedule>> getShedule({
    required String groupName, // Изменено на String
    required DateTime selectedDate,
  });

  // Опционально
  Future<List<Shedule>> getFullShedule({
    required String groupName,
    required DateTime selectedDate,
  });
}

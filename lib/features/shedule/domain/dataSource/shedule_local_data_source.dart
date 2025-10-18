import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';

abstract class SheduleLocalDataSource {
  List<Shedule>? getCache(String parity);
  Future<bool> saveCache(String parity, List<Shedule> shedule);
  Future<void> clearCache();
}

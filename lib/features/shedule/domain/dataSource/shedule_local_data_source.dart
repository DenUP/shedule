import 'package:shedule_test/features/shedule/domain/entity/group.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';

abstract class SheduleLocalDataSource {
  List<Shedule>? getCache(String parity);
  Future<bool> saveCache(String parity, List<Shedule> shedule);
  Future<void> clearCache();
  Future<void> saveSelectedGroup(String group);
  String? getSelectedGroup();
  Future<void> clearSelectedGroup();
  Future<void> saveGroupsList(List<Group> groups);
  Future<List<Group>> getGroupsList();
}

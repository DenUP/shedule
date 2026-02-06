import 'package:shedule_test/features/shedule/domain/entity/group.dart';

abstract class GroupsRepository {
  Future<List<Group>> getGroups({bool forceRefresh = false});
  Future<Group?> getGroupByName(String groupName);
  Future<void> preloadGroups();
  Future<void> saveGroupsToLocal(List<Group> groups);
  Future<List<Group>> getGroupsFromLocal();
}

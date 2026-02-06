import 'package:shedule_test/features/shedule/data/dataSource/group_remote_data_source_impl.dart';
import 'package:shedule_test/features/shedule/data/dataSource/shedule_local_data_source_impl.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_local_data_source.dart';
import 'package:shedule_test/features/shedule/domain/entity/group.dart';
import 'package:shedule_test/features/shedule/domain/repositories/groups_repository.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupRemoteDataSource remoteDataSource;
  final SheduleLocalDataSource localDataSource;

  GroupsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Group>> getGroups({bool forceRefresh = false}) async {
    try {
      // Сначала проверяем локальное хранилище
      final localGroups = await getGroupsFromLocal();

      // Если есть локальные данные и не требуется принудительное обновление
      if (localGroups.isNotEmpty && !forceRefresh) {
        final shouldRefresh =
            await (localDataSource as SheduleLocalDataSourceImpl)
                .shouldRefreshGroups();

        if (!shouldRefresh) {
          return localGroups;
        }
      }

      // Загружаем из сети
      final remoteGroups = await remoteDataSource.getGroups(
        forceRefresh: forceRefresh,
      );

      // Сохраняем в локальное хранилище
      await saveGroupsToLocal(remoteGroups);

      return remoteGroups;
    } catch (e) {
      // В случае ошибки возвращаем локальные данные
      final localGroups = await getGroupsFromLocal();
      if (localGroups.isNotEmpty) {
        return localGroups;
      }
      throw Exception('Failed to load groups: $e');
    }
  }

  @override
  Future<Group?> getGroupByName(String groupName) async {
    // Сначала ищем в локальном хранилище
    final localGroups = await getGroupsFromLocal();

    // Используем простой цикл for
    for (final group in localGroups) {
      if (group.name == groupName) {
        return group;
      }
    }

    // Если не нашли локально, ищем в удаленном источнике
    return await remoteDataSource.getGroupByName(groupName);
  }

  @override
  Future<void> preloadGroups() async {
    await getGroups(forceRefresh: true);
  }

  @override
  Future<void> saveGroupsToLocal(List<Group> groups) async {
    await localDataSource.saveGroupsList(groups);
  }

  @override
  Future<List<Group>> getGroupsFromLocal() async {
    return await localDataSource.getGroupsList();
  }
}

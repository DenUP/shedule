import 'package:shedule_test/core/utils/iterable_extensions.dart';
import 'package:shedule_test/features/shedule/domain/entity/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupRemoteDataSource {
  final SupabaseClient client;
  List<Group>? _cachedGroups; // Кэш в памяти

  GroupRemoteDataSource({required this.client});

  Future<List<Group>> getGroups({bool forceRefresh = false}) async {
    try {
      // Если есть кэш и не требуется принудительное обновление - используем кэш
      if (_cachedGroups != null && !forceRefresh) {
        return _cachedGroups!;
      }

      final response = await client
          .from('groups')
          .select('*')
          .order('name', ascending: true);

      final data = response as List<dynamic>;
      _cachedGroups = data.map((e) => Group.fromJson(e)).toList();
      return _cachedGroups!;
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

  Future<Group?> getGroupByName(String groupName) async {
    try {
      // Сначала проверяем кэш
      if (_cachedGroups != null) {
        final cachedGroup = _cachedGroups!.firstWhereOrNull(
          (group) => group.name == groupName,
        );
        if (cachedGroup != null) return cachedGroup;
      }

      // Если нет в кэше, загружаем из базы
      final response = await client
          .from('groups')
          .select('*')
          .eq('name', groupName)
          .maybeSingle();

      if (response != null) {
        return Group.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to find group: $e');
    }
  }

  // Метод для предварительной загрузки групп
  Future<void> preloadGroups() async {
    await getGroups(forceRefresh: true);
  }

  // Очистка кэша
  void clearCache() {
    _cachedGroups = null;
  }
}

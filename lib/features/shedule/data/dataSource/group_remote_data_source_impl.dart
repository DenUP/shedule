import 'package:shedule_test/features/shedule/domain/entity/group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupRemoteDataSource {
  final SupabaseClient client;

  GroupRemoteDataSource({required this.client});

  Future<List<Group>> getGroups() async {
    try {
      final response = await client
          .from('groups')
          .select('*')
          .order('name', ascending: true);

      final data = response as List<dynamic>;
      return data.map((e) => Group.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

  Future<Group?> getGroupByName(String groupName) async {
    try {
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
}

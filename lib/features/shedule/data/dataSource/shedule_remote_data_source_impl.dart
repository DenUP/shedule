import 'package:shedule_test/core/utils/time_utils.dart';
import 'package:shedule_test/features/shedule/data/dataSource/group_remote_data_source_impl.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_remote_data_source.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';
import 'package:shedule_test/features/shedule/domain/repositories/groups_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SheduleRemoteDataSourceImpl implements SheduleRemoteDataSource {
  final SupabaseClient client;
  final GroupRemoteDataSource groupDataSource;
  final GroupsRepository
  groupsRepository; // Используем репозиторий вместо источника данных

  SheduleRemoteDataSourceImpl({
    required this.client,
    required this.groupDataSource,
    required this.groupsRepository,
  });
  @override
  Future<List<Shedule>> getShedule({
    required String groupName,
    required DateTime selectedDate,
  }) async {
    // Используем репозиторий, который сам решит откуда брать данные
    final group = await groupsRepository.getGroupByName(groupName);
    if (group == null) {
      throw Exception('Group not found: $groupName');
    }

    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd';

    final response = await client
        .from('regular_schedule')
        .select('''
        id, week_parity, subject_name, teacher_name, classroom, 
        time_slots(day_of_week, start_time, end_time)
      ''')
        .eq('group_id', group.id)
        .eq('week_parity', parity);

    final data = response as List<dynamic>;
    return data.map((e) => Shedule.fromJson(e)).toList();
  }

  
  @override
  Future<List<Shedule>> getChangedShedule({
    required String groupName,
    required DateTime selectedDate,
  }) async {
    final group = await groupsRepository.getGroupByName(groupName);
    if (group == null) {
      throw Exception('Group not found: $groupName');
    }

    final response = await client
        .from('changed_schedule')
        .select('''
        id, group_id, date, subject_name, teacher_name, classroom,
        time_slots(day_of_week, start_time, end_time)
      ''')
        .eq('group_id', group.id)
        .eq('date', selectedDate.toIso8601String().substring(0, 10));

    final data = response as List<dynamic>;
    return data.map((e) => Shedule.fromJson(e)).toList();
  }
}
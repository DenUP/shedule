import 'package:shedule_test/features/shedule/domain/dataSource/shedule_remote_data_source.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SheduleRemoteDataSourceImpl implements SheduleRemoteDataSource {
  final SupabaseClient client;

  SheduleRemoteDataSourceImpl({required this.client});
  @override
  Future<List<Shedule>> getShedule({
    required String groupName,
    required int dayOfWeek,
  }) async {
    final response = await client
        .from('regular_schedule')
        .select('''
id, subject_name, teacher_name, classroom, time_slots(day_of_week, start_time, end_time, description, is_break)
      ''')
        .eq('group_id', 1)
        .eq('time_slots.day_of_week', dayOfWeek);
    final data = response as List<dynamic>;
    return data.map((e) => Shedule.fromJson(e)).toList();
  }
}

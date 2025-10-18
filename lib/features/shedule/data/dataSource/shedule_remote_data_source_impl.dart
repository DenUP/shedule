import 'package:shedule_test/core/utils/time_utils.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_remote_data_source.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SheduleRemoteDataSourceImpl implements SheduleRemoteDataSource {
  final SupabaseClient client;

  SheduleRemoteDataSourceImpl({required this.client});
  @override
  @override
  Future<List<Shedule>> getShedule({
    required String groupName,
    required DateTime selectedDate,
  }) async {
    final evenWeek = isEvenWeek(selectedDate);
    final parity = evenWeek ? 'even' : 'odd'; //Четная (even)

    final response = await client
        .from('regular_schedule')
        .select('''
        id, week_parity, subject_name, teacher_name, classroom, 
        time_slots(day_of_week, start_time, end_time)
      ''')
        .eq('group_id', 13)
        .eq('week_parity', parity);

    final data = response as List<dynamic>;
    return data.map((e) => Shedule.fromJson(e)).toList();
  }
}

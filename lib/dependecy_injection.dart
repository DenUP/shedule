import 'package:get_it/get_it.dart';
import 'package:shedule_test/features/shedule/data/dataSource/shedule_remote_data_source_impl.dart';
import 'package:shedule_test/features/shedule/data/repository/shedule_repository_impl.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_remote_data_source.dart';
import 'package:shedule_test/features/shedule/domain/repositories/shedule_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  await Supabase.initialize(
    url: 'https://ecvvgaeoaaowecmyfdfb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjdnZnYWVvYWFvd2VjbXlmZGZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MzcyNjMsImV4cCI6MjA2MDMxMzI2M30.eYiGkQ9TLAoah3yaMwSdWdxoPHT5w7jjmbDoFqpDq9Q',
  );
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  getIt.registerLazySingleton<SheduleRemoteDataSource>(
    () => SheduleRemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerLazySingleton<SheduleRepository>(
    () => SheduleRepositoryImpl(remoteDataSource: getIt()),
  );
}

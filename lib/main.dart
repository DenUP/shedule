import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shedule_test/dependecy_injection.dart';
import 'package:shedule_test/features/shedule/domain/repositories/shedule_repository.dart';
import 'package:shedule_test/features/shedule/presentation/bloc/shedule_bloc.dart';
import 'package:shedule_test/features/shedule/presentation/pages/shedule_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              SheduleBloc(repository: getIt<SheduleRepository>())
                ..add(SheduleLoadEvent(groupName: 'Группа 1', dayOfWeek: 1)),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ShedulePage(),
      ),
    );
  }
}

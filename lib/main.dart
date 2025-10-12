import 'package:flutter/material.dart';
import 'package:shedule_test/features/shedule/presentation/pages/shedule_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: ShedulePage());
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ecvvgaeoaaowecmyfdfb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjdnZnYWVvYWFvd2VjbXlmZGZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MzcyNjMsImV4cCI6MjA2MDMxMzI2M30.eYiGkQ9TLAoah3yaMwSdWdxoPHT5w7jjmbDoFqpDq9Q',
  );

  // Проверяем, авторизован ли пользователь
  final prefs = await SharedPreferences.getInstance();

  final isLoggedIn = prefs.getString('user_id') != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: isLoggedIn ? HomeScreen() : AuthScreen());
  }
}

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with WidgetsBindingObserver {
  @override
  @override
  void initState() {
    super.initState();

    // 1. Инициализируем слушатель для возврата в приложение
    _listener = AppLifecycleListener(
      onResume: () {
        print('App resumed → checking auth status');
        _startSessionCheck();
      },
    );

    // 2. ВАЖНО: Запускаем проверку сразу при открытии экрана
    // Используем Future.microtask, чтобы не блокировать отрисовку
    Future.microtask(() => _startSessionCheck());
  }

  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;
  RealtimeChannel? _channel;
  String? _sessionId; // ИСПРАВЛЕНО: храним как String
  late final AppLifecycleListener _listener;

  // Создание сессии в Supabase
  Future<void> _createAuthSession() async {
    setState(() => _isLoading = true);

    try {
      // 1. Проверяем, нет ли уже авторизации
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        return;
      }

      // 2. Проверяем, есть ли активная (не просроченная) сессия
      final verifiedSessions = await supabase
          .from('auth_sessions')
          .select()
          .eq('status', 'verified')
          .order('updated_at', ascending: false)
          .limit(1);

      if (verifiedSessions.isNotEmpty) {
        final session = verifiedSessions.first;

        await _completeAuth(session['phone_number'], session['telegram_id']);
        return;
      } else {
        // СОЗДАЕМ НОВУЮ СЕССИЮ, если активной нет
        print('Активной сессии нет, создаю новую...');
        final response = await supabase
            .from('auth_sessions')
            .insert({
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
              'expires_at': DateTime.now()
                  .add(Duration(minutes: 10))
                  .toIso8601String(),
            })
            .select()
            .single();

        final sessionData = response as Map<String, dynamic>;
        _sessionId = sessionData['id'].toString();
        print('Создана новая сессия: $_sessionId');
      }

      // 3. Формируем Deep Link с ID сессии
      final String botUsername = 'Lukamorie_menu_bot';
      final String deepLink = 'https://t.me/$botUsername?start=$_sessionId';

      print('Открываю Telegram с сессией: $_sessionId');
      print('Deep Link: $deepLink');

      if (await canLaunchUrl(Uri.parse(deepLink))) {
        await launchUrl(
          Uri.parse(deepLink),
          mode: LaunchMode.externalApplication,
        );
        _startSessionCheck();
      } else {
        print('Не удалось открыть Telegram');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Установите Telegram для авторизации')),
        );
      }
    } catch (e) {
      print('Error creating session: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
    }
  }

  void _startSessionCheck() async {
    if (_sessionId == null) return;

    // 1. Проверка состояния
    final session = await supabase
        .from('auth_sessions')
        .select()
        .eq('id', _sessionId!)
        .maybeSingle();

    if (session != null &&
        session['status'] == 'verified' &&
        session['phone_number'] != null) {
      print('Сессия уже подтверждена');
      _completeAuth(session['phone_number'], session['telegram_id']);
      return;
    }

    // 2. Ждём изменения
    _channel?.unsubscribe();
    _channel = supabase.channel('auth_sessions');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'auth_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _sessionId!,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record != null && record['status'] == 'verified') {
              _channel?.unsubscribe();
              _completeAuth(record['phone_number'], record['telegram_id']);
            }
          },
        )
        .subscribe();
  }

  // Завершение авторизации
  Future<void> _completeAuth(String phone, String telegramId) async {
    try {
      // Проверяем, есть ли пользователь
      final existingUserResponse = await supabase
          .from('users')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      String userId;

      if (existingUserResponse == null) {
        // Создаем нового пользователя
        final newUserResponse = await supabase
            .from('users')
            .insert({
              'phone': phone,
              'telegram_id': telegramId,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        // Удаляем из сессии
        await supabase.from('auth_sessions').delete().eq('status', 'verified');

        final userData = newUserResponse as Map<String, dynamic>;
        userId = userData['id'].toString();
        print('Пользователь создан: $userId');
      } else {
        // Пользователь существует
        final userData = existingUserResponse as Map<String, dynamic>;
        userId = userData['id'].toString();

        await supabase
            .from('users')
            .update({'telegram_id': telegramId})
            .eq('id', userId);
      }

      // Сохраняем данные пользователя
      await _saveUserData(userId, phone, telegramId);

      // Удаляем сессию после успешной авторизации
      await _deleteSession();

      setState(() => _isLoading = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Auth error: $e');
      setState(() => _isLoading = false);
    }
  }

  // Сохранение данных пользователя
  Future<void> _saveUserData(
    String userId,
    String phone,
    String telegramId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('phone', phone);
    await prefs.setString('telegram_id', telegramId);
    await prefs.setBool('is_logged_in', true);
    print('Данные сохранены: user_id=$userId, phone=$phone');
  }

  // Удаление сессии
  Future<void> _deleteSession() async {
    if (_sessionId != null) {
      try {
        // Используем строку напрямую (UUID не нужно преобразовывать в int)
        await supabase.from('auth_sessions').delete().eq('id', _sessionId!);
        print('Сессия $_sessionId удалена');
      } catch (e) {
        print('Error deleting session: $e');
      }
    }
  }

  // Удаление просроченной сессии
  Future<void> _deleteExpiredSession() async {
    if (_sessionId != null) {
      try {
        await supabase.from('auth_sessions').delete().eq('id', _sessionId!);
        print('Просроченная сессия $_sessionId удалена');
      } catch (e) {
        print('Error deleting expired session: $e');
      }
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _listener.dispose(); // Обязательно удалите слушателя
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Авторизация')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.telegram, size: 100, color: Colors.blue),
            SizedBox(height: 30),
            Text(
              'Вход через Telegram',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Нажмите кнопку ниже для быстрой авторизации'),
            SizedBox(height: 30),
            if (_isLoading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Открываю Telegram...'),
              SizedBox(height: 10),
              Text(
                '1. Нажмите "START" в Telegram\n'
                '2. Нажмите кнопку отправки номера',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: _startSessionCheck,
                child: Text('Проверить статус'),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _createAuthSession,
                icon: Icon(Icons.telegram),
                label: Text('Войти через Telegram'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                // Для отладки: проверка Deep Link
                final testLink = 'https://t.me/Lukamorie_menu_bot?start=123';
                if (await canLaunchUrl(Uri.parse(testLink))) {
                  print('Telegram доступен');
                } else {
                  print('Telegram НЕ доступен');
                }
              },
              child: Text('Проверить доступность Telegram'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Главная'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final prefs = snapshot.data as SharedPreferences;
              final phone = prefs.getString('phone') ?? 'не указан';
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 100, color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    'Вы успешно авторизованы!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text('Ваш телефон: $phone'),
                ],
              );
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

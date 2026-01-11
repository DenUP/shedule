// core/network/updatechecker.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static final String repoOwner = 'DenUP';
  static final String repoName = 'shedule';
  
  static Future<String> getCurrentVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('Ошибка получения версии приложения: $e');
      return '0.0.0';
    }
  }
  
  static Future<String?> getLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tag_name'];
      } else {
        print('GitHub API ответил с кодом: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при проверке обновлений: $e');
    }
    return null;
  }
  
  static bool isUpdateAvailable(String current, String latest) {
    try {
      // Убираем "v" из тега версии
      String cleanLatest = latest.replaceFirst(RegExp(r'^v'), '');
      
      List<String> currentParts = current.split('.');
      List<String> latestParts = cleanLatest.split('.');
      
      // Сравниваем по частям
      for (int i = 0; i < latestParts.length; i++) {
        int currentNum = (i < currentParts.length) ? int.parse(currentParts[i]) : 0;
        int latestNum = int.parse(latestParts[i]);
        
        if (latestNum > currentNum) return true;
        if (latestNum < currentNum) return false;
      }
      return false;
    } catch (e) {
      print('Ошибка сравнения версий: $e');
      return false;
    }
  }
  
  static Future<void> showUpdateDialog(BuildContext context) async {
    try {
      String currentVersion = await getCurrentVersion();
      print('Текущая версия: $currentVersion');
      
      String? latestVersion = await getLatestVersion();
      print('Последняя версия в GitHub: $latestVersion');
      
      if (latestVersion == null) {
        print('Не удалось получить информацию о версии');
        return;
      }
      
      if (isUpdateAvailable(currentVersion, latestVersion)) {
        print('Доступно обновление!');
        
        // Показываем диалог
        if (!context.mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Доступно обновление! 🎉'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Текущая версия: $currentVersion'),
                  Text('Новая версия: $latestVersion'),
                  const SizedBox(height: 16),
                  const Text('Рекомендуем обновиться для получения новых функций и исправлений.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Позже'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _openReleasesPage();
                  },
                  child: const Text('Обновить'),
                ),
              ],
            );
          },
        );
      } else {
        print('Обновление не требуется');
      }
    } catch (e) {
      print('Ошибка при показе диалога обновления: $e');
    }
  }
  
  static Future<void> _openReleasesPage() async {
    final url = Uri.parse('https://github.com/$repoOwner/$repoName/releases/latest');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Не удалось открыть ссылку: $url');
    }
  }
}
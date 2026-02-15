import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_local_data_source.dart';
import 'package:shedule_test/features/shedule/domain/entity/group.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';

class SheduleLocalDataSourceImpl implements SheduleLocalDataSource {
  final SharedPreferences sharedPreferences;
  final Map<String, List<Shedule>> _memoryCache = {};

  SheduleLocalDataSourceImpl({required this.sharedPreferences});

  final _keyLocal = 'keyLocal';
  final _keyGroup = 'selected_group';
  final _keyGroupsList = 'groups_list'; // Ключ для сохранения списка групп
  final _keyGroupsTimestamp = 'groups_timestamp'; // Время последнего обновления

  // Сохранение выбранной группы
  @override
  Future<void> saveSelectedGroup(String group) async {
    await sharedPreferences.setString(_keyGroup, group);
  }

  @override
  String? getSelectedGroup() {
    return sharedPreferences.getString(_keyGroup);
  }

  @override
  Future<void> clearSelectedGroup() async {
    await sharedPreferences.remove(_keyGroup);
  }

  // Сохранение и получение списка групп
  @override
  Future<List<Group>> getGroupsList() async {
    final jsonString = sharedPreferences.getString(_keyGroupsList);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Group.fromJson(e)).toList();
  }

  @override
  Future<void> saveGroupsList(List<Group> groups) async {
    final jsonList = groups.map((group) => group.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(_keyGroupsList, jsonString);
    await sharedPreferences.setString(
      _keyGroupsTimestamp,
      DateTime.now().toIso8601String(),
    );
  }

  // Проверка, нужно ли обновлять список групп (например, раз в день)
  Future<bool> shouldRefreshGroups() async {
    final timestamp = sharedPreferences.getString(_keyGroupsTimestamp);
    if (timestamp == null) return true;

    final lastUpdate = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    // Обновляем раз в день
    return difference.inHours > 24;
  }

  // Очистка кэша групп
  Future<void> clearGroupsCache() async {
    await sharedPreferences.remove(_keyGroupsList);
    await sharedPreferences.remove(_keyGroupsTimestamp);
  }

  // Существующие методы для расписания
  @override
  List<Shedule>? getCache(String parity) {
    // Сначала проверяем память
    if (_memoryCache.containsKey(parity)) {
      return _memoryCache[parity];
    }
    final data = sharedPreferences.getStringList("${_keyLocal}_$parity");
    if (data == null) return null;
    final result = data.map((e) => Shedule.fromJson(json.decode(e))).toList();
    _memoryCache[parity] = result;
    return result;
  }

  @override
  Future<bool> saveCache(String parity, List<Shedule> shedule) async {
    _memoryCache[parity] = shedule;
    final data = shedule.map((e) => json.encode(e.toJson())).toList();
    final shared = await sharedPreferences.setStringList(
      "${_keyLocal}_$parity",
      data,
    );
    return shared;
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove("${_keyLocal}_even");
    await sharedPreferences.remove("${_keyLocal}_odd");
  }
}

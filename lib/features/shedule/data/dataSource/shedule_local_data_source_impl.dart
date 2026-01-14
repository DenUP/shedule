import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shedule_test/features/shedule/domain/dataSource/shedule_local_data_source.dart';
import 'package:shedule_test/features/shedule/domain/entity/group.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';

class SheduleLocalDataSourceImpl implements SheduleLocalDataSource {
  final SharedPreferences sharedPreferences;

  SheduleLocalDataSourceImpl({required this.sharedPreferences});

  final _keyLocal = 'keyLocal';

  final _keyGroup = 'selected_group';

  // Существующие методы getCache, saveCache, clearCache ...
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

  @override
  List<Shedule>? getCache(String parity) {
    final data = sharedPreferences.getStringList("${_keyLocal}_$parity");
    if (data == null || data.isEmpty) return null;
    final response = data.map((e) => Shedule.fromJson(json.decode(e))).toList();
    return response;
  }

  @override
  Future<bool> saveCache(String parity, List<Shedule> shedule) async {
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

  @override
  Future<List<Group>> getGroupsList() {
    // TODO: implement getGroupsList
    throw UnimplementedError();
  }

  @override
  Future<void> saveGroupsList(List<Group> groups) {
    // TODO: implement saveGroupsList
    throw UnimplementedError();
  }
}

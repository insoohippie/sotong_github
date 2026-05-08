import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../model/setting/past_plan_snapshot.dart';


/// 지난 플랜 스냅샷 목록을 Hive에 저장/로드.
class PastPlanRepository {
  PastPlanRepository() : _box = Hive.box('past_plans');

  final Box _box;
  static const String _keyList = 'list';

  List<PastPlanSnapshot> load() {
    final raw = _box.get(_keyList);
    if (raw == null) return [];
    if (raw is! String) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>? ?? [];
      return list
          .map(
            (e) =>
                PastPlanSnapshot.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<PastPlanSnapshot> list) async {
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await _box.put(_keyList, encoded);
  }

  Future<void> add(PastPlanSnapshot snapshot) async {
    final list = load();
    list.add(snapshot);
    await save(list);
  }
}

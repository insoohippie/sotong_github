import 'package:hive_flutter/hive_flutter.dart';

/// 종료일 자동 연장 통보 팝업 "봤음" 기록.
///
/// 키에 새 종료일을 포함하므로 같은 연장에 대해서는 1회만 표시되고,
/// 재연장(종료일이 또 바뀜)이 일어나면 새 키라 다시 표시된다.
class PlanExtensionNoticeStorage {
  PlanExtensionNoticeStorage._();

  static final PlanExtensionNoticeStorage instance =
      PlanExtensionNoticeStorage._();

  static const String _boxName = 'auth_cache';
  static const String _keyPrefix = 'planExtensionNoticeShown';

  Box get _box => Hive.box(_boxName);

  String _key({
    required String uid,
    required String planId,
    required DateTime newEnd,
  }) {
    final d = DateTime(newEnd.year, newEnd.month, newEnd.day);
    return '$_keyPrefix:$uid:$planId:${d.toIso8601String()}';
  }

  bool hasShown({
    required String uid,
    required String planId,
    required DateTime newEnd,
  }) {
    return _box.get(
      _key(uid: uid, planId: planId, newEnd: newEnd),
      defaultValue: false,
    ) as bool;
  }

  Future<void> markShown({
    required String uid,
    required String planId,
    required DateTime newEnd,
  }) async {
    await _box.put(_key(uid: uid, planId: planId, newEnd: newEnd), true);
  }
}

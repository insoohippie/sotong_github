import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// 플랜 완료(목표 금액 달성) 상태 저장소.
///
/// 완료된 플랜의 planId를 기억해, 해당 플랜이 활성 플랜인 동안
/// 홈 대신 축하 화면(celebration)만 보이도록 잠그는 데 사용한다.
/// 새 플랜이 생성되면 planId가 달라지므로 잠금은 자동 해제된다.
class PlanCelebrationStorage {
  PlanCelebrationStorage._();

  static final PlanCelebrationStorage instance = PlanCelebrationStorage._();

  static const String _boxName = 'auth_cache';
  static const String _keyPrefix = 'planCompleted';

  Box get _box => Hive.box(_boxName);

  String _key(String uid) => '$_keyPrefix:$uid';

  /// 완료 정보: {planId, planName, daysTaken, completedAt} 또는 null
  Map<String, dynamic>? completedInfo({required String uid}) {
    final raw = _box.get(_key(uid));
    if (raw is! String) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// 현재 활성 플랜이 완료 상태인지 (planId 일치 여부로 판정)
  bool isPlanCompleted({required String uid, required String planId}) {
    if (planId.isEmpty) return false;
    final info = completedInfo(uid: uid);
    return info != null && info['planId'] == planId;
  }

  Future<void> markCompleted({
    required String uid,
    required String planId,
    required String planName,
    required int daysTaken,
    required DateTime completedAt,
  }) async {
    await _box.put(
      _key(uid),
      jsonEncode({
        'planId': planId,
        'planName': planName,
        'daysTaken': daysTaken,
        'completedAt': completedAt.toIso8601String(),
      }),
    );
  }
}

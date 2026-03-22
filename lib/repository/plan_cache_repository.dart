import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../model/plan/total_plan.dart';
import '../model/refData/ref_data.dart';

class PlanRecordCache {
  const PlanRecordCache({this.payload = const {}});

  final Map<String, dynamic> payload;

  factory PlanRecordCache.fromMap(Map<String, dynamic> map) {
    return PlanRecordCache(payload: Map<String, dynamic>.from(map));
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(payload);
}

class PlanCacheSnapshot {
  const PlanCacheSnapshot({
    required this.plan,
    required this.refData,
    this.recordCache = const PlanRecordCache(),
  });

  final TotalPlan plan;
  final RefData refData;
  final PlanRecordCache recordCache;

  Map<String, dynamic> toMap() {
    return {
      'plan': {
        ...plan.toMap(),
        'planId': plan.planId,
      },
      'refData': refData.toMap(),
      'recordCache': recordCache.toMap(),
    };
  }

  factory PlanCacheSnapshot.fromMap(Map<String, dynamic> map) {
    final planPayload = Map<String, dynamic>.from(map['plan'] as Map);
    final planId = planPayload['planId'] as String? ?? '';
    planPayload.remove('planId');
    final plan = TotalPlan.fromMap(planId, planPayload);
    final refData =
        RefData.fromMap(Map<String, dynamic>.from(map['refData'] as Map));
    final recordRaw = map['recordCache'];
    final recordCache = recordRaw is Map
        ? PlanRecordCache.fromMap(Map<String, dynamic>.from(recordRaw))
        : const PlanRecordCache();
    return PlanCacheSnapshot(
      plan: plan,
      refData: refData,
      recordCache: recordCache,
    );
  }
}

class PlanCacheRepository {
  PlanCacheRepository() : _box = Hive.box('plan_cache');

  final Box _box;

  Future<void> saveSnapshot({
    required String uid,
    required PlanCacheSnapshot snapshot,
  }) async {
    await _box.put(uid, jsonEncode(snapshot.toMap()));
  }

  PlanCacheSnapshot? loadSnapshot(String uid) {
    final raw = _box.get(uid);
    if (raw == null) return null;
    try {
      final map = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);
      return PlanCacheSnapshot.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSnapshot(String uid) async {
    await _box.delete(uid);
  }
}

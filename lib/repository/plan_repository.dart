// repository/plan_repository.dart
import '../data_source/plan_data_source.dart';
import '../data_source/auth_data_source.dart';
import '../model/plan_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanRepository {
  final PlanDataSource _ds;
  final AuthDataSource _auth;
  PlanRepository(this._ds, this._auth);

  String _uidOrThrow() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('로그인이 필요합니다.');
    return uid;
  }

  /// 저장
  Future<String> saveCurrentUserPlan(PlanInfo plan) async {
    final uid = _uidOrThrow();
    final now = FieldValue.serverTimestamp();
    final data = {
      ...plan.toMap(),
      'createdAt': now,
      'updatedAt': now,
    };
    final id = await _ds.create(uid, data);
    return id;
  }

  /// 전체 플랜(최신순)
  Future<List<PlanInfo>> getUserPlans() async {
    final uid = _uidOrThrow();
    final snaps = await _ds.query(uid, orderBy: 'createdAt', descending: true);
    return snaps.docs.map((d) => PlanInfo.fromMap(d.data())).toList();
  }

  /// 최신 플랜 1개
  Future<PlanInfo?> getLatestPlanForCurrentUser() async {
    final uid = _uidOrThrow();
    final snaps = await _ds.query(uid, orderBy: 'createdAt', descending: true, limit: 1);
    if (snaps.docs.isEmpty) return null;
    return PlanInfo.fromMap(snaps.docs.first.data());
  }

  /// 특정 플랜 이름만 수정
  Future<void> updatePlanNameById(String planId, String newName) async {
    final uid = _uidOrThrow();
    await _ds.updateFields(uid, planId, {
      'planName': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 최신 플랜 이름만 수정(편의 함수)
  Future<void> updateLatestPlanName(String newName) async {
    final uid = _uidOrThrow();
    final snaps = await _ds.query(uid, orderBy: 'createdAt', descending: true, limit: 1);
    if (snaps.docs.isEmpty) throw Exception('수정할 플랜이 없습니다.');
    final planId = snaps.docs.first.id;
    await updatePlanNameById(planId, newName);
  }

  /// 부분 업데이트(PlanInfo -> Map으로 변환해 patch)
  Future<void> updatePlan(String planId, PlanInfo patch) async {
    final uid = _uidOrThrow();
    await _ds.updateFields(uid, planId, {
      ...patch.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlan(String planId) async {
    final uid = _uidOrThrow();
    await _ds.delete(uid, planId);
  }
}

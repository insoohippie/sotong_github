// repository/plan_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data_source/auth_data_source.dart';
import '../data_source/plan_data_source.dart';
import '../model/plan/total_plan.dart';

class PlanRepository {
  PlanRepository(this._ds, this._auth);

  final PlanDataSource _ds;
  final AuthDataSource _auth;

  String _uidOrThrow() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('로그인이 필요합니다.');
    return uid;
  }

  /// 저장
  Future<String> saveCurrentUserPlan(TotalPlan plan) async {
    final uid = _uidOrThrow();
    final now = FieldValue.serverTimestamp();
    final data = {
      ...plan.toMap(),
      'planId': plan.planId,
      'createdAt': now,
      'updatedAt': now,
    };
    final id = await _ds.create(uid, data);
    return id;
  }

  /// 전체 플랜(최신순)
  Future<List<TotalPlan>> getUserPlans() async {
    final uid = _uidOrThrow();
    final snaps = await _ds.query(uid, orderBy: 'createdAt', descending: true);
    return snaps.docs.map(_mapDocToTotalPlan).toList();
  }

  /// 최신 플랜 1개
  Future<TotalPlan?> getLatestPlanForCurrentUser() async {
    final uid = _uidOrThrow();
    final snaps = await _ds.query(uid, orderBy: 'createdAt', descending: true, limit: 1);
    if (snaps.docs.isEmpty) return null;
    return _mapDocToTotalPlan(snaps.docs.first);
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

  /// 부분 업데이트(TotalPlan -> Map으로 변환해 patch)
  Future<void> updatePlan(String planId, TotalPlan patch) async {
    final uid = _uidOrThrow();
    await _ds.updateFields(uid, planId, {
      ...patch.toMap(),
      'planId': patch.planId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlan(String planId) async {
    final uid = _uidOrThrow();
    await _ds.delete(uid, planId);
  }

  TotalPlan _mapDocToTotalPlan(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TotalPlan.fromMap(doc.id, doc.data());
  }
}

// data_source/plan_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('plans');

  /// 생성(문서 ID 자동)
  Future<String> create(String uid, Map<String, dynamic> data) async {
    try {
      print('=== PlanDataSource.create 시작 ===');
      print('UID: $uid');
      print('데이터: $data');
      final docRef = _col(uid).doc();
      print('문서 참조 생성됨: ${docRef.path}');
      await docRef.set(data);
      print('=== PlanDataSource 저장 성공, ID: ${docRef.id} ===');
      return docRef.id;
    } catch (e, stackTrace) {
      print('=== PlanDataSource 저장 실패 ===');
      print('오류: $e');
      print('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 읽기(리스트) - 정렬/limit 등은 호출부에서 지정
  Future<QuerySnapshot<Map<String, dynamic>>> query(
    String uid, {
    String orderBy = 'createdAt',
    bool descending = true,
    int? limit,
  }) {
    Query<Map<String, dynamic>> q = _col(
      uid,
    ).orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.get();
  }

  /// 단건 읽기
  Future<DocumentSnapshot<Map<String, dynamic>>> getById(
    String uid,
    String planId,
  ) {
    return _col(uid).doc(planId).get();
  }

  /// 부분 업데이트
  Future<void> updateFields(
    String uid,
    String planId,
    Map<String, dynamic> patch,
  ) {
    return _col(uid).doc(planId).update(patch);
  }

  /// 삭제
  Future<void> delete(String uid, String planId) {
    return _col(uid).doc(planId).delete();
  }
}

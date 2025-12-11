// data_source/plan_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('plans');

  /// 생성(문서 ID 자동)
  Future<String> create(String uid, Map<String, dynamic> data) async {
    final docRef = _col(uid).doc();
    final payload = Map<String, dynamic>.from(data)..['planId'] = docRef.id;
    await docRef.set(payload);
    return docRef.id;
  }

  /// 통째로 덮어쓰기
  Future<void> replace(String uid, String planId, Map<String, dynamic> data) {
    return _col(uid).doc(planId).set(data);
  }


  /// 읽기(리스트) - 정렬/limit 등은 호출부에서 지정
  Future<QuerySnapshot<Map<String, dynamic>>> query(
      String uid, {
        String orderBy = 'createdAt',
        bool descending = true,
        int? limit,
      }) {
    Query<Map<String, dynamic>> q = _col(uid).orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.get();
  }

  /// 단건 읽기
  Future<DocumentSnapshot<Map<String, dynamic>>> getById(String uid, String planId) {
    return _col(uid).doc(planId).get();
  }

  /// 부분 업데이트
  Future<void> updateFields(String uid, String planId, Map<String, dynamic> patch) {
    return _col(uid).doc(planId).update(patch);
  }

  /// 삭제
  Future<void> delete(String uid, String planId) {
    return _col(uid).doc(planId).delete();
  }
}

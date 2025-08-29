import 'package:cloud_firestore/cloud_firestore.dart';

class CommunicationDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('emotion_diary');

  /// 월 범위 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> streamByDateRange(
      String uid, {
        required DateTime start,
        required DateTime end,
      }) {
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: false)
        .snapshots();
  }

  /// 일(day) 범위 단건 조회 (있으면 최대 1건)
  Future<QuerySnapshot<Map<String, dynamic>>> queryByDay(
      String uid, {
        required DateTime dayStart,
        required DateTime dayEnd,
      }) {
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .limit(1)
        .get();
  }

  /// 생성
  Future<String> add(String uid, Map<String, dynamic> data) async {
    final ref = _col(uid).doc();
    await ref.set(data);
    return ref.id;
  }

  /// 업데이트
  Future<void> update(String uid, String docId, Map<String, dynamic> patch) {
    return _col(uid).doc(docId).update(patch);
  }

  /// 삭제
  Future<void> delete(String uid, String docId) {
    return _col(uid).doc(docId).delete();
  }
}

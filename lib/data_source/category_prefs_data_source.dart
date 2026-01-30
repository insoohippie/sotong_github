import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryPrefsDataSource {
  CategoryPrefsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------- planMeta (기간분기, 여러 문서) ----------
  CollectionReference<Map<String, dynamic>> planMetaCol(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('categoryPrefs');
  }

  /// 날짜 day를 커버하는 "현재 활성" planMeta 1개 조회
  Future<QuerySnapshot<Map<String, dynamic>>> queryPlanMetaForDate({
    required String uid,
    required Timestamp day,
  }) {
    return planMetaCol(uid)
        .where('isActive', isEqualTo: true)
        .where('applyDate', isLessThanOrEqualTo: day)
        .orderBy('applyDate', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPlanMetaDoc({
    required String uid,
    required String docId,
  }) {
    return planMetaCol(uid).doc(docId).get();
  }

  Future<void> setPlanMetaDoc({
    required String uid,
    required String docId,
    required Map<String, dynamic> data,
    SetOptions? options,
  }) {
    return planMetaCol(uid).doc(docId).set(
      data,
      options ?? SetOptions(merge: true),
    );
  }

  // ---------- refPrefs (즉시, 단일 doc) ----------
  DocumentReference<Map<String, dynamic>> refPrefsDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('categoryPrefsRef')
        .doc('_root');
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getRefPrefs({
    required String uid,
  }) {
    return refPrefsDoc(uid).get();
  }

  Future<void> setRefPrefs({
    required String uid,
    required Map<String, dynamic> data,
    SetOptions? options,
  }) {
    return refPrefsDoc(uid).set(
      data,
      options ?? SetOptions(merge: true),
    );
  }

  Future<T> runTransaction<T>(TransactionHandler<T> handler) {
    return _firestore.runTransaction<T>(handler);
  }
}

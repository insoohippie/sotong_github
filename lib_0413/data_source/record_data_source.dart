import 'package:cloud_firestore/cloud_firestore.dart';

class RecordDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// users/{uid}/records/{yyyy-MM} 문서 가져오기
  Future<DocumentSnapshot<Map<String, dynamic>>> getMonthlyDoc(
      String uid,
      String monthKey,
      ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('records')
        .doc(monthKey)
        .get();
  }

  /// users/{uid}/records/{yyyy-MM} 문서 저장
  Future<void> setMonthlyDoc(
      String uid,
      String monthKey,
      Map<String, dynamic> data, {
        bool merge = true,
      }) {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('records')
        .doc(monthKey);

    return merge ? ref.set(data, SetOptions(merge: true)) : ref.set(data);
  }

  // records 컬렉션의 문서 목록 가져오기
  Future<QuerySnapshot<Map<String, dynamic>>> listMonthlyDocs(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('records')
        .get();
  }

  // 월 문서 1개 삭제
  Future<void> deleteMonthlyDoc(String uid, String monthKey) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('records')
        .doc(monthKey)
        .delete();
  }
}

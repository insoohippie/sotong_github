import 'package:cloud_firestore/cloud_firestore.dart';

class RefCategoryDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// users/{uid}/refCategories/{docId}
  DocumentReference<Map<String, dynamic>> _doc(String uid, String docId) {
    return _firestore.collection('users').doc(uid).collection('refCategories').doc(docId);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getRefDoc(String uid, String docId) {
    return _doc(uid, docId).get();
  }

  Future<void> setRefDoc(
      String uid,
      String docId,
      Map<String, dynamic> data, {
        bool merge = true,
      }) {
    final ref = _doc(uid, docId);
    return merge ? ref.set(data, SetOptions(merge: true)) : ref.set(data);
  }
}

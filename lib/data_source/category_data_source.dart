// lib/data_source/category_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('categories')
        .doc('categoryList');
  }

  Future<Map<String, dynamic>?> getCategoryDoc(String uid) async {
    final doc = await _docRef(uid).get();
    return doc.data();
  }

  Future<void> setCategoryDoc(String uid, Map<String, dynamic> data) async {
    await _docRef(uid).set(data, SetOptions(merge: false));
  }

  Future<void> deleteCategoryDoc(String uid) async {
    await _docRef(uid).delete();
  }
}
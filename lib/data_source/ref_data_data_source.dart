import 'package:cloud_firestore/cloud_firestore.dart';

/// Low level accessors for refData subcollections under a user.
class RefDataDataSource {
  RefDataDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _baseDocument(String uid) {
    // We keep the alternating collection/document structure by inserting a
    // fixed anchor document named `_root`.
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('refData')
        .doc('_root');
  }

  CollectionReference<Map<String, dynamic>> _monthlyIncomeCol(String uid) {
    return _baseDocument(uid).collection('monthlyIncome');
  }

  CollectionReference<Map<String, dynamic>> _monthlyConsumeCol(String uid) {
    return _baseDocument(uid).collection('monthlyConsume');
  }

  CollectionReference<Map<String, dynamic>> _dailyConsumeCol(String uid) {
    return _baseDocument(uid).collection('dailyConsume');
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchMonthlyIncomes(
      String uid) async {
    final snap = await _monthlyIncomeCol(uid).get();
    return snap.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchMonthlyConsumes(
      String uid) async {
    final snap = await _monthlyConsumeCol(uid).get();
    return snap.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchDailyConsumes(
      String uid) async {
    final snap = await _dailyConsumeCol(uid).get();
    return snap.docs;
  }

  Future<void> upsertMonthlyIncome(
      String uid, String docId, Map<String, dynamic> data) {
    return _monthlyIncomeCol(uid).doc(docId).set(data);
  }

  Future<void> upsertMonthlyConsume(
      String uid, String docId, Map<String, dynamic> data) {
    return _monthlyConsumeCol(uid).doc(docId).set(data);
  }

  Future<void> upsertDailyConsume(
      String uid, String docId, Map<String, dynamic> data) {
    return _dailyConsumeCol(uid).doc(docId).set(data);
  }

  Future<void> deleteMonthlyIncome(String uid, String docId) {
    return _monthlyIncomeCol(uid).doc(docId).delete();
  }

  Future<void> deleteMonthlyConsume(String uid, String docId) {
    return _monthlyConsumeCol(uid).doc(docId).delete();
  }

  Future<void> deleteDailyConsume(String uid, String docId) {
    return _dailyConsumeCol(uid).doc(docId).delete();
  }
}
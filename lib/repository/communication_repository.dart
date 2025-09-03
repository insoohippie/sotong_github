import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/emotion_spending_diary.dart';

class CommunicationRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CommunicationRepository(this._db, this._auth);

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('diary');

  // 특정 날짜 범위 가져오기 (하루/주/월 단위로 재사용)
  Future<List<EmotionSpendingDiary>> fetchRange(DateTime from, DateTime to) async {
    final qs = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .get();

    return qs.docs.map((d) => EmotionSpendingDiary.fromMap(d.data())).toList();
  }

  // 실시간 스트림 (원하면 Home에서 StreamBuilder로도 사용 가능)
  Stream<List<EmotionSpendingDiary>> streamRange(DateTime from, DateTime to) {
    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EmotionSpendingDiary.fromMap(d.data())).toList());
  }
}

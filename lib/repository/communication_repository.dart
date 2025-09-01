import 'package:cloud_firestore/cloud_firestore.dart';

import '../data_source/communication_data_source.dart';
import '../data_source/auth_data_source.dart';
import '../model/emotion_spending_diary.dart';

class CommunicationRepository {
  final CommunicationDataSource _ds;
  final AuthDataSource _auth;

  CommunicationRepository(this._ds, this._auth);

  String _uidOrThrow() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('로그인이 필요합니다.');
    return uid;
  }

  /// 월 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMonth(DateTime anchor) {
    final uid = _uidOrThrow();
    final start = DateTime(anchor.year, anchor.month, 1);
    final end = DateTime(anchor.year, anchor.month + 1, 1);
    return _ds.streamByDateRange(uid, start: start, end: end);
  }

  /// 같은 ‘날짜(연-월-일)’ 문서가 있으면 업데이트, 없으면 추가
  Future<void> upsertEntry(EmotionSpendingDiary entry) async {
    final uid = _uidOrThrow();
    final dayStart = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final exist = await _ds.queryByDay(uid, dayStart: dayStart, dayEnd: dayEnd);
    final map = _toMap(entry);

    if (exist.docs.isNotEmpty) {
      await _ds.update(uid, exist.docs.first.id, map);
    } else {
      await _ds.add(uid, map);
    }
  }

  Future<void> addEntry(EmotionSpendingDiary entry) async {
    final uid = _uidOrThrow();
    await _ds.add(uid, _toMap(entry));
  }

  Future<void> deleteEntry(String docId) async {
    final uid = _uidOrThrow();
    await _ds.delete(uid, docId);
  }

  // ---------- Mapper ----------
  Map<String, dynamic> _toMap(EmotionSpendingDiary e) => {
    'date': Timestamp.fromDate(e.date),
    'emotion': e.emotion,
    'emotionAnimation': e.emotionAnimation,
    'spendingAmount': e.spendingAmount,
    'spendingDescription': e.spendingDescription,
    'memo': e.memo,
  };

  EmotionSpendingDiary? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data();
      if (d == null) return null;
      final ts = d['date'] as Timestamp?;
      return EmotionSpendingDiary(
        date: (ts?.toDate()) ?? DateTime.now(),
        emotion: (d['emotion'] ?? '') as String,
        emotionAnimation: (d['emotionAnimation'] ?? '') as String,
        spendingAmount: (d['spendingAmount'] ?? 0).toDouble(),
        spendingDescription: (d['spendingDescription'] ?? '') as String,
        memo: (d['memo'] ?? '') as String,
      );
    } catch (_) {
      return null;
    }
  }
}

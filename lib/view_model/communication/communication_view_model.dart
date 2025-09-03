import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/emotion_spending_diary.dart';

/// Firestore 스키마 가정:
/// users/{uid}/emotion_diary (subcollection)
///  - id: doc id (자동)
///  - date: Timestamp (해당 기록의 실제 날짜/시간)
///  - spendingAmount: num
///  - spendingDescription: string
///  - memo: string
///  - emotion: string
///  - emotionAnimation: string
///
/// *월 단위 로딩: loadMonth(anchor) 호출
/// *카렌더 표시: byDay (Map<DateOnly -> List<Entry>>)
/// *특정 날짜 첫 엔트리: firstEntryFor(date)
class CommunicationViewModel extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CommunicationViewModel({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 날짜(연-월-일 자정 기준) -> 해당 날짜 엔트리 목록
  Map<DateTime, List<EmotionSpendingDiary>> _byDay = {};
  Map<DateTime, List<EmotionSpendingDiary>> get byDay => _byDay;

  /// 현재 월의 실시간 구독
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// 월(anchor) 기준으로 [해당 월 1일 00:00, 다음 달 1일 00:00) 범위를 구독/로드
  Future<void> loadMonth(DateTime anchor) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('로그인이 필요합니다.');
      return;
    }

    // 기존 구독 해제
    await _sub?.cancel();
    _setLoading(true);

    try {
      final monthStart = DateTime(anchor.year, anchor.month, 1);
      final monthEnd = DateTime(anchor.year, anchor.month + 1, 1);

      final query = _db
          .collection('users')
          .doc(user.uid)
          .collection('emotion_diary')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('date', isLessThan: Timestamp.fromDate(monthEnd))
          .orderBy('date', descending: false);

      _sub = query.snapshots().listen((snap) {
        final items = snap.docs.map(_fromDoc).whereType<EmotionSpendingDiary>().toList();
        _rebuildByDay(items);
      }, onError: (e) {
        _setError('데이터 구독 중 오류가 발생했어요: $e');
      });

      _setError(null);
    } catch (e) {
      _setError('데이터 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 해당 날짜(연-월-일)의 총 지출액(여러 건이면 합계)
  double spendingFor(DateTime date) {
    final key = _dateOnly(date);
    final list = _byDay[key];
    if (list == null || list.isEmpty) return 0.0;
    return list.fold<double>(0.0, (sum, e) => sum + e.spendingAmount);
  }

  /// 해당 날짜의 첫 번째 기록 금액(예전처럼 단일 기록만 쓰고 싶을 때)
  double firstSpendingFor(DateTime date) {
    final key = _dateOnly(date);
    final list = _byDay[key];
    if (list == null || list.isEmpty) return 0.0;
    return list.first.spendingAmount;
  }

  /// 특정 날짜(연-월-일 기준)의 첫 엔트리를 반환 (없으면 null)
  EmotionSpendingDiary? firstEntryFor(DateTime date) {
    final key = _dateOnly(date);
    final list = _byDay[key];
    if (list == null || list.isEmpty) return null;
    return list.first;
    // 필요하면 정렬 기준 변경 가능 (예: 시간 오름차순)
  }

  /// 엔트리 추가/교체 (같은 날의 기존 것을 덮어쓰기 원한다면 이 메서드 사용)
  Future<void> upsertEntry(EmotionSpendingDiary entry) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('로그인이 필요합니다.');
      return;
    }

    try {
      // 같은 "날짜(연-월-일)"에 이미 문서가 있으면 교체, 없으면 새로 생성
      final dayKey = _dateOnly(entry.date);
      final dayStart = dayKey;
      final dayEnd = dayKey.add(const Duration(days: 1));

      final col = _db.collection('users').doc(user.uid).collection('emotion_diary');
      final existing = await col
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('date', isLessThan: Timestamp.fromDate(dayEnd))
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // update
        await existing.docs.first.reference.update(_toMap(entry));
      } else {
        // add
        await col.add(_toMap(entry));
      }
    } catch (e) {
      _setError('저장 실패: $e');
    }
  }

  /// 단순 추가 (중복 허용)
  Future<void> addEntry(EmotionSpendingDiary entry) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('로그인이 필요합니다.');
      return;
    }
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('emotion_diary')
          .add(_toMap(entry));
    } catch (e) {
      _setError('추가 실패: $e');
    }
  }

  /// 삭제
  Future<void> deleteEntry(String docId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('로그인이 필요합니다.');
      return;
    }
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('emotion_diary')
          .doc(docId)
          .delete();
    } catch (e) {
      _setError('삭제 실패: $e');
    }
  }

  /// 내부 상태 업데이트
  void _rebuildByDay(List<EmotionSpendingDiary> items) {
    final map = <DateTime, List<EmotionSpendingDiary>>{};
    for (final it in items) {
      final key = _dateOnly(it.date);
      map.putIfAbsent(key, () => []).add(it);
    }

    // 같은 날 여러 개면 시간순 정렬(오름차순)
    map.forEach((_, list) {
      list.sort((a, b) => a.date.compareTo(b.date));
    });

    _byDay = map;
    notifyListeners();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  EmotionSpendingDiary? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      if (data == null) return null;

      final ts = data['date'] as Timestamp?;
      final date = ts?.toDate() ?? DateTime.now();

      return EmotionSpendingDiary(
        date: date,
        emotion: (data['emotion'] ?? '') as String,
        emotionAnimation: (data['emotionAnimation'] ?? '') as String,
        spendingAmount: (data['spendingAmount'] ?? 0).toDouble(),
        spendingDescription: (data['spendingDescription'] ?? '') as String,
        memo: (data['memo'] ?? '') as String,
      );
    } catch (e) {
      if (kDebugMode) {
        print('fromDoc parse error: $e');
      }
      return null;
    }
  }

  Map<String, dynamic> _toMap(EmotionSpendingDiary e) {
    return {
      'date': Timestamp.fromDate(e.date),
      'emotion': e.emotion,
      'emotionAnimation': e.emotionAnimation,
      'spendingAmount': e.spendingAmount,
      'spendingDescription': e.spendingDescription,
      'memo': e.memo,
    };
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

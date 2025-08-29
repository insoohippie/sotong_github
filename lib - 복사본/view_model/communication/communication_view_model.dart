import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/emotion_spending_diary.dart';
import '../../repository/communication_repository.dart';

class CommunicationViewModel extends ChangeNotifier {
  final CommunicationRepository _repo;
  CommunicationViewModel(this._repo);

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 날짜(연-월-일) -> 그 날의 기록 리스트
  Map<DateTime, List<EmotionSpendingDiary>> _byDay = {};
  Map<DateTime, List<EmotionSpendingDiary>> get byDay => _byDay;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  Future<void> loadMonth(DateTime anchor) async {
    await _sub?.cancel();
    _setLoading(true);
    try {
      _sub = _repo.streamMonth(anchor).listen((snap) {
        final items = snap.docs
            .map(_repo.fromDoc)
            .whereType<EmotionSpendingDiary>()
            .toList();
        _rebuildByDay(items);
        _setError(null);
      }, onError: (e) {
        _setError('데이터 구독 중 오류가 발생했어요: $e');
      });
    } catch (e) {
      _setError('데이터 로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  double spendingFor(DateTime date) {
    final key = _dateOnly(date);
    final list = _byDay[key];
    if (list == null || list.isEmpty) return 0.0;
    return list.fold<double>(0.0, (sum, e) => sum + e.spendingAmount);
  }

  EmotionSpendingDiary? firstEntryFor(DateTime date) {
    final key = _dateOnly(date);
    final list = _byDay[key];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  Future<void> upsertEntry(EmotionSpendingDiary entry) => _repo.upsertEntry(entry);
  Future<void> addEntry(EmotionSpendingDiary entry) => _repo.addEntry(entry);
  Future<void> deleteEntry(String docId) => _repo.deleteEntry(docId);

  // ---------- internal ----------
  void _rebuildByDay(List<EmotionSpendingDiary> items) {
    final map = <DateTime, List<EmotionSpendingDiary>>{};
    for (final it in items) {
      final key = _dateOnly(it.date);
      map.putIfAbsent(key, () => []).add(it);
    }
    map.forEach((_, list) => list.sort((a, b) => a.date.compareTo(b.date)));
    _byDay = map;
    notifyListeners();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

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

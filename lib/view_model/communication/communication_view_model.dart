import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/emotion_spending_diary.dart';
import '../../repository/communication_repository.dart';

/// 한 달 감정 요약 결과
class MonthlyEmotionSummary {
  final int happyDays;
  final int normalDays;
  final int gloomyDays;
  final String overallMessage;

  const MonthlyEmotionSummary({
    required this.happyDays,
    required this.normalDays,
    required this.gloomyDays,
    required this.overallMessage,
  });
}

/// 특정 감정에 대한 소비 통계
class EmotionSpendingStat {
  final String emotion;
  final int totalAmount;
  final int count;
  final double averageAmount;

  const EmotionSpendingStat({
    required this.emotion,
    required this.totalAmount,
    required this.count,
    required this.averageAmount,
  });
}

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

  // ================== Firestore 연동 ==================
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

  // ================== UI용 헬퍼 (하드코딩 로직 대체용) ==================

  /// 달력 셀에 보여줄 대표 감정 이모지
  String emojiForDate(DateTime date) {
    final entry = firstEntryFor(date);
    if (entry == null) return '';
    return _emojiFromEmotion(entry.emotion);
  }

  /// 감정 문자열 -> 이모지 매핑
  String _emojiFromEmotion(String emotion) {
    switch (emotion) {
      case '기쁨':
      case '행복':
        return '😊';
      case '혼란':
        return '😵‍💫';
      case '슬픔':
      case '우울':
        return '😢';
      case '피곤':
        return '😴';
      case '화남':
        return '😠';
      case '플렉스':
        return '😎';
      default:
        return '😐';
    }
  }

  /// 한 달 감정 요약 (기존 CommunicationPage 의 월 요약 로직을 ViewModel로 이동)
  MonthlyEmotionSummary buildMonthlySummary(DateTime monthAnchor) {
    final monthStart = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final monthEnd = DateTime(monthAnchor.year, monthAnchor.month + 1, 1);

    final monthlyEntries = _byDay.entries
        .where((e) =>
    !e.key.isBefore(monthStart) && e.key.isBefore(monthEnd))
        .expand((e) => e.value)
        .toList();

    int happyCount = monthlyEntries
        .where((e) =>
    e.emotion == '기쁨' ||
        e.emotion == '행복' ||
        e.emotion == '플렉스')
        .length;
    int normalCount = monthlyEntries
        .where((e) => e.emotion == '혼란' || e.emotion == '피곤')
        .length;
    int gloomyCount = monthlyEntries
        .where((e) =>
    e.emotion == '슬픔' || e.emotion == '우울' || e.emotion == '화남')
        .length;

    String overallMessage;
    if (monthlyEntries.isEmpty) {
      overallMessage = '이번 달 기록이 아직 없어요. 천천히 시작해볼까요?';
    } else if (happyCount > gloomyCount && happyCount > normalCount) {
      overallMessage = '긍정적인 한 달을 보내고 계시네요';
    } else if (gloomyCount > happyCount && gloomyCount > normalCount) {
      overallMessage = '조금 힘든 한 달이었네요. 힘내세요!';
    } else {
      overallMessage = '안정적인 한 달을 보내고 계시네요';
    }

    return MonthlyEmotionSummary(
      happyDays: happyCount,
      normalDays: normalCount,
      gloomyDays: gloomyCount,
      overallMessage: overallMessage,
    );
  }

  /// 특정 기간 동안, 감정 하나에 대한 소비 통계
  ///
  /// - periodStart / periodEnd 가 null이면 전체 기간 기준
  EmotionSpendingStat buildEmotionSpendingStat(
      String emotion, {
        DateTime? periodStart,
        DateTime? periodEnd,
      }) {
    bool inRange(DateTime d) {
      if (periodStart != null && d.isBefore(_dateOnly(periodStart!))) {
        return false;
      }
      if (periodEnd != null && !d.isBefore(_dateOnly(periodEnd!.add(const Duration(days: 1))))) {
        // end는 포함되게 하기 위해 +1일
        return false;
      }
      return true;
    }

    final entries = _byDay.entries
        .where((e) => inRange(e.key))
        .expand((e) => e.value)
        .where((e) => e.emotion == emotion)
        .toList();

    final total = entries.fold<int>(0, (sum, e) => sum + e.spendingAmount.toInt());
    final count = entries.length;
    final avg = count == 0 ? 0.0 : total / count;

    return EmotionSpendingStat(
      emotion: emotion,
      totalAmount: total,
      count: count,
      averageAmount: avg,
    );
  }

  // ================== internal ==================
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

  // ================= 감정/통계 헬퍼 =================

  /// UI에서 사용할 감정 리스트
  static const List<String> _emotionList = [
    '기쁨',
    '혼란',
    '슬픔',
    '피곤',
    '화남',
    '플렉스',
  ];

  List<String> get emotionList => List.unmodifiable(_emotionList);

  /// 감정 이름 -> 이모지 매핑
  String getEmoji(String emotion) {
    switch (emotion) {
      case '기쁨':
        return '😊';
      case '혼란':
        return '😵‍💫';
      case '슬픔':
        return '😢';
      case '피곤':
        return '😴';
      case '화남':
        return '😠';
      case '플렉스':
        return '😎';
      default:
        return '😐';
    }
  }

  /// 특정 감정에 대해 이번 달 **평균 소비 금액**(원 단위, 반올림) 반환
  int getEmotionAmount(String emotion, {DateTime? anchor}) {
    final now = anchor ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    // 이번 달 모든 일지 평탄화
    final monthlyEntries = _byDay.entries
        .where((e) =>
    !e.key.isBefore(monthStart) &&
        e.key.isBefore(monthEnd)) // [monthStart, monthEnd)
        .expand((e) => e.value)
        .where((e) => e.emotion == emotion)
        .toList();

    if (monthlyEntries.isEmpty) return 0;

    final total = monthlyEntries.fold<double>(
      0.0,
          (sum, e) => sum + e.spendingAmount,
    );

    return (total / monthlyEntries.length).round();
  }

  /// 이번 달 감정 요약 (카운트 + 메시지)
  ///
  /// return 예시:
  /// {
  ///   'happy': 5,
  ///   'normal': 8,
  ///   'gloomy': 3,
  ///   'message': '긍정적인 한 달을 보내고 계시네요'
  /// }
  Map<String, dynamic> monthlyEmotionSummary({DateTime? anchor}) {
    final now = anchor ?? DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final monthlyEntries = _byDay.entries
        .where((e) =>
    !e.key.isBefore(monthStart) &&
        e.key.isBefore(monthEnd))
        .expand((e) => e.value)
        .toList();

    final happyCount = monthlyEntries
        .where((e) =>
    e.emotion == '기쁨' ||
        e.emotion == '행복' ||
        e.emotion == '플렉스')
        .length;

    final normalCount = monthlyEntries
        .where((e) => e.emotion == '혼란' || e.emotion == '피곤')
        .length;

    final gloomyCount = monthlyEntries
        .where((e) =>
    e.emotion == '슬픔' ||
        e.emotion == '우울' ||
        e.emotion == '화남')
        .length;

    String message;
    if (happyCount > gloomyCount && happyCount > normalCount) {
      message = '긍정적인 한 달을 보내고 계시네요';
    } else if (gloomyCount > happyCount && gloomyCount > normalCount) {
      message = '조금 힘든 한 달이었네요. 힘내세요!';
    } else {
      message = '안정적인 한 달을 보내고 계시네요';
    }

    return {
      'happy': happyCount,
      'normal': normalCount,
      'gloomy': gloomyCount,
      'message': message,
    };
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

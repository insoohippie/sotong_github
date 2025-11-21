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

  /// 날짜별 기록 데이터
  Map<DateTime, List<EmotionSpendingDiary>> _byDay = {};
  Map<DateTime, List<EmotionSpendingDiary>> get byDay => _byDay;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  // ========== Calendar State ==========
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  // ========== Emotion Analysis State ==========
  String selectedEmotionForAnalysis = '기쁨';
  String selectedAnalysisPeriod = '월간'; // '주간' 또는 '월간'

  /// 🔹 일일 소비 한도 (달력에서 빨간색 표시용)
  ///   나중에 HomeViewModel / Firestore 값으로 교체 가능
  double dailySpendingLimit = 10000;

  // Firestore 구독 시작
  Future<void> loadMonth(DateTime anchor) async {
    await _sub?.cancel();
    _setLoading(true);

    selectedYear = anchor.year;
    selectedMonth = anchor.month;

    try {
      _sub = _repo.streamMonth(anchor).listen((snap) {
        final items = snap.docs
            .map(_repo.fromDoc)
            .whereType<EmotionSpendingDiary>()
            .toList();

        _rebuildByDay(items);
        _setError(null);
      }, onError: (e) {
        _setError('데이터 구독 오류: $e');
      });
    } catch (e) {
      _setError('로드 실패: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 달 변경
  void changeMonth(int delta) {
    var newMonth = selectedMonth + delta;
    var newYear = selectedYear;

    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }

    loadMonth(DateTime(newYear, newMonth, 1));
  }

  /// 날짜 대표 감정 이모지 (DateTime 기반)
  String emojiForDate(DateTime date) {
    final list = _byDay[_dateOnly(date)];
    if (list == null || list.isEmpty) return '';
    return getEmoji(list.first.emotion);
  }

  /// 날짜 지출 총합 (일 단위)
  int spendingForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final list = _byDay[_dateOnly(date)];

    if (list == null || list.isEmpty) return 0;

    return list.fold(0, (sum, e) => sum + e.spendingAmount.round());
  }

  /// 해당 날짜 기록 여부
  bool hasRecord(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final list = _byDay[_dateOnly(date)];
    return list != null && list.isNotEmpty;
  }

  // ========== ⬇️ EmotionCalendarSection 이 사용하는 헬퍼들 ==========

  /// 해당 날짜에 감정 기록이 있는지
  bool hasEmotionRecord(int day) => hasRecord(day);

  /// 해당 날짜의 지출 금액 (int)
  int spendingAmountForDay(int day) => spendingForDay(day);

  /// 해당 날짜의 대표 감정 이모지 (테스트 UI 그대로)
  String emotionEmojiForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    return emojiForDate(date);
  }

  /// 해당 날짜의 소비 일지 텍스트
  ///
  /// TODO: EmotionSpendingDiary 모델 안의 실제 필드(예: memo / note 등)에 맞게 수정
  String diaryForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final list = _byDay[_dateOnly(date)];
    if (list == null || list.isEmpty) {
      return '소비 일지가 아직 없어요.';
    }

    // 모델 필드를 아직 모르면 임시 문구 사용
    // 예: list.first.diary ?? '...' 이런 식으로 나중에 바꿔주면 됨
    return '소비 일지가 아직 작성되지 않았어요.';
  }

  /// 이모지 → 감정 이름 (테스트 파일 로직 그대로)
  String emotionNameFromEmoji(String emoji) {
    switch (emoji) {
      case '😊':
        return '기쁨';
      case '😵‍💫':
        return '혼란';
      case '😢':
        return '슬픔';
      case '😴':
        return '피곤';
      case '😠':
        return '화남';
      case '😎':
        return '플렉스';
      default:
        return '알 수 없음';
    }
  }

  // ========== 감정 드롭다운/통계 ==========

  static const List<String> emotionList = [
    '기쁨',
    '혼란',
    '슬픔',
    '피곤',
    '화남',
    '플렉스',
  ];

  /// 감정 → 이모지 매핑
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
        return '🙂';
    }
  }

  /// 감정 분석 섹션에서 쓰는: 분석용 감정 이모지
  String emotionEmojiForAnalysis(String emotion) => getEmoji(emotion);

  /// 감정/기간별 소비 금액
  int emotionSpendingAmount(String emotion, String period) {
    final now = DateTime(selectedYear, selectedMonth);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final entries = _byDay.entries
        .where(
          (e) => !e.key.isBefore(monthStart) && e.key.isBefore(monthEnd),
    )
        .expand((e) => e.value)
        .where((e) => e.emotion == emotion)
        .toList();

    if (entries.isEmpty) return 0;

    if (period == '월간') {
      return entries.fold(
        0,
            (sum, e) => sum + e.spendingAmount.round(),
      );
    }

    // 주간 계산: "마지막 7일" 기준 (임시 로직)
    final last7 = DateTime.now().subtract(const Duration(days: 7));
    final weekly = entries.where((e) => e.date.isAfter(last7)).toList();

    return weekly.fold(
      0,
          (sum, e) => sum + e.spendingAmount.round(),
    );
  }

  void setAnalysisEmotion(String emotion) {
    selectedEmotionForAnalysis = emotion;
    notifyListeners();
  }

  void setAnalysisPeriod(String period) {
    selectedAnalysisPeriod = period;
    notifyListeners();
  }

  String getMonthlyInsightMessage() {
    final summary = monthlyEmotionSummary();
    final msg = summary['message'] ?? '이번 달을 기록해보세요!';
    return msg;
  }

  /// 이번 달 감정 요약 + 인사이트 메시지 생성
  Map<String, dynamic> monthlyEmotionSummary({DateTime? anchor}) {
    final now = anchor ?? DateTime(selectedYear, selectedMonth);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final monthlyEntries = _byDay.entries
        .where((e) => !e.key.isBefore(monthStart) && e.key.isBefore(monthEnd))
        .expand((e) => e.value)
        .toList();

    // 감정별 카운트
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
      message = '긍정적인 한 달을 보내고 계시네요! 😊';
    } else if (gloomyCount > happyCount && gloomyCount > normalCount) {
      message = '조금 힘든 한 달이었네요 🥲';
    } else {
      message = '안정적인 한 달이에요 😌';
    }

    return {
      'happy': happyCount,
      'normal': normalCount,
      'gloomy': gloomyCount,
      'message': message,
    };
  }

  // 내부 유틸
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

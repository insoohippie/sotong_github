import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Icons;
import 'package:intl/intl.dart';

import 'package:sotong_local/services/spending_event_bus.dart';

import '../../model/record/monthly_record.dart';
import '../../model/record/day_record.dart';
import '../../model/record/record_entry.dart';

import '../../repository/record_repository.dart';
import '../../repository/plan_repository.dart';

class CommunicationViewModel extends ChangeNotifier {
  final RecordRepository _recordRepository;
  final PlanRepository _planRepository;

  late final StreamSubscription<SpendingUpdatedEvent> _spendingSub;

  CommunicationViewModel(
      this._recordRepository,
      this._planRepository,
      SpendingEventBus eventBus,
      ) {
    _spendingSub = eventBus.stream.listen((_) {
      reloadForCurrentMonth();
    });
  }

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // records 단일 소스(현재 선택된 달)
  MonthlyRecord? _monthly;

  // 최근 7/30일 집계를 위한 월 캐시
  final Map<String, MonthlyRecord> _monthCache = {}; // key: yyyy-MM

  // ========== Calendar State ==========
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  // ========== Emotion Analysis State ==========
  String selectedEmotionForAnalysis = '기쁨';
  String selectedAnalysisPeriod = '월간'; // '주간' | '월간'

  /// 일일 소비 한도(표시용)
  double dailySpendingLimit = 0;

  // =====================================================
  //  Load
  // =====================================================

  Future<void> loadMonth(DateTime anchor) async {
    _setLoading(true);

    selectedYear = anchor.year;
    selectedMonth = anchor.month;

    try {
      // 1) 월 기록 로드
      final monthly = await _recordRepository.loadMonthlyRecordByDate(anchor);
      _monthly = monthly;

      // 2) 캐시에 넣기
      _monthCache[_monthKey(anchor)] = monthly;

      // 3) 플랜에서 일일 소비 한도 로드
      await _loadDailyLimitFromPlan();

      // 4) 최근 30일 커버하도록 필요한 월들 프리로드
      await _preloadMonthsForRecentPeriod(days: 30);

      _setError(null);
    } catch (e) {
      _setError('로드 실패: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> reloadForCurrentMonth() async {
    await loadMonth(DateTime(selectedYear, selectedMonth, 1));
  }

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

  Future<void> _loadDailyLimitFromPlan() async {
    try {
      final plan = await _planRepository.getLatestPlanForCurrentUser();
      final metrics = plan?.result.totalMetrics;
      final limit = (metrics?.dailyConsumeAmount ?? 0).toDouble();
      dailySpendingLimit = limit;
    } catch (_) {
      dailySpendingLimit = 0;
    }
  }

  // =====================================================
  //  records 기반 헬퍼 (캘린더/모달용)
  // =====================================================

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _fmtKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  DayRecord? _dayRecord(DateTime date) {
    final key = _fmtKey(_dateOnly(date));
    return _monthly?.days[key];
  }

  List<RecordEntry> entriesForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final ds = _dayRecord(date);
    return ds?.spendingEntries ?? const [];
  }

  int spendingForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final ds = _dayRecord(date);
    if (ds == null) return 0;

    return ds.totalSpendingAmount;
  }

  bool hasEmotionRecord(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final emotion = _dayRecord(date)?.emotion ?? '';
    return emotion.trim().isNotEmpty;
  }

  bool hasAmountRecord(int day) {
    return spendingForDay(day) > 0;
  }

  bool hasDiaryRecord(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final comment = _dayRecord(date)?.comment ?? '';
    return comment.trim().isNotEmpty;
  }

  bool hasRecord(int day) {
    return hasEmotionRecord(day) || hasAmountRecord(day) || hasDiaryRecord(day);
  }

  int spendingAmountForDay(int day) => spendingForDay(day);

  String emotionLabelForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    return _dayRecord(date)?.emotion ?? '';
  }

  String emotionEmojiForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final emotion = _dayRecord(date)?.emotion ?? '';
    if (emotion.trim().isEmpty) return '';
    return getEmoji(emotion);
  }

  String diaryForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final comment = _dayRecord(date)?.comment ?? '';
    if (comment.trim().isEmpty) return '소비 일지가 아직 없어요.';
    return comment;
  }

  // =====================================================
  //  감정 매핑/분석 (최근 7/30일 기준)
  // =====================================================

  static const List<String> emotionList = [
    '평온',
    '좋음',
    '슬픔',
    '스트레스',
    '동기부여',
    '아무 감정 없음',
  ];

  String getEmoji(String emotion) {
    switch (emotion) {
      case '평온':
        return '😌';
      case '좋음':
        return '😊';
      case '슬픔':
        return '😢';
      case '스트레스':
        return '😣';
      case '동기부여':
        return '🔥';
      case '아무 감정 없음':
        return '🙂';
      default:
        return '🙂';
    }
  }

  String emotionEmojiForAnalysis(String emotion) => getEmoji(emotion);

  // -----------------------------
  // ✅ 최근 기간 집계
  // -----------------------------

  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  Future<void> _ensureMonthLoaded(DateTime anyDay) async {
    final key = _monthKey(anyDay);
    if (_monthCache.containsKey(key)) return;

    final monthAnchor = DateTime(anyDay.year, anyDay.month, 1);
    final monthly = await _recordRepository.loadMonthlyRecordByDate(monthAnchor);
    _monthCache[key] = monthly;
  }

  Future<void> _preloadMonthsForRecentPeriod({required int days}) async {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));

    DateTime cursor = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(today.year, today.month, 1);

    while (!cursor.isAfter(endMonth)) {
      await _ensureMonthLoaded(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
  }

  List<DayRecord> _daysInRecentPeriod(String period) {
    final today = _dateOnly(DateTime.now());
    final int days = (period == '주간') ? 7 : 30;
    final start = today.subtract(Duration(days: days - 1));

    final List<DayRecord> out = [];

    for (final m in _monthCache.values) {
      for (final d in m.days.values) {
        final date = _dateOnly(d.date);
        if (!date.isBefore(start) && !date.isAfter(today)) {
          out.add(d);
        }
      }
    }

    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  int emotionCount(String emotion, String period) {
    final days = _daysInRecentPeriod(period);
    return days.where((d) => d.emotion.trim() == emotion).length;
  }

  int emotionTotalSpending(String emotion, String period) {
    final days = _daysInRecentPeriod(period).where((d) => d.emotion.trim() == emotion);

    return days.fold<int>(0, (sum, d) {
      return sum + d.totalSpendingAmount;
    });
  }

  int emotionSpendingAmount(String emotion, String period) {
    return emotionTotalSpending(emotion, period);
  }

  List<Map<String, dynamic>> emotionTop3Stats(String period) {
    final list = <Map<String, dynamic>>[];

    for (final e in emotionList) {
      final count = emotionCount(e, period);
      if (count == 0) continue;

      final total = emotionTotalSpending(e, period);
      final avg = (total / count).round();

      list.add({
        'emotion': e,
        'emoji': getEmoji(e),
        'count': count,
        'total': total,
        'avg': avg,
      });
    }

    list.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

    return list.take(3).toList();
  }

  void setAnalysisEmotion(String emotion) {
    selectedEmotionForAnalysis = emotion;
    notifyListeners();
  }

  void setAnalysisPeriod(String period) {
    selectedAnalysisPeriod = period;
    _preloadMonthsForRecentPeriod(days: period == '주간' ? 7 : 30);
    notifyListeners();
  }

  // =====================================================
  //  인사이트 배너
  // =====================================================

  static final _bannerIcons = [
    Icons.mood,
    Icons.warning_amber_rounded,
    Icons.volunteer_activism,
    Icons.link,
    Icons.calendar_view_week,
  ];

  static const _bannerColors = [
    Color(0xFF0062FF),
    Color(0xFFD32F2F),
    Color(0xFF43A047),
    Color(0xFF7B1FA2),
    Color(0xFF00838F),
  ];

  List<Map<String, dynamic>> get bannerInsights {
    final month = selectedMonth;
    final messages = [
      _messageRepresentativeEmotion(month),
      _messageEmotionWhenOverBudget(month),
      _messageEmotionWhenSaving(month),
      _messageEmotionCategoryRelation(month),
      _messageWeekdayEmotionPattern(month),
    ];

    return List.generate(
      5,
          (i) => {
        'title': messages[i],
        'icon': _bannerIcons[i],
        'color': _bannerColors[i],
      },
    );
  }

  String _messageRepresentativeEmotion(int month) {
    final top = _topEmotionThisMonth();
    if (top == null || top.count == 0) return '$month월에는 아직 감정 기록이 없어요.';
    return '$month월에는 ${top.name} 감정이 가장 많이 기록됐어요.';
  }

  ({String name, int count})? _topEmotionThisMonth() {
    if (_monthly == null) return null;

    final monthStart = DateTime(selectedYear, selectedMonth, 1);
    final monthEnd = DateTime(selectedYear, selectedMonth + 1, 1);
    final Map<String, int> counts = {};

    for (final d in _monthly!.days.values) {
      final date = _dateOnly(d.date);
      if (date.isBefore(monthStart) || !date.isBefore(monthEnd)) continue;
      final emo = d.emotion.trim();
      if (emo.isEmpty) continue;
      counts[emo] = (counts[emo] ?? 0) + 1;
    }

    if (counts.isEmpty) return null;
    final entry = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (name: entry.key, count: entry.value);
  }

  String _messageEmotionWhenOverBudget(int month) {
    return '일일 예산을 초과한 날에는 스트레스 감정이 가장 많았어요.';
  }

  String _messageEmotionWhenSaving(int month) {
    return '지출을 아낀 날에는 동기부여 감정이 가장 많이 기록됐어요.';
  }

  String _messageEmotionCategoryRelation(int month) {
    return '스트레스가 기록된 날에는 치킨 카테고리 소비가 가장 많아요.';
  }

  String _messageWeekdayEmotionPattern(int month) {
    return '주말에는 기쁨 감정과 함께 외식 소비가 많아요.';
  }

  String getMonthlyInsightMessage() {
    final summary = monthlyEmotionSummary();
    return summary['message'] ?? '이번 달을 기록해보세요!';
  }

  Map<String, dynamic> monthlyEmotionSummary({DateTime? anchor}) {
    if (_monthly == null) {
      return {
        'happy': 0,
        'normal': 0,
        'gloomy': 0,
        'message': '이번 달을 기록해보세요!',
      };
    }

    final now = anchor ?? DateTime(selectedYear, selectedMonth);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final days = _monthly!.days.values.where((d) {
      final date = _dateOnly(d.date);
      return !date.isBefore(monthStart) && date.isBefore(monthEnd);
    });

    int happy = 0, normal = 0, gloomy = 0;

    for (final d in days) {
      final emo = d.emotion.trim();
      if (emo.isEmpty) continue;

      if (emo == '좋음' || emo == '동기부여') {
        happy++;
      } else if (emo == '평온' || emo == '아무 감정 없음') {
        normal++;
      } else if (emo == '슬픔' || emo == '스트레스') {
        gloomy++;
      }
    }

    String message;
    if (happy > gloomy && happy > normal) {
      message = '긍정적인 한 달을 보내고 계시네요! 😊';
    } else if (gloomy > happy && gloomy > normal) {
      message = '조금 힘든 한 달이었네요 🥲';
    } else {
      message = '안정적인 한 달이에요 😌';
    }

    return {
      'happy': happy,
      'normal': normal,
      'gloomy': gloomy,
      'message': message,
    };
  }

  // =====================================================
  //  내부 유틸
  // =====================================================

  void _setLoading(bool v) {
    _isLoading = v;
  }

  void _setError(String? msg) {
    _error = msg;
  }

  @override
  void dispose() {
    _spendingSub.cancel();
    super.dispose();
  }
}
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Icons;
import 'package:intl/intl.dart';

import 'package:sotong_local/services/spending_event_bus.dart';

import '../../model/record/monthly_spending.dart';
import '../../model/record/day_spending.dart';
import '../../model/record/spending_entry.dart';

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
    // 소비 저장/수정 이벤트 발생 시 현재 달 리로드
    _spendingSub = eventBus.stream.listen((_) {
      reloadForCurrentMonth();
    });
  }

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // records 단일 소스(현재 선택된 달): 캘린더/모달은 이걸 주로 씀
  MonthlySpending? _monthly;

  // 최근 7/30일 집계를 위해 여러 월을 캐시
  final Map<String, MonthlySpending> _monthCache = {}; // key: 'yyyy-MM'

  // ========== Calendar State ==========
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  // ========== Emotion Analysis State ==========
  String selectedEmotionForAnalysis = '기쁨';
  String selectedAnalysisPeriod = '월간'; // '주간' | '월간'

  /// 일일 소비 한도(표시용)
  /// - 플랜에서 로드해서 넣음
  double dailySpendingLimit = 0;

  // =====================================================
  //  Load
  // =====================================================

  Future<void> loadMonth(DateTime anchor) async {
    _setLoading(true);

    selectedYear = anchor.year;
    selectedMonth = anchor.month;

    try {
      // 1) 월 기록 로드 (offline-first)
      final monthly = await _recordRepository.loadMonthlySpendingByDate(anchor);
      _monthly = monthly;

      // 캐시에 넣기 (최근 7/30일 집계용)
      _monthCache[_monthKey(anchor)] = monthly;

      // 2)플랜에서 일일 소비 한도 로드
      await _loadDailyLimitFromPlan();

      // 3) 최근 30일 커버하도록 필요한 월들 프리로드
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

  /// ✅ 플랜에서 daily limit 읽어서 세팅
  Future<void> _loadDailyLimitFromPlan() async {
    try {
      // 너 프로젝트에서 "최신 플랜 1개" 가져오는 메서드로 맞춰주면 됨
      final plan = await _planRepository.getLatestPlanForCurrentUser();
      final metrics = plan?.result.totalMetrics;

      // sumDailyConsume = 하루 소비 한도 (HomeViewModel에서 쓰던 값)
      final limit = (metrics?.dailyConsumeAmount ?? 0).toDouble();
      dailySpendingLimit = limit;
    } catch (_) {
      // 플랜 로드 실패해도 기록 화면은 뜨게
      dailySpendingLimit = 0;
    }
  }

  // =====================================================
  //  records 기반 헬퍼 (캘린더/모달용: selectedMonth 기준)
  // =====================================================

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _fmtKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  DaySpending? _daySpending(DateTime date) {
    final key = _fmtKey(_dateOnly(date));
    return _monthly?.days[key];
  }

  List<SpendingEntry> entriesForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final ds = _daySpending(date);
    return ds?.entries ?? [];
  }

  int spendingForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final ds = _daySpending(date);
    if (ds == null) return 0;

    // ds.totalAmount가 있으면 그걸 우선 사용
    final totalFromField = ds.totalAmount;
    if (totalFromField != null) return totalFromField;

    // fallback: entries 합
    return ds.entries.fold<int>(0, (sum, e) => sum + e.amount.round());
  }

  bool hasEmotionRecord(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final emotion = _daySpending(date)?.emotion ?? '';
    return emotion.trim().isNotEmpty;
  }

  bool hasAmountRecord(int day) {
    return spendingForDay(day) > 0;
  }

  bool hasDiaryRecord(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final comment = _daySpending(date)?.comment ?? '';
    return comment.trim().isNotEmpty;
  }

  bool hasRecord(int day) {
    // 감정 or 금액 or 일지 중 하나라도 있으면 기록으로 판단
    return hasEmotionRecord(day) || hasAmountRecord(day) || hasDiaryRecord(day);
  }

  // 달력 UI에서 쓰는 헬퍼들
  int spendingAmountForDay(int day) => spendingForDay(day);

  /// 해당 날짜에 저장된 감정 라벨 (평온, 좋음, 슬픔 등) — 달력/상세에서 Lottie 경로 매핑용
  String emotionLabelForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    return _daySpending(date)?.emotion ?? '';
  }

  String emotionEmojiForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final emotion = _daySpending(date)?.emotion ?? '';
    if (emotion.trim().isEmpty) return '';
    return getEmoji(emotion);
  }

  String diaryForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final comment = _daySpending(date)?.comment ?? '';
    if (comment.trim().isEmpty) return '소비 일지가 아직 없어요.';
    return comment;
  }

  // =====================================================
  //  감정 매핑/분석 (최근 7/30일 기준)
  // =====================================================

  static const List<String> emotionList = ['기쁨', '혼란', '슬픔', '피곤', '화남', '플렉스'];

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

  String emotionEmojiForAnalysis(String emotion) => getEmoji(emotion);

  // -----------------------------
  // ✅ 최근 기간 집계 (핵심)
  // -----------------------------

  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  Future<void> _ensureMonthLoaded(DateTime anyDay) async {
    final key = _monthKey(anyDay);
    if (_monthCache.containsKey(key)) return;

    final monthAnchor = DateTime(anyDay.year, anyDay.month, 1);
    final monthly = await _recordRepository.loadMonthlySpendingByDate(
      monthAnchor,
    );
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

  List<DaySpending> _daysInRecentPeriod(String period) {
    final today = _dateOnly(DateTime.now());
    final int days = (period == '주간') ? 7 : 30;
    final start = today.subtract(Duration(days: days - 1));

    final List<DaySpending> out = [];

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

  /// 감정별 기록 일수 (최근 7/30일)
  int emotionCount(String emotion, String period) {
    final days = _daysInRecentPeriod(period);
    return days.where((d) => d.emotion.trim() == emotion).length;
  }

  /// 감정별 소비 총합 (최근 7/30일)
  int emotionTotalSpending(String emotion, String period) {
    final days = _daysInRecentPeriod(
      period,
    ).where((d) => d.emotion.trim() == emotion);

    return days.fold<int>(0, (sum, d) {
      final total =
          d.totalAmount ??
              d.entries.fold<int>(0, (s, e) => s + e.amount.round());
      return sum + total;
    });
  }

  /// "월간=최근30일 / 주간=최근7일" 총합
  int emotionSpendingAmount(String emotion, String period) {
    return emotionTotalSpending(emotion, period);
  }

  /// return: [{emotion, emoji, count, total, avg}, ...] 최대 3개
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

    // 1순위: 총 금액(total) 많은 순
    list.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

    return list.take(3).toList();
  }

  void setAnalysisEmotion(String emotion) {
    selectedEmotionForAnalysis = emotion;
    notifyListeners();
  }

  /// "최근 N일"로 계산
  void setAnalysisPeriod(String period) {
    selectedAnalysisPeriod = period;
    _preloadMonthsForRecentPeriod(days: period == '주간' ? 7 : 30);

    notifyListeners();
  }

  // =====================================================
  //  인사이트 배너 (감정 중심 5종) — SlidingBanner용
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
    // TODO: 예산 초과한 날의 감정 집계
    return '일일 예산을 초과한 날에는 스트레스 감정이 가장 많았어요.';
  }

  String _messageEmotionWhenSaving(int month) {
    // TODO: 절약한 날의 감정 집계
    return '지출을 아낀 날에는 동기부여 감정이 가장 많이 기록됐어요.';
  }

  String _messageEmotionCategoryRelation(int month) {
    // TODO: 감정별 최다 카테고리
    return '스트레스가 기록된 날에는 치킨 카테고리 소비가 가장 많아요.';
  }

  String _messageWeekdayEmotionPattern(int month) {
    // TODO: 요일별 감정·소비 패턴
    return '주말에는 기쁨 감정과 함께 외식 소비가 많아요.';
  }

  String getMonthlyInsightMessage() {
    final summary = monthlyEmotionSummary();
    return summary['message'] ?? '이번 달을 기록해보세요!';
  }

  Map<String, dynamic> monthlyEmotionSummary({DateTime? anchor}) {
    if (_monthly == null) {
      return {'happy': 0, 'normal': 0, 'gloomy': 0, 'message': '이번 달을 기록해보세요!'};
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

      if (emo == '기쁨' || emo == '행복' || emo == '플렉스') {
        happy++;
      } else if (emo == '혼란' || emo == '피곤') {
        normal++;
      } else if (emo == '슬픔' || emo == '우울' || emo == '화남') {
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

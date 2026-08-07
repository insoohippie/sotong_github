// lib/view_model/communication/communication_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Icons;
import 'package:intl/intl.dart';

import 'package:sotong/services/record_event_bus.dart';
import 'package:sotong/services/home_widget_sync_service.dart';

import '../../model/record/monthly_record.dart';
import '../../model/record/day_record.dart';
import '../../model/record/record_entry.dart';

import '../../repository/record_repository.dart';
import '../../repository/plan_repository.dart';

class CommunicationViewModel extends ChangeNotifier {
  final RecordRepository _recordRepository;
  final PlanRepository _planRepository;

  late final StreamSubscription<RecordUpdatedEvent> _eventSub;

  CommunicationViewModel(
      this._recordRepository,
      this._planRepository,
      RecordEventBus eventBus,
      ) {
    _eventSub = eventBus.stream.listen((_) {
      reloadForCurrentMonth();
    });
  }

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MonthlyRecord? _monthly;
  final Map<String, MonthlyRecord> _monthCache = {};

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  String selectedEmotionForAnalysis = '기쁨';
  String selectedAnalysisPeriod = '월간';

  double dailySpendingLimit = 0;

  DateTime? _planStartDate;
  DateTime? _planEndDate;

  // HomeViewModel에서 전달받는 실제 플랜 완료일
  DateTime? _planCompletionDate;

  DateTime? get planStartDate => _planStartDate;
  DateTime? get planEndDate => _planEndDate;

  DateTime _monthAnchor(int year, int month) =>
      DateTime(year, month, 1);

  DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  // ───────────────── 플랜 날짜 범위 ─────────────────

  /// HomeViewModel의 planCompletionDate를
  /// CommunicationViewModel에도 동기화한다.
  ///
  /// notifyListeners()는 하지 않는다.
  /// CommunicationPage가 HomeViewModel 변경에 따라
  /// 필요한 rebuild를 수행하기 때문이다.
  void setPlanCompletionDate(DateTime? completionDate) {
    _planCompletionDate = completionDate == null
        ? null
        : _dateOnly(completionDate);
  }

  /// 달력의 최종 허용일
  ///
  /// 완료된 플랜:
  ///   실제 완료일
  ///
  /// 진행 중:
  ///   플랜 종료일
  DateTime? _effectiveEndDate(DateTime? endCap) {
    return endCap ??
        _planCompletionDate ??
        _planEndDate;
  }

  /// 분석의 최종 기준일
  ///
  /// 진행 중:
  ///   미래 기록은 분석하지 않으므로 오늘까지
  ///   단, 플랜 종료일이 이미 지났다면 종료일까지
  ///
  /// 완료 후:
  ///   실제 완료일까지
  DateTime _analysisEndDate() {
    final today = _dateOnly(DateTime.now());

    final completion = _planCompletionDate;
    if (completion != null) {
      return completion.isAfter(today)
          ? today
          : completion;
    }

    final planEnd = _planEndDate;

    if (planEnd != null &&
        planEnd.isBefore(today)) {
      return planEnd;
    }

    return today;
  }

  /// 최근 N일의 시작일을 계산한다.
  ///
  /// 단, 절대로 플랜 시작일 이전으로 내려가지 않는다.
  DateTime _analysisStartDate(int days) {
    final end = _analysisEndDate();

    var start = end.subtract(
      Duration(days: days - 1),
    );

    final planStart = _planStartDate;

    if (planStart != null &&
        start.isBefore(planStart)) {
      start = planStart;
    }

    return start;
  }

  /// 현재 선택된 월에서 이전 달로 이동 가능한지
  ///
  /// 플랜 시작월보다 이전으로는 이동할 수 없다.
  bool canGoToPreviousMonth({DateTime? endCap}) {
    if (_planStartDate == null) return true;

    final current = _monthAnchor(selectedYear, selectedMonth);
    final start = _monthAnchor(
      _planStartDate!.year,
      _planStartDate!.month,
    );

    return current.isAfter(start);
  }

  /// 현재 선택된 월에서 다음 달로 이동 가능한지
  ///
  /// 진행 중:
  ///   플랜 종료월까지만 이동 가능
  ///
  /// 완료 후:
  ///   실제 완료월까지만 이동 가능
  bool canGoToNextMonth({DateTime? endCap}) {
    final effectiveEnd = _effectiveEndDate(endCap);

    if (effectiveEnd == null) return true;

    final current = _monthAnchor(selectedYear, selectedMonth);
    final end = _monthAnchor(
      effectiveEnd.year,
      effectiveEnd.month,
    );

    return current.isBefore(end);
  }

  /// 달력의 특정 날짜가 현재 플랜의 허용 범위인지 확인
  ///
  /// 진행 중:
  ///   시작일 ~ 플랜 종료일
  ///
  /// 완료 후:
  ///   시작일 ~ 실제 완료일
  bool isDayInPlanRange(int day, {DateTime? endCap}) {
    final date = _dateOnly(
      DateTime(selectedYear, selectedMonth, day),
    );

    // 플랜 시작 전
    if (_planStartDate != null &&
        date.isBefore(_planStartDate!)) {
      return false;
    }

    // 진행 중이면 플랜 종료일,
    // 완료 후면 실제 완료일
    final effectiveEnd = _effectiveEndDate(endCap);

    if (effectiveEnd != null &&
        date.isAfter(_dateOnly(effectiveEnd))) {
      return false;
    }

    return true;
  }

  /// 요청된 월을 플랜 허용 범위 안으로 보정한다.
  ///
  /// 홈의 _clampDateToAllowedRange와 같은 역할을
  /// 소통 화면에서는 "월 단위"로 수행한다.
  DateTime _clampMonthToAllowedRange(
      DateTime anchor, {
        DateTime? endCap,
      }) {
    var normalized = _monthAnchor(anchor.year, anchor.month);

    final planStart = _planStartDate;
    if (planStart != null) {
      final startMonth = _monthAnchor(
        planStart.year,
        planStart.month,
      );

      if (normalized.isBefore(startMonth)) {
        normalized = startMonth;
      }
    }

    final effectiveEnd = _effectiveEndDate(endCap);
    if (effectiveEnd != null) {
      final endMonth = _monthAnchor(
        effectiveEnd.year,
        effectiveEnd.month,
      );

      if (normalized.isAfter(endMonth)) {
        normalized = endMonth;
      }
    }

    return normalized;
  }

  // ───────────────── 월 로딩 ─────────────────

  Future<void> loadMonth(
      DateTime anchor, {
        DateTime? endCap,
      }) async {
    _setLoading(true);

    try {
      // 먼저 플랜 정보를 불러온 뒤 날짜 범위를 판단한다.
      await _loadPlanInfo();

      // 홈과 동일하게 허용 범위 안으로 보정
      final targetMonth = _clampMonthToAllowedRange(
        anchor,
        endCap: endCap,
      );

      selectedYear = targetMonth.year;
      selectedMonth = targetMonth.month;

      // 보정된 실제 선택 월의 데이터를 로드
      final monthly =
      await _recordRepository.loadMonthlyRecordByDate(targetMonth);

      _monthly = monthly;
      _monthCache[_monthKey(targetMonth)] = monthly;

      // 분석용 캐시
      if (_planStartDate != null) {
        await _preloadMonthsForPlanPeriod(_planStartDate!);
      } else {
        await _preloadMonthsForRecentPeriod(days: 30);
      }

      _setError(null);
    } catch (e) {
      _setError('로드 실패: $e');
    } finally {
      _setLoading(false);
      notifyListeners();

      unawaited(
        HomeWidgetSyncService.syncCommunicationBannerItems(
          bannerInsights,
        ),
      );
    }
  }

  Future<void> reloadForCurrentMonth() async {
    await loadMonth(
      DateTime(selectedYear, selectedMonth, 1),
    );
  }

  void changeMonth(
      int delta, {
        DateTime? endCap,
      }) {
    if (delta < 0 &&
        !canGoToPreviousMonth(endCap: endCap)) {
      return;
    }

    if (delta > 0 &&
        !canGoToNextMonth(endCap: endCap)) {
      return;
    }

    var newMonth = selectedMonth + delta;
    var newYear = selectedYear;

    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }

    loadMonth(
      DateTime(newYear, newMonth, 1),
      endCap: endCap,
    );
  }

  // ───────────────── 플랜 정보 ─────────────────

  Future<void> _loadPlanInfo() async {
    try {
      final plan =
      await _planRepository.getLatestPlanForCurrentUser();

      final metrics = plan?.result.totalMetrics;

      dailySpendingLimit =
          (metrics?.dailyConsumeAmount ?? 0).toDouble();

      _planStartDate = _extractPlanStartDate(plan);
      _planEndDate = _extractPlanEndDate(plan);
    } catch (_) {
      dailySpendingLimit = 0;
      _planStartDate = null;
      _planEndDate = null;
    }
  }

  DateTime? _extractPlanStartDate(dynamic plan) {
    if (plan == null) return null;

    DateTime? parseCandidate(dynamic value) {
      if (value == null) return null;

      if (value is DateTime) {
        return _dateOnly(value);
      }

      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return _dateOnly(parsed);
        }
      }

      return null;
    }

    // HomeViewModel과 동일한 우선순위
    try {
      final start = parseCandidate(plan.startDate);
      if (start != null) return start;
    } catch (_) {}

    try {
      final creation = parseCandidate(plan.creationDate);
      if (creation != null) return creation;
    } catch (_) {}

    // 기존 데이터 호환용 fallback
    try {
      final nested = parseCandidate(plan.result.startDate);
      if (nested != null) return nested;
    } catch (_) {}

    try {
      final created = parseCandidate(plan.createdAt);
      if (created != null) return created;
    } catch (_) {}

    return null;
  }

  DateTime? _extractPlanEndDate(dynamic plan) {
    if (plan == null) return null;

    DateTime? parseCandidate(dynamic value) {
      if (value == null) return null;

      if (value is DateTime) {
        return _dateOnly(value);
      }

      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return _dateOnly(parsed);
        }
      }

      return null;
    }

    // HomeViewModel과 동일:
    // 수정된 종료일이 있으면 modEndDate 우선
    try {
      final modifiedEnd = parseCandidate(plan.modEndDate);
      if (modifiedEnd != null) return modifiedEnd;
    } catch (_) {}

    try {
      final end = parseCandidate(plan.endDate);
      if (end != null) return end;
    } catch (_) {}

    return null;
  }

  String _fmtKey(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(d);


  DayRecord? _dayRecord(DateTime date) {
    final key = _fmtKey(_dateOnly(date));
    return _monthly?.days[key];
  }

  DayRecord? _findDayRecord(DateTime date) {
    final monthKey = _monthKey(date);
    final monthly = _monthCache[monthKey];
    if (monthly == null) return null;

    final dayKey = _fmtKey(_dateOnly(date));
    return monthly.days[dayKey];
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
    final date = DateTime(selectedYear, selectedMonth, day);
    final record = _dayRecord(date);

    if (record == null) return false;
    if (record.isAutoGenerated) return false;

    // DayRecord가 있고 자동 생성이 아니면,
    // 소비 금액이 0원이어도 사용자가 기록한 날로 인정
    return true;
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

  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  Future<void> _ensureMonthLoaded(DateTime anyDay) async {
    final key = _monthKey(anyDay);

    if (_monthCache.containsKey(key)) {
      return;
    }

    final monthAnchor = DateTime(
      anyDay.year,
      anyDay.month,
      1,
    );

    final monthly =
    await _recordRepository.loadMonthlyRecordByDate(
      monthAnchor,
    );

    _monthCache[key] = monthly;
  }

  /// 최근 주간/월간 분석에 필요한 월 데이터를 미리 로드한다.
  ///
  /// 플랜 시작일 이전 데이터는 로드할 필요가 없고,
  /// 완료된 플랜이면 완료일 이후도 분석하지 않는다.
  Future<void> _preloadMonthsForRecentPeriod({
    required int days,
  }) async {
    final end = _analysisEndDate();
    final start = _analysisStartDate(days);

    if (start.isAfter(end)) {
      return;
    }

    var cursor = DateTime(
      start.year,
      start.month,
      1,
    );

    final endMonth = DateTime(
      end.year,
      end.month,
      1,
    );

    while (!cursor.isAfter(endMonth)) {
      await _ensureMonthLoaded(cursor);

      cursor = DateTime(
        cursor.year,
        cursor.month + 1,
        1,
      );
    }
  }

  /// 플랜 전체 분석을 위해 필요한 월 데이터를 미리 로드한다.
  ///
  /// 진행 중이면 오늘까지만,
  /// 완료된 플랜이면 실제 완료일까지 로드한다.
  Future<void> _preloadMonthsForPlanPeriod(
      DateTime planStart,
      ) async {
    final start = _dateOnly(planStart);
    final end = _analysisEndDate();

    if (start.isAfter(end)) {
      return;
    }

    var cursor = DateTime(
      start.year,
      start.month,
      1,
    );

    final endMonth = DateTime(
      end.year,
      end.month,
      1,
    );

    while (!cursor.isAfter(endMonth)) {
      await _ensureMonthLoaded(cursor);

      cursor = DateTime(
        cursor.year,
        cursor.month + 1,
        1,
      );
    }
  }

  /// 최근 주간/월간 분석 대상 기록
  ///
  /// 주간:
  ///   최근 7일
  ///
  /// 월간:
  ///   최근 30일
  ///
  /// 단,
  /// - 플랜 시작일 이전 제외
  /// - 진행 중 미래 날짜 제외
  /// - 완료 후 완료일 이후 제외
  List<DayRecord> _daysInRecentPeriod(
      String period,
      ) {
    final days =
    period == '주간' ? 7 : 30;

    final start = _analysisStartDate(days);
    final end = _analysisEndDate();

    final List<DayRecord> out = [];

    for (final monthly in _monthCache.values) {
      for (final day in monthly.days.values) {
        final date = _dateOnly(day.date);

        if (date.isBefore(start)) {
          continue;
        }

        if (date.isAfter(end)) {
          continue;
        }

        out.add(day);
      }
    }

    out.sort(
          (a, b) => a.date.compareTo(b.date),
    );

    return out;
  }

  /// 플랜 전체 분석 대상 기록
  ///
  /// 진행 중:
  ///   시작일 ~ 오늘
  ///
  /// 완료 후:
  ///   시작일 ~ 실제 완료일
  List<DayRecord> _daysInPlanFullPeriod() {
    final end = _analysisEndDate();

    final start =
        _planStartDate ?? end;

    if (start.isAfter(end)) {
      return const [];
    }

    final List<DayRecord> out = [];

    for (final monthly in _monthCache.values) {
      for (final day in monthly.days.values) {
        final date = _dateOnly(day.date);

        if (date.isBefore(start)) {
          continue;
        }

        if (date.isAfter(end)) {
          continue;
        }

        out.add(day);
      }
    }

    out.sort(
          (a, b) => a.date.compareTo(b.date),
    );

    return out;
  }

  int emotionCount(
      String emotion,
      String period,
      ) {
    final days = _daysInRecentPeriod(period);

    return days
        .where(
          (d) => d.emotion.trim() == emotion,
    )
        .length;
  }

  int emotionTotalSpending(
      String emotion,
      String period,
      ) {
    final days = _daysInRecentPeriod(period)
        .where(
          (d) => d.emotion.trim() == emotion,
    );

    return days.fold<int>(
      0,
          (sum, d) =>
      sum + d.totalSpendingAmount,
    );
  }

  int emotionSpendingAmount(
      String emotion,
      String period,
      ) {
    return emotionTotalSpending(
      emotion,
      period,
    );
  }

  /// 감정별 통계를 만든 뒤
  /// sortBy에 따라 실제 TOP3를 반환한다.
  ///
  /// sortBy:
  /// - count : 기록 횟수
  /// - total : 총 소비
  /// - avg   : 일일 평균 소비
  List<Map<String, dynamic>> emotionTop3Stats(
      String period, {
        String sortBy = 'count',
      }) {
    final days = _daysInRecentPeriod(period);

    final countByEmotion = <String, int>{};
    final totalByEmotion = <String, int>{};

    for (final day in days) {
      final emotion = day.emotion.trim();

      if (emotion.isEmpty) {
        continue;
      }

      countByEmotion[emotion] =
          (countByEmotion[emotion] ?? 0) + 1;

      totalByEmotion[emotion] =
          (totalByEmotion[emotion] ?? 0) +
              day.totalSpendingAmount;
    }

    final list =
    countByEmotion.entries.map((entry) {
      final emotion = entry.key;
      final count = entry.value;

      final total =
          totalByEmotion[emotion] ?? 0;

      final avg = count == 0
          ? 0
          : (total / count).round();

      return <String, dynamic>{
        'emotion': emotion,
        'emoji': getEmoji(emotion),
        'count': count,
        'total': total,
        'avg': avg,
      };
    }).toList();

    int metricValue(
        Map<String, dynamic> item,
        ) {
      switch (sortBy) {
        case 'total':
          return item['total'] as int;

        case 'avg':
          return item['avg'] as int;

        case 'count':
        default:
          return item['count'] as int;
      }
    }

    list.sort((a, b) {
      // 1순위:
      // 현재 슬라이드의 핵심 지표
      final metricCompare =
      metricValue(b).compareTo(
        metricValue(a),
      );

      if (metricCompare != 0) {
        return metricCompare;
      }

      // 동률이면 기록 횟수 우선
      final countCompare =
      (b['count'] as int).compareTo(
        a['count'] as int,
      );

      if (countCompare != 0) {
        return countCompare;
      }

      // 그래도 같으면 총 지출
      final totalCompare =
      (b['total'] as int).compareTo(
        a['total'] as int,
      );

      if (totalCompare != 0) {
        return totalCompare;
      }

      // 완전히 같으면 이름순으로 고정해서
      // rebuild 때 순서가 흔들리지 않도록 한다.
      return (a['emotion'] as String)
          .compareTo(
        b['emotion'] as String,
      );
    });

    return list.take(3).toList();
  }

  void setAnalysisEmotion(String emotion) {
    selectedEmotionForAnalysis = emotion;
    notifyListeners();
  }

  /// 주간 ↔ 월간 변경
  ///
  /// 필요한 월 데이터를 불러온 뒤에도
  /// notifyListeners()가 실행되도록 Future로 변경.
  Future<void> setAnalysisPeriod(
      String period,
      ) async {
    if (period == selectedAnalysisPeriod) {
      return;
    }

    selectedAnalysisPeriod = period;

    // 토글은 즉시 변경되도록 한 번 갱신
    notifyListeners();

    await _preloadMonthsForRecentPeriod(
      days: period == '주간' ? 7 : 30,
    );

    // 새로 로드된 월 데이터까지 반영하도록
    // 반드시 한 번 더 갱신
    notifyListeners();
  }

  List<Map<String, dynamic>> get bannerInsights {
    final List<Map<String, dynamic>> result = [];

    // 1) 최다 감정 - 플랜 전체 기간
    final fullDays = _daysInPlanFullPeriod();
    final fullEmotionCount = <String, int>{};

    for (final d in fullDays) {
      final emotion = d.emotion.trim();
      if (emotion.isEmpty) continue;
      fullEmotionCount[emotion] = (fullEmotionCount[emotion] ?? 0) + 1;
    }

    if (fullEmotionCount.isNotEmpty) {
      final topEmotion = fullEmotionCount.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
      );

      result.add({
        'title': '플랜 기간 동안 ${topEmotion.key} 감정이 가장 많이 기록됐어요.',
        'icon': Icons.mood,
        'color': _bannerColorByType(
          'top_emotion',
          emotion: topEmotion.key,
        ),
        'type': 'top_emotion',
      });
    }

    // 2) 최근 감정 - 최근 7일
    final recentDays = _daysInRecentPeriod('주간');
    final recentEmotionCount = <String, int>{};

    for (final d in recentDays) {
      final emotion = d.emotion.trim();
      if (emotion.isEmpty) continue;
      recentEmotionCount[emotion] = (recentEmotionCount[emotion] ?? 0) + 1;
    }

    if (recentEmotionCount.isNotEmpty) {
      final topRecentEmotion = recentEmotionCount.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
      );

      result.add({
        'title': '최근 7일 동안 ${topRecentEmotion.key} 감정이 가장 많아요.',
        'icon': Icons.schedule,
        'color': _bannerColorByType(
          'recent_emotion',
          emotion: topRecentEmotion.key,
        ),
        'type': 'recent_emotion',
      });
    }

    // 3) 카테고리 감정 - 플랜 전체 기간
    // 카테고리별로 어떤 감정이 가장 많이 기록되는지 계산
    final categoryEmotionCount = <String, Map<String, int>>{};

    for (final d in fullDays) {
      final emotion = d.emotion.trim();
      if (emotion.isEmpty) continue;
      if (d.spendingEntries.isEmpty) continue;

      for (final e in d.spendingEntries) {
        final category = e.category.trim().isNotEmpty ? e.category.trim() : '기타';

        categoryEmotionCount[category] ??= {};
        categoryEmotionCount[category]![emotion] =
            (categoryEmotionCount[category]![emotion] ?? 0) + 1;
      }
    }

    if (categoryEmotionCount.isNotEmpty) {
      String? bestCategory;
      String? bestEmotion;
      int bestCount = 0;

      for (final categoryEntry in categoryEmotionCount.entries) {
        final emotionMap = categoryEntry.value;
        if (emotionMap.isEmpty) continue;

        final topEmotionForCategory = emotionMap.entries.reduce(
              (a, b) => a.value >= b.value ? a : b,
        );

        if (topEmotionForCategory.value > bestCount) {
          bestCount = topEmotionForCategory.value;
          bestCategory = categoryEntry.key;
          bestEmotion = topEmotionForCategory.key;
        }
      }

      result.add({
        'title': '$bestCategory 소비를 할 때 $bestEmotion을 많이 느끼는 편이에요.',
        'icon': Icons.shopping_bag_outlined,
        'color': _bannerColorByType(
          'category_emotion',
          emotion: bestEmotion,
        ),
        'type': 'category_emotion',
      });
    }

    if (result.isEmpty) {
      result.add({
        'title': '소비 기록이 쌓이면 감정 패턴을 알려드릴게요.',
        'icon': Icons.mood,
        'color': const Color(0xFF0062FF),
        'type': 'empty',
      });
    }

    return result;
  }

  Color _bannerColorByType(String type, {String? emotion}) {
    switch (type) {
      case 'top_emotion':
        return const Color(0xFF0062FF); // 메인 블루
      case 'recent_emotion':
        return const Color(0xFF00C853); // 최근 트렌드 (초록)
      case 'category_emotion':
      // 카테고리는 감정 색 기반으로 가는 게 자연스러움
        return emotion != null ? _emotionColor(emotion) : const Color(0xFFFF9800);
      default:
        return const Color(0xFF0062FF);
    }
  }

  Color _emotionColor(String emotion) {
    switch (emotion) {
      case '좋음':
        return const Color(0xFFFFC107);
      case '평온':
        return const Color(0xFF4CAF50);
      case '슬픔':
        return const Color(0xFF2196F3);
      case '스트레스':
        return const Color(0xFFF44336);
      case '동기부여':
        return const Color(0xFF9C27B0);
      case '아무 감정 없음':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF0062FF);
    }
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

  void _setLoading(bool v) {
    _isLoading = v;
  }

  void _setError(String? msg) {
    _error = msg;
  }

  @override
  void dispose() {
    _eventSub.cancel();
    super.dispose();
  }
}
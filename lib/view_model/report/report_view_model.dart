import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, IconData, Icons;
import 'package:intl/intl.dart';

import 'package:sotong/component/theme/app_colors.dart';
import 'package:sotong/services/record_event_bus.dart';
import 'package:sotong/services/plan_saved_event_bus.dart';
import 'package:sotong/services/home_widget_sync_service.dart';

import '../../model/refData/daily_consume.dart';
import '../../repository/record_repository.dart';
import '../../repository/ref_data_repository.dart';
import '../../repository/plan_repository.dart';

import '../../model/record/monthly_record.dart';
import '../../model/record/day_record.dart';
import '../../model/refData/ref_data.dart';
import '../../model/report/report_models.dart';
import '../../model/plan/total_plan.dart';
import '../../repository/auth_repository.dart';
import '../../services/app_session_reset_service.dart';
import '../services/saving_progress_service.dart';

class ReportViewModel extends ChangeNotifier implements SessionResettable {
  ReportViewModel(
      this._recordRepo,
      this._refRepo,
      this._planRepo,
      this._authRepo, {
        RecordEventBus? eventBus,
        PlanSavedEventBus? planSavedBus,
      }) {
    if (eventBus != null) {
      _eventSub = eventBus.stream.listen((_) {
        _spendingDebounce?.cancel();
        _spendingDebounce = Timer(const Duration(milliseconds: 120), () async {
          await refreshAfterSpendingUpdated();
        });
      });
    }

    if (planSavedBus != null) {
      _planSavedSub = planSavedBus.stream.listen((_) {
        _planDebounce?.cancel();
        _planDebounce = Timer(const Duration(milliseconds: 120), () async {
          await refreshAfterPlanUpdated();
        });
      });
    }
  }

  final RecordRepository _recordRepo;
  final RefDataRepository _refRepo;
  final PlanRepository _planRepo;
  final AuthRepository _authRepo;

  final SavingProgressService _savingProgressService =
  const SavingProgressService();

  String? _loadedUid;

  StreamSubscription<RecordUpdatedEvent>? _eventSub;
  StreamSubscription<dynamic>? _planSavedSub;

  Timer? _spendingDebounce;
  Timer? _planDebounce;
  Timer? _savingTicker;

  int _monthCategoryTabIndex = 3;
  int get monthCategoryTabIndex => _monthCategoryTabIndex;

  void setMonthCategoryTabIndex(int index) {
    if (_monthCategoryTabIndex == index) return;
    _monthCategoryTabIndex = index;
    notifyListeners();
  }

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  final NumberFormat _nf = NumberFormat('#,###');

  int _insightIndex = 0;
  int get insightIndex => _insightIndex;

  void setInsightIndex(int i) {
    _insightIndex = i;
    notifyListeners();
  }

  int monthSectionYear = DateTime.now().year;
  int monthSectionMonth = DateTime.now().month;

  void changeMonthSection(int delta) {
    var y = monthSectionYear;
    var m = monthSectionMonth + delta;

    if (m < 1) {
      m = 12;
      y -= 1;
    } else if (m > 12) {
      m = 1;
      y += 1;
    }

    monthSectionYear = y;
    monthSectionMonth = m;
    _rebuildAll();
  }

  ReportRangeType _rangeType = ReportRangeType.weekly;
  ReportRangeType get rangeType => _rangeType;

  void setRangeType(ReportRangeType next) {
    if (_rangeType == next) return;
    _rangeType = next;
    _rebuildAll();
  }

  final Map<String, MonthlyRecord> _monthCache = {};
  RefData? _refData;
  TotalPlan? _latestPlan;

  final Map<String, String> _lastRecordNameByKey = {};

  ReportCategoryBudgetChart? _budgetChart;
  ReportCategoryBudgetChart? get budgetChart => _budgetChart;

  int _incomeTotal = 0;
  int _savingTotal = 0;
  int _fixedExpenseTotal = 0;
  int _variableExpenseTotal = 0;

  int get incomeTotal => _incomeTotal;
  int get savingTotal => _savingTotal;
  int get fixedExpenseTotal => _fixedExpenseTotal;
  int get variableExpenseTotal => _variableExpenseTotal;

  bool _didInit = false;

  Future<void> loadInitial() async {
    final currentUid = _authRepo.cachedUid ?? _authRepo.currentUserId;

    if (_loadedUid != currentUid) {
      _loadedUid = currentUid;
      _resetUserScopedState();
    }

    if (_didInit) return;

    _didInit = true;
    await _rebuildAll();
  }

  void _resetUserScopedState() {
    _didInit = false;

    _monthCache.clear();

    _refData = null;
    _latestPlan = null;

    _lastRecordNameByKey.clear();

    _budgetChart = null;

    _incomeTotal = 0;
    _savingTotal = 0;
    _fixedExpenseTotal = 0;
    _variableExpenseTotal = 0;

    _insightIndex = 0;

    monthSectionYear = DateTime.now().year;
    monthSectionMonth = DateTime.now().month;

    _rangeType = ReportRangeType.weekly;

    _monthCategoryTabIndex = 3;

    _error = null;
    _isLoading = false;
  }

  @override
  void resetSession() {
    _loadedUid = null;

    _savingTicker?.cancel();
    _savingTicker = null;

    _spendingDebounce?.cancel();
    _spendingDebounce = null;

    _planDebounce?.cancel();
    _planDebounce = null;

    _resetUserScopedState();
    notifyListeners();
  }

  ReportRange get chartRange {
    final now = _dateOnly(DateTime.now());

    if (_rangeType == ReportRangeType.weekly) {
      final monday = now.subtract(Duration(days: (now.weekday + 6) % 7));
      final sunday = monday.add(const Duration(days: 6));

      return ReportRange(
        start: _dateOnly(monday),
        end: _dateOnly(sunday),
      );
    } else {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);

      return ReportRange(
        start: _dateOnly(start),
        end: _dateOnly(end),
      );
    }
  }

  ReportRange get spentChartRange {
    final r = chartRange;
    final today = _dateOnly(DateTime.now());

    final end = r.end.isAfter(today) ? today : r.end;

    return ReportRange(
      start: r.start,
      end: end,
    );
  }

  String get rangeLabel {
    return _rangeType == ReportRangeType.weekly ? '주간' : '월간';
  }

  String get chartRangeText {
    final r = chartRange;

    if (_rangeType == ReportRangeType.monthly) {
      return '${r.start.year}년 ${r.start.month}월';
    }

    final s = r.start;
    final e = r.end;

    return '${s.month}/${s.day}(${_dowKor(s.weekday)}) ~ ${e.month}/${e.day}(${_dowKor(e.weekday)})';
  }

  String _dowKor(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  List<Map<String, dynamic>> get insights => _buildReportInsights();

  // =====================================================
  // 배너 인사이트
  // =====================================================

  List<Map<String, dynamic>> _buildReportInsights() {
    final fullRange = _planFullRangeFromLatestPlan();
    final recent7 = _recent7Range();

    final fullTop = _topCategoryStatsInRange(fullRange);
    final recentTop = _topCategoryStatsInRange(recent7);

    final hasAnySpendingInFull = _hasAnySpendingInRange(fullRange);
    final hasAnySpendingInRecent7 = _hasAnySpendingInRange(recent7);

    final withinGoalRatio = _withinDailyGoalRatio(fullRange);
    final missingRecordRatio = _missingRecordDayRatioInFullPeriod();
    final noSpendRecordedRatio = _noSpendRecordedDayRatioInFullPeriod();

    return [
      {
        'title': hasAnySpendingInFull && fullTop != null
            ? '플랜 전체기간에서 평균 ${_nf.format(fullTop.avg)}원으로 ${fullTop.name}가 가장 많아요.'
            : '소비를 기록하면 소비 패턴을 분석해드릴게요.',
        'icon': Icons.pie_chart,
        'color': AppColors.primary,
      },
      {
        'title': hasAnySpendingInRecent7 && recentTop != null
            ? '최근 7일 동안 평균 ${_nf.format(recentTop.avg)}원으로 ${recentTop.name}가 가장 많아요.'
            : '최근 소비 기록이 쌓이면 분석을 보여드릴게요.',
        'icon': Icons.access_time,
        'color': const Color(0xFF43A047),
      },
      {
        'title': _hasAnyDailyGoalConfigured(fullRange)
            ? _dailyGoalBannerMessage(withinGoalRatio)
            : '예산을 설정하면 소비 관리 상태를 볼 수 있어요.',
        'icon': Icons.savings,
        'color': _dailyGoalBannerColor(withinGoalRatio),
      },
      {
        'title': _missingRecordBannerMessage(missingRecordRatio),
        'icon': Icons.edit_note,
        'color': const Color(0xFF607D8B),
      },
      {
        'title': _noSpendRecordedBannerMessage(noSpendRecordedRatio),
        'icon': Icons.remove_shopping_cart,
        'color': const Color(0xFF8E24AA),
      },
    ];
  }

  ReportRange _planFullRangeFromLatestPlan() {
    final now = _dateOnly(DateTime.now());
    final planStart = _latestPlan?.startDate;

    if (planStart == null) {
      return ReportRange(start: now, end: now);
    }

    final start = _dateOnly(planStart);

    return ReportRange(start: start, end: now);
  }

  int _daysCount(ReportRange r) {
    final s = _dateOnly(r.start);
    final e = _dateOnly(r.end);

    return e.difference(s).inDays + 1;
  }

  DayRecord? _findDayRecord(DateTime date) {
    final monthKey = _monthKey(DateTime(date.year, date.month, 1));
    final monthly = _monthCache[monthKey];

    if (monthly == null) return null;

    final dateKey = DateFormat('yyyy-MM-dd').format(_dateOnly(date));

    return monthly.days[dateKey];
  }

  bool _hasAnySpendingInRange(ReportRange r) {
    return _sumSpentInRange(r) > 0;
  }

  ({String name, int total, int avg})? _topCategoryStatsInRange(ReportRange r) {
    const etcKey = 'etc';

    final days = _daysInRange(r);

    if (days.isEmpty) return null;

    final spentByKey = <String, int>{};
    final activeDaysByKey = <String, int>{};

    for (final d in days) {
      final daySumByKey = <String, int>{};

      for (final e in d.spendingEntries) {
        final key = e.categoryKey.trim().isEmpty
            ? etcKey
            : e.categoryKey.trim();

        daySumByKey[key] = (daySumByKey[key] ?? 0) + e.amount.round();
      }

      daySumByKey.forEach((key, amount) {
        spentByKey[key] = (spentByKey[key] ?? 0) + amount;

        if (amount > 0) {
          activeDaysByKey[key] = (activeDaysByKey[key] ?? 0) + 1;
        }
      });
    }

    if (spentByKey.isEmpty) return null;

    final top = spentByKey.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
    );

    final topKey = top.key;
    final total = top.value;
    final activeDays = activeDaysByKey[topKey] ?? 1;
    final avg = (total / activeDays).round();

    final name = _planNameForKey(topKey) ??
        _lastRecordNameByKey[topKey] ??
        (topKey == etcKey ? '기타' : topKey);

    return (name: name, total: total, avg: avg);
  }

  int _plannedDailyAmountOn(DateTime date) {
    final refData = _refData;
    if (refData == null) return 0;

    final day = _dateOnly(date);
    int total = 0;

    for (final dc in refData.dailyConsumeMap.values) {
      if (!dc.isActive) continue;

      final start = _dateOnly(dc.startDate);
      final end = _dateOnly(dc.endDate);

      if (day.isBefore(start) || day.isAfter(end)) continue;

      for (final e in dc.entries) {
        total += e.amount.round();
      }
    }

    return total;
  }

  int _withinDailyGoalRatio(ReportRange r) {
    DateTime cursor = _dateOnly(r.start);
    final end = _dateOnly(r.end);

    int eligibleDays = 0;
    int successDays = 0;

    while (!cursor.isAfter(end)) {
      final planned = _plannedDailyAmountOn(cursor);

      if (planned > 0) {
        eligibleDays++;

        final spent = _spentOnDate(cursor);

        if (spent <= planned) {
          successDays++;
        }
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    if (eligibleDays == 0) return 0;

    return ((successDays / eligibleDays) * 100).round();
  }

  bool _hasAnyDailyGoalConfigured(ReportRange r) {
    DateTime cursor = _dateOnly(r.start);
    final end = _dateOnly(r.end);

    while (!cursor.isAfter(end)) {
      if (_plannedDailyAmountOn(cursor) > 0) return true;

      cursor = cursor.add(const Duration(days: 1));
    }

    return false;
  }

  String _dailyGoalBannerMessage(int ratio) {
    if (ratio < 30) {
      return '목표한 일일금액 안으로 소비한 날이 $ratio%예요. 흐름을 한 번 점검해보세요.';
    }

    if (ratio < 60) {
      return '목표한 일일금액 안으로 소비한 날이 $ratio%예요. 조금씩 관리되고 있어요.';
    }

    if (ratio < 80) {
      return '목표한 일일금액 안으로 소비한 날이 $ratio%예요. 잘 관리하고 있어요.';
    }

    return '목표한 일일금액 안으로 소비한 날이 $ratio%예요. 아주 잘 관리하고 있어요.';
  }

  Color _dailyGoalBannerColor(int ratio) {
    if (ratio < 30) {
      return const Color(0xFFD32F2F);
    }

    if (ratio < 60) {
      return const Color(0xFFF57C00);
    }

    if (ratio < 80) {
      return const Color(0xFF43A047);
    }

    return const Color(0xFF0062FF);
  }

  int _missingRecordDayRatioInFullPeriod() {
    final fullRange = _planFullRangeFromLatestPlan();
    final totalDays = _daysCount(fullRange);

    if (totalDays <= 0) return 0;

    int missingDays = 0;

    DateTime cursor = _dateOnly(fullRange.start);
    final end = _dateOnly(fullRange.end);

    while (!cursor.isAfter(end)) {
      final day = _findDayRecord(cursor);

      if (day == null) {
        missingDays++;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return ((missingDays / totalDays) * 100).round();
  }

  int _noSpendRecordedDayRatioInFullPeriod() {
    final fullRange = _planFullRangeFromLatestPlan();
    final totalDays = _daysCount(fullRange);

    if (totalDays <= 0) return 0;

    int noSpendDays = 0;

    DateTime cursor = _dateOnly(fullRange.start);
    final end = _dateOnly(fullRange.end);

    while (!cursor.isAfter(end)) {
      final day = _findDayRecord(cursor);

      if (day != null &&
          day.spendingEntries.isEmpty &&
          day.totalSpendingAmount == 0) {
        noSpendDays++;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return ((noSpendDays / totalDays) * 100).round();
  }

  String _missingRecordBannerMessage(int ratio) {
    if (ratio == 0) {
      return '플랜 전체기간 중 기록 없는 날은 0%예요. 기록 흐름이 잘 이어지고 있어요.';
    }

    if (ratio < 50) {
      return '플랜 전체기간 중 기록 없는 날은 $ratio%예요. 빠진 날을 기록해보세요.';
    }

    return '플랜 전체기간 중 기록 없는 날은 $ratio%예요. 빈 날부터 가볍게 채워보세요.';
  }

  String _noSpendRecordedBannerMessage(int ratio) {
    if (ratio == 0) {
      return '플랜 전체기간 중 무지출로 기록한 날은 0%예요.';
    }

    if (ratio < 20) {
      return '플랜 전체기간 중 무지출로 기록한 날은 $ratio%예요.';
    }

    if (ratio < 50) {
      return '플랜 전체기간 중 무지출로 기록한 날은 $ratio%예요. 무지출 흐름도 보이고 있어요.';
    }

    return '플랜 전체기간 중 무지출로 기록한 날은 $ratio%예요. 무지출 기록이 잘 쌓이고 있어요.';
  }

  int _spentOnDate(DateTime date) {
    final day = _findDayRecord(date);

    if (day == null) return 0;

    return day.spendingEntries.fold<int>(
      0,
          (sum, e) => sum + e.amount.round(),
    );
  }

  List<({String name, int spent})> unplannedSpentListForChartRange({
    int maxItems = 8,
  }) {
    final r = chartRange;

    return _unplannedSpentList(
      range: r,
      maxItems: maxItems,
    );
  }

  List<({String date, int spent})> plannedSpentDetailListForChartRange(
      String categoryKey, {
        int maxItems = 8,
      }) {
    final r = chartRange;
    final days = _daysInRange(r);

    final out = <({String date, int spent})>[];

    for (final d in days) {
      int sum = 0;

      for (final e in d.spendingEntries) {
        if (e.categoryKey.trim() == categoryKey.trim()) {
          sum += e.amount.round();
        }
      }

      if (sum > 0) {
        final weekdayKor = switch (d.date.weekday) {
          1 => '월',
          2 => '화',
          3 => '수',
          4 => '목',
          5 => '금',
          6 => '토',
          7 => '일',
          _ => '',
        };

        out.add((
        date: '${d.date.month}/${d.date.day}($weekdayKor)',
        spent: sum,
        ));
      }
    }

    return out.take(maxItems).toList();
  }

  List<({String name, int spent})> _unplannedSpentList({
    required ReportRange range,
    required int maxItems,
  }) {
    const etcKey = 'etc';

    final plannedKeys = <String>{};
    final refData = _refData;

    if (refData != null) {
      for (final dc in refData.dailyConsumeMap.values) {
        final overlap = _overlapDays(
          rangeStart: range.start,
          rangeEnd: range.end,
          docStart: _dateOnly(dc.startDate),
          docEnd: _dateOnly(dc.endDate),
        );

        if (overlap <= 0) continue;

        for (final e in dc.entries) {
          final k = e.categoryKey.trim();

          if (k.isEmpty) continue;

          plannedKeys.add(k);
        }
      }
    }

    final spentByKey = <String, int>{};
    final days = _daysInRange(range);

    for (final d in days) {
      for (final e in d.spendingEntries) {
        final k = e.categoryKey.trim().isEmpty
            ? etcKey
            : e.categoryKey.trim();

        spentByKey[k] = (spentByKey[k] ?? 0) + e.amount.round();

        final keyTrim = e.categoryKey.trim();
        final nameTrim = e.category.trim();

        if (keyTrim.isNotEmpty && nameTrim.isNotEmpty) {
          _lastRecordNameByKey[keyTrim] = nameTrim;
        }
      }
    }

    final unplanned = <String, int>{};

    spentByKey.forEach((k, v) {
      if (k == etcKey) return;

      if (!plannedKeys.contains(k)) {
        unplanned[k] = (unplanned[k] ?? 0) + v;
      }
    });

    if (unplanned.isEmpty) return const [];

    final items = unplanned.entries.map((e) {
      final key = e.key;
      final spent = e.value;

      final name = (_lastRecordNameByKey[key]?.trim().isNotEmpty ?? false)
          ? _lastRecordNameByKey[key]!.trim()
          : key;

      return (name: name, spent: spent);
    }).toList();

    items.sort((a, b) => b.spent.compareTo(a.spent));

    return items.take(maxItems).toList();
  }

  Future<void> _rebuildAll() async {
    _setLoading(true);
    _setError(null);
    notifyListeners();

    try {
      _latestPlan = await _planRepo.getLatestPlanForCurrentUser();
      _refData = await _refRepo.loadAll();

      final fullRange = _planFullRangeFromLatestPlan();
      await _ensureMonthsLoadedForRange(fullRange);

      final r = chartRange;
      await _ensureMonthsLoadedForRange(r);

      await _ensureMonthLoaded(
        DateTime(monthSectionYear, monthSectionMonth, 1),
      );

      _budgetChart = _buildBudgetChart(range: r);

      _recomputeMonthTotalsFromRecords();

      _setError(null);
    } catch (e) {
      _setError('리포트 로드 실패: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
      unawaited(
        HomeWidgetSyncService.syncReportBannerItems(insights),
      );
    }
  }

  Future<void> refreshAfterSpendingUpdated() async {
    _invalidateMonthsForRefresh();
    await _rebuildAll();
  }

  Future<void> refreshAfterPlanUpdated() async {
    _invalidateMonthsForRefresh();

    _refData = null;
    _latestPlan = null;
    _budgetChart = null;

    await _rebuildAll();
  }

  void startSavingTicker() {
    _savingTicker?.cancel();

    _savingTicker = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        _recomputeMonthTotalsFromRecords();
        notifyListeners();
      },
    );
  }

  void stopSavingTicker() {
    _savingTicker?.cancel();
    _savingTicker = null;
  }

  void _invalidateMonthsForRefresh() {
    final r = chartRange;
    final months = _monthsCovered(_dateOnly(r.start), _dateOnly(r.end));

    for (final m in months) {
      _monthCache.remove(_monthKey(DateTime(m.year, m.month, 1)));
    }

    final full = _planFullRangeFromLatestPlan();
    final fullMonths = _monthsCovered(
      _dateOnly(full.start),
      _dateOnly(full.end),
    );

    for (final m in fullMonths) {
      _monthCache.remove(_monthKey(DateTime(m.year, m.month, 1)));
    }

    _monthCache.remove(
      _monthKey(DateTime(monthSectionYear, monthSectionMonth, 1)),
    );
  }

  ReportRange? _effectiveBudgetRangeForChart(ReportRange raw) {
    final plan = _latestPlan;

    DateTime start = _dateOnly(raw.start);
    DateTime end = _dateOnly(raw.end);

    if (plan != null) {
      final rawPlanStart = plan.startDate ?? plan.creationDate;
      final rawPlanEnd = plan.modEndDate ?? plan.endDate;

      if (rawPlanStart != null) {
        final planStart = _dateOnly(rawPlanStart);
        if (planStart.isAfter(start)) {
          start = planStart;
        }
      }

      if (rawPlanEnd != null) {
        final planEnd = _dateOnly(rawPlanEnd);
        if (planEnd.isBefore(end)) {
          end = planEnd;
        }
      }
    }

    if (end.isBefore(start)) return null;

    return ReportRange(start: start, end: end);
  }

  String? _dailyConsumeIdFromMiniPlanOn(DateTime date) {
    final plan = _latestPlan;
    if (plan == null) return null;

    final day = _dateOnly(date);

    final key =
        '${day.year.toString().padLeft(4, '0')}'
        '${day.month.toString().padLeft(2, '0')}';

    final subPlan = plan.subPlans[key];

    if (subPlan != null) {
      for (final mini in subPlan.orderedMinis()) {
        final start = _dateOnly(mini.startDate);
        final end = _dateOnly(mini.endDate);

        if (!day.isBefore(start) && !day.isAfter(end)) {
          final id = mini.dailyConsumeId.trim();
          return id.isEmpty ? null : id;
        }
      }
    }

    return null;
  }

  DailyConsume? _dailyConsumeFromMiniPlanOn(DateTime date) {
    final refData = _refData;
    if (refData == null) return null;

    final dailyId = _dailyConsumeIdFromMiniPlanOn(date);
    if (dailyId == null) return null;

    return refData.dailyConsumeMap[dailyId];
  }

  /// miniPlan 연결이 없는 예외 상황에서만 쓰는 fallback.
  /// 기존 방식처럼 날짜 범위로 찾되, 같은 날짜에 여러 개가 겹치면
  /// startDate가 가장 늦은 것 하나만 선택한다.
  DailyConsume? _fallbackDailyConsumeOn(DateTime date) {
    final refData = _refData;
    if (refData == null) return null;

    final day = _dateOnly(date);

    final candidates = refData.dailyConsumeMap.values.where((dc) {
      if (!dc.isActive) return false;

      final start = _dateOnly(dc.startDate);
      final end = _dateOnly(dc.endDate);

      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final startCompare = b.startDate.compareTo(a.startDate);
      if (startCompare != 0) return startCompare;
      return b.id.compareTo(a.id);
    });

    return candidates.first;
  }

  ReportCategoryBudgetChart _buildBudgetChart({
    required ReportRange range,
  }) {
    const etcKey = 'etc';

    final plannedByKey = <String, int>{};
    final nameByKey = <String, String>{};
    final emojiByKey = <String, String>{};
    final spentByKey = <String, int>{};

    // ✅ 예산은 차트 전체 기간을 그대로 쓰되,
    // 플랜 시작일/종료일 밖은 제외한다.
    //
    // 예:
    // 화면 표시: 6/29 ~ 7/5
    // 플랜 시작: 7/1
    // 예산 계산: 7/1 ~ 7/5
    final budgetRange = _effectiveBudgetRangeForChart(range);

    if (budgetRange != null) {
      DateTime cursor = _dateOnly(budgetRange.start);
      final end = _dateOnly(budgetRange.end);

      while (!cursor.isAfter(end)) {
        // ✅ 1순위: 현재 날짜를 담당하는 miniPlan.dailyConsumeId
        // ✅ 2순위: 예외 상황에서만 날짜 범위 fallback
        final dc = _dailyConsumeFromMiniPlanOn(cursor) ??
            _fallbackDailyConsumeOn(cursor);

        if (dc != null) {
          for (final e in dc.entries) {
            final key = e.categoryKey.trim().isEmpty
                ? etcKey
                : e.categoryKey.trim();

            // ✅ 하루씩 돌기 때문에 amount를 overlap 곱하지 않고 1일치만 더함
            final add = e.amount.round();

            plannedByKey[key] = (plannedByKey[key] ?? 0) + add;

            nameByKey[key] ??=
            e.category.trim().isEmpty ? '기타' : e.category.trim();

            emojiByKey[key] ??=
            e.emoji.trim().isEmpty ? '💰' : e.emoji.trim();
          }
        }

        cursor = cursor.add(const Duration(days: 1));
      }
    }

    // ✅ 실제 소비는 기존처럼 오늘까지만 본다.
    // 기존 spentChartRange가 미래 날짜를 오늘로 잘라주고 있음.
    final spentDays = _daysInRange(spentChartRange);

    for (final d in spentDays) {
      for (final e in d.spendingEntries) {
        final key = e.categoryKey.trim().isEmpty
            ? etcKey
            : e.categoryKey.trim();

        spentByKey[key] = (spentByKey[key] ?? 0) + e.amount.round();

        final keyTrim = e.categoryKey.trim();
        final nameTrim = e.category.trim();

        if (keyTrim.isNotEmpty && nameTrim.isNotEmpty) {
          _lastRecordNameByKey[keyTrim] = nameTrim;
        }
      }
    }

    nameByKey.putIfAbsent(etcKey, () => '기타');
    emojiByKey.putIfAbsent(etcKey, () => '🧩');

    int etcSpent = spentByKey[etcKey] ?? 0;

    spentByKey.forEach((k, v) {
      if (k == etcKey) return;

      if (!plannedByKey.containsKey(k)) {
        etcSpent += v;
      }
    });

    spentByKey[etcKey] = etcSpent;

    final keys = plannedByKey.keys.toSet();

    if ((spentByKey[etcKey] ?? 0) > 0) {
      keys.add(etcKey);
    }

    final rows = keys.map((k) {
      final name = nameByKey[k] ??
          (k == etcKey ? '기타' : (_lastRecordNameByKey[k] ?? k));

      return ReportCategoryBudgetRow(
        categoryKey: k,
        name: name,
        emoji: emojiByKey[k] ?? (k == etcKey ? '🧩' : '💰'),
        planned: plannedByKey[k] ?? 0,
        spent: spentByKey[k] ?? 0,
        isTotal: false,
      );
    }).toList();

    rows.sort((a, b) => b.spent.compareTo(a.spent));

    final etcIndex = rows.indexWhere((e) => e.categoryKey == etcKey);

    if (etcIndex >= 0) {
      final etc = rows.removeAt(etcIndex);
      rows.add(etc);
    }

    final totalSpent = rows.fold<int>(0, (s, r) => s + r.spent);
    final totalPlanned = rows.fold<int>(0, (s, r) => s + r.planned);

    rows.add(
      ReportCategoryBudgetRow(
        categoryKey: '__total__',
        name: '총소비',
        emoji: '📌',
        planned: totalPlanned,
        spent: totalSpent,
        isTotal: true,
      ),
    );

    return ReportCategoryBudgetChart(
      range: range,
      rows: List.unmodifiable(rows),
    );
  }

  void _recomputeMonthTotalsFromRecords() {
    final today = _dateOnly(DateTime.now());

    final monthStart = DateTime(monthSectionYear, monthSectionMonth, 1);
    final rawMonthEnd = DateTime(monthSectionYear, monthSectionMonth + 1, 0);

    final isCurrentMonth =
        monthStart.year == today.year && monthStart.month == today.month;

    final monthEnd = isCurrentMonth ? today : rawMonthEnd;

    final plan = _latestPlan;

    DateTime effectiveStart = monthStart;
    DateTime effectiveEnd = monthEnd;

    if (plan != null) {
      final rawPlanStart = plan.startDate ?? plan.creationDate;
      final rawPlanEnd = plan.modEndDate ?? plan.endDate;

      if (rawPlanStart != null) {
        final planStart = _dateOnly(rawPlanStart);

        if (planStart.isAfter(effectiveStart)) {
          effectiveStart = planStart;
        }
      }

      if (rawPlanEnd != null) {
        final planEnd = _dateOnly(rawPlanEnd);

        if (planEnd.isBefore(effectiveEnd)) {
          effectiveEnd = planEnd;
        }
      }
    }

    final monthly = _monthCache[_monthKey(monthStart)];

    final planMonthlyIncome = _plannedMonthlyIncomeForMonth(monthStart);
    final planFixedExpense = _plannedFixedExpenseForMonth(monthStart);

    final recordedIncome = effectiveEnd.isBefore(effectiveStart)
        ? 0
        : _recordedIncomeForRange(
      monthly: monthly,
      start: effectiveStart,
      end: effectiveEnd,
    );

    final variableExpense = effectiveEnd.isBefore(effectiveStart)
        ? 0
        : _mixedVariableExpenseForMonth(
      monthly: monthly,
      monthStart: effectiveStart,
      monthEnd: effectiveEnd,
    );

    final savingProgress = effectiveEnd.isBefore(effectiveStart)
        ? SavingProgressResult.zero()
        : _savingProgressService.calculate(
      plan: _latestPlan,
      monthlyCache: _monthCache,
      start: effectiveStart,
      end: effectiveEnd,
      mode: SavingProgressMode.rangeWithoutCurrentAsset,
      now: DateTime.now(),
    );

    _incomeTotal = planMonthlyIncome + recordedIncome;
    _fixedExpenseTotal = planFixedExpense;
    _variableExpenseTotal = variableExpense;

    // 레포트 저축:
    // 보유금액 제외 + 선택 월 안에서 실제 플랜 기간에 해당하는 누적 저축분.
    _savingTotal = savingProgress.liveSavedAmount.round();
  }

  int _recordedIncomeForRange({
    required MonthlyRecord? monthly,
    required DateTime start,
    required DateTime end,
  }) {
    if (monthly == null) return 0;

    final s = _dateOnly(start);
    final e = _dateOnly(end);

    int total = 0;

    for (final day in monthly.days.values) {
      final date = _dateOnly(day.date);

      if (date.isBefore(s) || date.isAfter(e)) continue;

      for (final entry in day.incomeEntries) {
        total += entry.amount.round();
      }
    }

    return total;
  }

  int _actualSavedForRange({
    required DateTime start,
    required DateTime end,
  }) {
    double total = 0;

    var cursor = _dateOnly(start);
    final last = _dateOnly(end);
    final today = _dateOnly(DateTime.now());

    while (!cursor.isAfter(last)) {
      final dayRecord = _findDayRecord(cursor);

      final plannedBudget = _plannedDailyAmountOn(cursor);
      final plannedDailySaving = _plannedDailyNetForDate(cursor);

      final actualSpending =
      dayRecord == null ? 0 : _actualSpendingFromDay(dayRecord);

      final extraIncome = dayRecord?.totalIncomeAmount ?? 0;
      final hasSpendingEntries = dayRecord?.spendingEntries.isNotEmpty ?? false;

      if (cursor.isBefore(today) || hasSpendingEntries) {
        total += plannedDailySaving +
            plannedBudget -
            actualSpending +
            extraIncome;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    final includesToday =
        !today.isBefore(_dateOnly(start)) && !today.isAfter(_dateOnly(end));

    if (includesToday && !_isSavingConfirmedForDate(today)) {
      total += _guideSumForToday();
    }

    return total.round();
  }

  bool _isSavingConfirmedForDate(DateTime date) {
    final record = _findDayRecord(date);

    return record != null && record.spendingEntries.isNotEmpty;
  }

  double _guideSumForToday() {
    final perSecond = _plannedDailyNetForDate(DateTime.now()) / 86400.0;

    if (perSecond == 0) return 0;

    final now = DateTime.now();
    final todayStart = _dateOnly(now);
    final elapsedSeconds = now.difference(todayStart).inSeconds;

    return elapsedSeconds * perSecond;
  }

  double _plannedDailyNetForDate(DateTime date) {
    final plan = _latestPlan;

    if (plan == null) return 0;

    final normalized = _dateOnly(date);
    final key = DateFormat('yyyyMM').format(normalized);
    final subPlan = plan.subPlans[key];

    if (subPlan == null) return 0;

    final minis = subPlan.orderedMinis();

    if (minis.isEmpty) return 0;

    for (final mini in minis) {
      final start = _dateOnly(mini.startDate);
      final end = _dateOnly(mini.endDate);

      if (!normalized.isBefore(start) && !normalized.isAfter(end)) {
        final daysInMonth = DateTime(
          normalized.year,
          normalized.month + 1,
          0,
        ).day;

        final monthlyNet = mini.monthlyIncomeAmount -
            mini.monthlyConsumeAmount -
            (mini.dailyConsumeAmount * daysInMonth);

        return monthlyNet / daysInMonth;
      }
    }

    return 0;
  }

  int _plannedMonthlyIncomeForMonth(DateTime monthStart) {
    final refData = _refData;

    if (refData == null) return 0;

    final targetMonth = DateTime(monthStart.year, monthStart.month, 1);

    int total = 0;

    for (final income in refData.monthlyIncomeMap.values) {
      if (!income.isActive) continue;
      if (!_containsMonth(income.yearMonthList, targetMonth)) continue;

      for (final e in income.entries) {
        total += e.amount.round();
      }
    }

    return total;
  }

  int _plannedFixedExpenseForMonth(DateTime monthStart) {
    final refData = _refData;

    if (refData == null) return 0;

    final targetMonth = DateTime(monthStart.year, monthStart.month, 1);

    int total = 0;

    for (final consume in refData.monthlyConsumeMap.values) {
      if (!consume.isActive) continue;
      if (!_containsMonth(consume.yearMonthList, targetMonth)) continue;

      for (final e in consume.entries) {
        total += e.amount.round();
      }
    }

    return total;
  }

  bool _containsMonth(List<DateTime> months, DateTime targetMonth) {
    return months.any(
          (m) => m.year == targetMonth.year && m.month == targetMonth.month,
    );
  }

  int _recordedIncomeForMonth(MonthlyRecord? monthly) {
    if (monthly == null) return 0;

    int total = 0;

    for (final day in monthly.days.values) {
      for (final e in day.incomeEntries) {
        total += e.amount.round();
      }
    }

    return total;
  }

  int _mixedVariableExpenseForMonth({
    required MonthlyRecord? monthly,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) {
    int total = 0;

    var cursor = _dateOnly(monthStart);
    final end = _dateOnly(monthEnd);

    while (!cursor.isAfter(end)) {
      final dayRecord = _dayRecordInMonthly(monthly, cursor);

      if (_hasUserRecord(dayRecord)) {
        total += _actualSpendingFromDay(dayRecord!);
      } else {
        total += _plannedDailyAmountOn(cursor);
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return total;
  }

  DayRecord? _dayRecordInMonthly(
      MonthlyRecord? monthly,
      DateTime date,
      ) {
    if (monthly == null) return null;

    final dateKey = DateFormat('yyyy-MM-dd').format(_dateOnly(date));

    return monthly.days[dateKey];
  }

  bool _hasUserRecord(DayRecord? day) {
    if (day == null) return false;

    if (day.isAutoGenerated) return false;

    return day.spendingEntries.isNotEmpty ||
        day.incomeEntries.isNotEmpty ||
        day.totalSpendingAmount > 0 ||
        day.totalIncomeAmount > 0 ||
        day.emotion.trim().isNotEmpty ||
        day.comment.trim().isNotEmpty;
  }

  int _actualSpendingFromDay(DayRecord day) {
    final entrySum = day.spendingEntries.fold<int>(
      0,
          (sum, e) => sum + e.amount.round(),
    );

    if (entrySum > 0) return entrySum;

    return day.totalSpendingAmount;
  }

  List<DayRecord> _daysInRange(ReportRange r) {
    final start = _dateOnly(r.start);
    final end = _dateOnly(r.end);

    final out = <DayRecord>[];
    final months = _monthsCovered(start, end);

    for (final m in months) {
      final mm = _monthCache[_monthKey(m)];

      if (mm == null) continue;

      for (final d in mm.days.values) {
        final day = _dateOnly(d.date);

        if (day.isBefore(start) || day.isAfter(end)) continue;

        for (final e in d.spendingEntries) {
          final key = e.categoryKey.trim();

          if (key.isEmpty) continue;

          final name = e.category.trim();

          if (name.isNotEmpty) {
            _lastRecordNameByKey[key] = name;
          }
        }

        out.add(d);
      }
    }

    out.sort((a, b) => a.date.compareTo(b.date));

    return out;
  }

  ReportRange _recent7Range() {
    final now = _dateOnly(DateTime.now());
    final start = now.subtract(const Duration(days: 6));

    return ReportRange(start: start, end: now);
  }

  ReportRange _previous7Range() {
    final now = _dateOnly(DateTime.now());
    final end = now.subtract(const Duration(days: 7));
    final start = end.subtract(const Duration(days: 6));

    return ReportRange(start: start, end: end);
  }

  int _sumSpentInRange(ReportRange r) {
    final days = _daysInRange(r);

    int sum = 0;

    for (final d in days) {
      for (final e in d.spendingEntries) {
        sum += e.amount.round();
      }
    }

    return sum;
  }

  int _sumPlannedInRange(ReportRange r) {
    final refData = _refData;

    if (refData == null) return 0;

    int sum = 0;

    for (final dc in refData.dailyConsumeMap.values) {
      final overlap = _overlapDays(
        rangeStart: r.start,
        rangeEnd: r.end,
        docStart: _dateOnly(dc.startDate),
        docEnd: _dateOnly(dc.endDate),
      );

      if (overlap <= 0) continue;

      for (final e in dc.entries) {
        sum += (e.amount * overlap).round();
      }
    }

    return sum;
  }

  String? _topCategoryNameInRange(ReportRange r) {
    const etcKey = 'etc';

    final days = _daysInRange(r);
    final spentByKey = <String, int>{};

    for (final d in days) {
      for (final e in d.spendingEntries) {
        final key = e.categoryKey.trim().isEmpty
            ? etcKey
            : e.categoryKey.trim();

        spentByKey[key] = (spentByKey[key] ?? 0) + e.amount.round();
      }
    }

    if (spentByKey.isEmpty) return null;

    final top = spentByKey.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
    );

    final topKey = top.key;

    final planName = _planNameForKey(topKey);

    if (planName != null && planName.trim().isNotEmpty) {
      return planName.trim();
    }

    final recordName = _lastRecordNameByKey[topKey];

    if (recordName != null && recordName.trim().isNotEmpty) {
      return recordName.trim();
    }

    return topKey == etcKey ? '기타' : topKey;
  }

  String? _planNameForKey(String key) {
    final refData = _refData;

    if (refData == null) return null;

    for (final dc in refData.dailyConsumeMap.values) {
      for (final e in dc.entries) {
        if (e.categoryKey.trim() == key.trim()) {
          final name = e.category.trim();

          if (name.isNotEmpty) return name;
        }
      }
    }

    return null;
  }

  int _overlapDays({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime docStart,
    required DateTime docEnd,
  }) {
    final rs = _dateOnly(rangeStart);
    final re = _dateOnly(rangeEnd);
    final ds = _dateOnly(docStart);
    final de = _dateOnly(docEnd);

    final start = rs.isAfter(ds) ? rs : ds;
    final end = re.isBefore(de) ? re : de;

    if (end.isBefore(start)) return 0;

    return end.difference(start).inDays + 1;
  }

  Future<void> _ensureMonthsLoadedForRange(ReportRange r) async {
    final months = _monthsCovered(
      _dateOnly(r.start),
      _dateOnly(r.end),
    );

    for (final m in months) {
      await _ensureMonthLoaded(DateTime(m.year, m.month, 1));
    }
  }

  Future<void> _ensureMonthLoaded(DateTime anchorMonthFirstDay) async {
    final key = _monthKey(anchorMonthFirstDay);

    if (_monthCache.containsKey(key)) return;

    final loaded = await _recordRepo.loadMonthlyRecordByDate(anchorMonthFirstDay);
    _monthCache[key] = loaded;

    final prev = DateTime(
      anchorMonthFirstDay.year,
      anchorMonthFirstDay.month - 1,
      1,
    );

    final next = DateTime(
      anchorMonthFirstDay.year,
      anchorMonthFirstDay.month + 1,
      1,
    );

    if (!_monthCache.containsKey(_monthKey(prev))) {
      final prevLoaded = await _recordRepo.loadMonthlyRecordByDate(prev);
      _monthCache[_monthKey(prev)] = prevLoaded;
    }

    if (!_monthCache.containsKey(_monthKey(next))) {
      final nextLoaded = await _recordRepo.loadMonthlyRecordByDate(next);
      _monthCache[_monthKey(next)] = nextLoaded;
    }
  }

  List<DateTime> _monthsCovered(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, 1);
    final e = DateTime(end.year, end.month, 1);

    final out = <DateTime>[];
    var cursor = s;

    while (!cursor.isAfter(e)) {
      out.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return out;
  }

  DateTime _dateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  String _monthKey(DateTime d) {
    return DateFormat('yyyy-MM').format(d);
  }

  void _setLoading(bool v) {
    _isLoading = v;
  }

  void _setError(String? msg) {
    _error = msg;
  }

  @override
  void dispose() {
    _savingTicker?.cancel();

    _spendingDebounce?.cancel();
    _planDebounce?.cancel();

    _eventSub?.cancel();
    _planSavedSub?.cancel();

    super.dispose();
  }
}
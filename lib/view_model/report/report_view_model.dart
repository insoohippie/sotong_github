// lib/view_model/report/report_view_model.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

import 'package:sotong_local/repository/record_repository.dart';
import 'package:sotong_local/model/record/monthly_spending.dart';
import 'package:sotong_local/model/record/day_spending.dart';
import 'package:sotong_local/model/record/spending_entry.dart';
import 'package:sotong_local/services/spending_event_bus.dart';

class ReportViewModel extends ChangeNotifier {
  final RecordRepository _recordRepository;
  late final StreamSubscription<SpendingUpdatedEvent> _spendingSub;

  ReportViewModel(this._recordRepository, SpendingEventBus eventBus) {
    _selectedBaseDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

    _spendingSub = eventBus.stream.listen((_) {
      reloadForCurrentMonth();
    });
  }

  // ───────── 상태 ─────────

  bool _isLoading = false;
  String? _error;

  late DateTime _selectedBaseDate;

  String budgetPeriod = '월간';
  String selectedCategory = '변동소비';
  bool isCategoryDropdownOpen = false;

  int currentInsightIndex = 0;

  MonthlySpending? _monthly;

  bool get hasData => _monthly != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get selectedMonth => _selectedBaseDate.month;
  int get selectedYear => _selectedBaseDate.year;

  // ───────── 집계 데이터(상단 카드: 선택된 월 기준 유지) ─────────

  Map<String, int> _monthlyCategorySpent = {};
  Map<String, int> _weeklyCategorySpent = {}; // 혹시 향후 사용 대비 유지

  int incomeTotal = 0;
  int fixedExpenseTotal = 0;
  int variableExpenseTotal = 0;
  int savingTotal = 0;

  /// 소비 수치 중심 인사이트 5종 (총 소비, 하루 평균, 최다 카테고리, 예산 대비, 소비 추세)
  List<Map<String, dynamic>> get insights => _buildReportInsights();

  // ✅ 최근 7/30일 차트 집계를 위해 여러 월을 캐시
  final Map<String, MonthlySpending> _monthCache = {}; // key: 'yyyy-MM'

  // ✅ 아직 플랜 예산 연결 전: 하루소비한도 하드코딩(테스트용)
  // TODO: 나중에 Plan에서 가져와서 세팅
  int hardDailySpendingLimit = 20000;

  // ───────── 차트 데이터 (여기만 "최근 7/30일" 기준) ─────────
  // ✅ 마지막 축: '총소비' = 모든 카테고리 합 spent
  // ✅ '총소비'의 budget = 하루소비한도 * (월간=30, 주간=7)
  List<Map<String, dynamic>> get currentBudgetData {
    final days = _daysInRecentPeriod(budgetPeriod);

    // 1) spent 집계
    final Map<String, int> spentByCategory = {};
    int totalSpentAll = 0;

    for (final d in days) {
      for (final e in d.entries) {
        final cat = e.category.trim();
        if (cat.isEmpty) continue;

        final amt = (e.amount as num).round(); // double -> int
        if (amt == 0) continue;

        spentByCategory[cat] = (spentByCategory[cat] ?? 0) + amt;
        totalSpentAll += amt;
      }
    }

    // 2) ✅ 임시 카테고리 예산(예산 연결 전 UI 테스트)
    //    - 여기 없는 카테고리는 needsBudget=true로 뜨게 함
    final Map<String, int> hardBudget = {
      '식비': 180000,
      '카페': 70000,
      '쇼핑': 120000,
      '여가': 90000,
    };

    // 3) 카테고리 리스트 구성
    final List<Map<String, dynamic>> out = [];
    final categories = spentByCategory.keys.toList()..sort();

    for (final cat in categories) {
      final spent = spentByCategory[cat] ?? 0;

      final hasBudget = hardBudget.containsKey(cat);
      final budget = hasBudget ? hardBudget[cat]! : 0;

      out.add({
        'category': cat,
        'spent': spent,
        'budget': budget,
        'needsBudget': !hasBudget,
      });
    }

    // 4) ✅ 마지막 축: 총소비 (budget = 하루소비한도 * 30/7)
    final int periodDays = (budgetPeriod == '주간') ? 7 : 30;
    final int totalBudget = hardDailySpendingLimit * periodDays;

    out.add({
      'category': '총소비',
      'spent': totalSpentAll,
      'budget': totalBudget,
      'needsBudget': false,
      'isTotal': true,
    });

    return out;
  }

  double get maxYForCurrentBudget {
    if (currentBudgetData.isEmpty) return 100000;

    double maxVal = 0;
    for (final e in currentBudgetData) {
      final spent = (e['spent'] as num?)?.toDouble() ?? 0.0;
      final budget = (e['budget'] as num?)?.toDouble() ?? 0.0;
      final highest = (spent > budget) ? spent : budget;
      if (highest > maxVal) maxVal = highest;
    }

    return (maxVal * 1.2).ceilToDouble().clamp(1.0, double.infinity);
  }

  // ───────── 인사이트 (소비 수치 중심 5종) ─────────

  static final _nf = NumberFormat.decimalPattern('ko_KR');

  List<Map<String, dynamic>> _buildReportInsights() {
    final days7 = _daysInRecentPeriod('주간');
    final total7 = _totalSpentFromDays(days7);
    final avgDaily7 = days7.isEmpty ? 0 : (total7 / 7).round();
    final topCat7 = _topCategoryFromDays(days7);
    final budget7 = hardDailySpendingLimit * 7;
    final ratio7 = budget7 > 0 ? (total7 / budget7 * 100).round() : 0;
    final prev7 = _totalSpentPrevious7Days();
    final trend7 = prev7 > 0 ? ((total7 - prev7) / prev7 * 100).round() : 0;

    return [
      {
        'title': total7 > 0
            ? '최근 7일 동안 총 ${_nf.format(total7)}원을 소비했어요.'
            : '최근 7일간 소비 기록이 없어요.',
        'icon': Icons.account_balance_wallet,
        'color': AppColors.primary,
      },
      {
        'title': days7.isNotEmpty
            ? '최근 7일 기준 하루 평균 소비는 ${_nf.format(avgDaily7)}원이에요.'
            : '최근 7일 기록이 없어요.',
        'icon': Icons.trending_up,
        'color': const Color(0xFF43A047),
      },
      {
        'title': topCat7 != null
            ? '최근 7일 동안 가장 많이 쓴 카테고리는 $topCat7예요.'
            : '최근 7일간 소비 기록이 없어요.',
        'icon': Icons.pie_chart,
        'color': AppColors.primary,
      },
      {
        'title': budget7 > 0
            ? '최근 7일은 설정한 예산의 ${ratio7}%를 사용했어요.'
            : '예산을 설정하면 예산 대비 소비를 볼 수 있어요.',
        'icon': Icons.savings,
        'color': ratio7 > 100
            ? const Color(0xFFD32F2F)
            : const Color(0xFF43A047),
      },
      {
        'title': prev7 > 0
            ? '직전 7일 대비 소비가 ${trend7 >= 0 ? trend7 : -trend7}% ${trend7 >= 0 ? '증가' : '감소'}했어요.'
            : '소비 추세는 이전 기록이 쌓이면 보여줄게요.',
        'icon': Icons.compare_arrows,
        'color': AppColors.primary,
      },
    ];
  }

  int _totalSpentFromDays(List<DaySpending> days) {
    int sum = 0;
    for (final d in days) {
      for (final e in d.entries) {
        sum += (e.amount as num).round();
      }
    }
    return sum;
  }

  String? _topCategoryFromDays(List<DaySpending> days) {
    final Map<String, int> byCat = {};
    for (final d in days) {
      for (final e in d.entries) {
        final cat = e.category.trim();
        if (cat.isEmpty) continue;
        final amt = (e.amount as num).round();
        byCat[cat] = (byCat[cat] ?? 0) + amt;
      }
    }
    if (byCat.isEmpty) return null;
    return byCat.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int _totalSpentPrevious7Days() {
    final today = _dateOnly(DateTime.now());
    final startPrev = today.subtract(const Duration(days: 13));
    final endPrev = today.subtract(const Duration(days: 7));
    int sum = 0;
    for (final m in _monthCache.values) {
      for (final d in m.days.values) {
        final date = _dateOnly(d.date);
        if (date.isBefore(startPrev) || date.isAfter(endPrev)) continue;
        for (final e in d.entries) {
          sum += (e.amount as num).round();
        }
      }
    }
    return sum;
  }

  // ───────── 데이터 로딩 ─────────

  Future<void> _loadForMonth(DateTime month) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ 상단 카드: 선택된 월 로드(유지)
      _monthly = await _recordRepository.loadMonthlySpendingByDate(month);

      // ✅ 캐시에도 저장
      if (_monthly != null) {
        _monthCache[_monthKey(month)] = _monthly!;
      }

      // ✅ 차트(최근 7/30일) 커버 월 프리로드
      await _preloadMonthsForRecentPeriod(days: 30);

      _recomputeAggregates();
      _error = null;
    } catch (_) {
      _error = '데이터를 불러오는 중 오류가 발생했어요';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reloadForCurrentMonth() async {
    await _loadForMonth(_selectedBaseDate);
  }

  bool _didInitialLoad = false;

  Future<void> loadInitial() async {
    if (_didInitialLoad) return;
    _didInitialLoad = true;

    if (hasData) return;

    await reloadForCurrentMonth();
  }

  void _recomputeAggregates() {
    _monthlyCategorySpent.clear();
    _weeklyCategorySpent.clear();

    incomeTotal = 0;
    fixedExpenseTotal = 0;
    variableExpenseTotal = 0;
    savingTotal = 0;

    if (_monthly == null) return;

    // ✅ 상단 카드(선택된 월) 계산 유지
    for (final DaySpending day in _monthly!.days.values) {
      for (final SpendingEntry e in day.entries) {
        if (e.category.isEmpty || e.amount == 0) continue;

        final amt = (e.amount as num).round();
        _monthlyCategorySpent[e.category] =
            (_monthlyCategorySpent[e.category] ?? 0) + amt;

        // 기존대로 변동소비만 더함
        variableExpenseTotal += amt;
      }
    }
  }

  // ───────── UI 액션 ─────────

  void setBudgetPeriod(String period) {
    if (budgetPeriod == period) return;
    budgetPeriod = period;

    // ✅ 주간/월간 바뀌면 필요한 월들 미리 로드
    _preloadMonthsForRecentPeriod(days: period == '주간' ? 7 : 30);

    notifyListeners();
  }

  void changeMonth(int delta) {
    _selectedBaseDate = DateTime(
      _selectedBaseDate.year,
      _selectedBaseDate.month + delta,
      1,
    );
    _loadForMonth(_selectedBaseDate);
  }

  void toggleCategoryDropdown() {
    isCategoryDropdownOpen = !isCategoryDropdownOpen;
    notifyListeners();
  }

  void selectCategory(String category) {
    selectedCategory = category;
    isCategoryDropdownOpen = false;
    notifyListeners();
  }

  void setInsightIndex(int index) {
    currentInsightIndex = index;
    notifyListeners();
  }

  // ================== Recent 7/30 helpers ==================

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

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

  @override
  void dispose() {
    _spendingSub.cancel();
    super.dispose();
  }
}

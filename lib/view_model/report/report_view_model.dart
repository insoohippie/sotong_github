// lib/view_model/report/report_view_model.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, IconData, Icons;
import 'package:intl/intl.dart';

import 'package:sotong_local/component/theme/app_colors.dart';

import '../../repository/record_repository.dart';
import '../../model/record/monthly_spending.dart';
import '../../model/record/day_spending.dart';
import '../../model/refData/ref_data.dart';
import '../../model/report/report_models.dart';
import '../../repository/ref_data_repository.dart';

class ReportViewModel extends ChangeNotifier {
  ReportViewModel(this._recordRepo, this._refRepo);

  final RecordRepository _recordRepo;
  final RefDataRepository _refRepo;

  // ─────────────────────────────
  // state
  // ─────────────────────────────
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  final NumberFormat _nf = NumberFormat('#,###');

  // 배너 인덱스
  int _insightIndex = 0;
  int get insightIndex => _insightIndex;
  void setInsightIndex(int i) {
    _insightIndex = i;
    notifyListeners();
  }

  // 월 선택
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  // 주간/월간 (뷰에서 쓰는 이름: rangeType)
  ReportRangeType _rangeType = ReportRangeType.weekly;
  ReportRangeType get rangeType => _rangeType;

  void setRangeType(ReportRangeType next) {
    if (_rangeType == next) return;
    _rangeType = next;
    _rebuildAll();
  }

  void changeMonth(int delta) {
    var y = selectedYear;
    var m = selectedMonth + delta;
    if (m < 1) {
      m = 12;
      y -= 1;
    } else if (m > 12) {
      m = 1;
      y += 1;
    }
    selectedYear = y;
    selectedMonth = m;
    _rebuildAll();
  }

  // ─────────────────────────────
  // data cache
  // ─────────────────────────────
  final Map<String, MonthlySpending> _monthCache = {}; // yyyy-MM -> monthly
  RefData? _refData;

  // record에서 본 "마지막 카테고리 이름" 캐시 (표시용 fallback)
  final Map<String, String> _lastRecordNameByKey = {};

  // 차트 모델
  ReportCategoryBudgetChart? _budgetChart;
  ReportCategoryBudgetChart? get budgetChart => _budgetChart;

  // MonthCategorySection에서 쓰는 합계(일단 "기록 기반"으로 유지)
  int _incomeTotal = 0;
  int _savingTotal = 0;
  int _fixedExpenseTotal = 0;
  int _variableExpenseTotal = 0;

  int get incomeTotal => _incomeTotal;
  int get savingTotal => _savingTotal;
  int get fixedExpenseTotal => _fixedExpenseTotal;
  int get variableExpenseTotal => _variableExpenseTotal;

  // ─────────────────────────────
  // init (뷰에서 쓰는 이름: loadInitial)
  // ─────────────────────────────
  bool _didInit = false;

  Future<void> loadInitial() async {
    if (_didInit) return;
    _didInit = true;
    await _rebuildAll();
  }

  // ─────────────────────────────
  // derived
  // ─────────────────────────────
  String get rangeLabel {
    if (_rangeType == ReportRangeType.weekly) return '주간';
    return '월간';
  }

  ReportRange get range {
    final now = _dateOnly(DateTime.now());

    if (_rangeType == ReportRangeType.weekly) {
      // ✅ 월요일 시작 고정
      final monday = now.subtract(Duration(days: (now.weekday + 6) % 7));
      final sunday = monday.add(const Duration(days: 6));
      return ReportRange(start: _dateOnly(monday), end: _dateOnly(sunday));
    } else {
      final start = DateTime(selectedYear, selectedMonth, 1);
      final end = DateTime(selectedYear, selectedMonth + 1, 0);
      return ReportRange(start: _dateOnly(start), end: _dateOnly(end));
    }
  }

  // ✅ 뷰에서 쓰는 이름: insights
  List<Map<String, dynamic>> get insights => _buildReportInsights();

  List<Map<String, dynamic>> _buildReportInsights() {
    // 인사이트는 “최근 7일” 기준으로 고정
    final r7 = _recent7Range();
    final spent7 = _sumSpentInRange(r7);

    // ✅ budget7 = dailyConsume overlap 기반 “진짜 예산”
    final budget7 = _sumPlannedInRange(r7);

    final avgDaily7 = (spent7 / 7).round();
    final topCat7 = _topCategoryNameInRange(r7);
    final ratio7 = budget7 > 0 ? (spent7 / budget7 * 100).round() : 0;

    final prev7 = _sumSpentInRange(_previous7Range());
    final trend7 = prev7 > 0 ? ((spent7 - prev7) / prev7 * 100).round() : 0;

    return [
      {
        'title': spent7 > 0
            ? '최근 7일 동안 총 ${_nf.format(spent7)}원을 소비했어요.'
            : '최근 7일간 소비 기록이 없어요.',
        'icon': Icons.account_balance_wallet,
        'color': AppColors.primary,
      },
      {
        'title': spent7 > 0
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
        'color': ratio7 > 100 ? const Color(0xFFD32F2F) : const Color(0xFF43A047),
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

  // ─────────────────────────────
  // main rebuild
  // ─────────────────────────────
  Future<void> _rebuildAll() async {
    _setLoading(true);
    _setError(null);
    notifyListeners();

    try {
      // 1) 월 기록 로드(선택월)
      await _ensureMonthLoaded(DateTime(selectedYear, selectedMonth, 1));

      // 2) RefData 로드
      _refData ??= await _refRepo.loadAll();

      // 3) chart 빌드(합의안 A)
      final r = range;
      _budgetChart = _buildBudgetChart(range: r);

      // 4) MonthCategorySection totals (일단 기록 기반)
      _recomputeMonthTotalsFromRecords();

      _setError(null);
    } catch (e) {
      _setError('리포트 로드 실패: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ─────────────────────────────
  // chart build
  // planned: dailyConsume overlap 누적
  // spent: record range 필터 합산
  // chart categories: “플랜 카테고리 합집합(+기타)”
  // ─────────────────────────────
  ReportCategoryBudgetChart _buildBudgetChart({required ReportRange range}) {
    const etcKey = 'etc';

    final plannedByKey = <String, int>{};
    final nameByKey = <String, String>{};
    final emojiByKey = <String, String>{};

    final spentByKey = <String, int>{};

    // 1) planned
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
          final key = (e.categoryKey.trim().isEmpty) ? etcKey : e.categoryKey.trim();
          final add = (e.amount * overlap).round();

          plannedByKey[key] = (plannedByKey[key] ?? 0) + add;

          nameByKey[key] ??= (e.category.trim().isEmpty ? '기타' : e.category.trim());
          emojiByKey[key] ??= '💰';
        }
      }
    }

    // 2) spent (categoryKey 기준)
    final days = _daysInRange(range);
    for (final d in days) {
      for (final e in d.entries) {
        final key = (e.categoryKey.trim().isEmpty) ? etcKey : e.categoryKey.trim();
        spentByKey[key] = (spentByKey[key] ?? 0) + e.amount.round();
      }
    }

    // 3) keys = 플랜 합집합 (+etc 필요 시)
    nameByKey.putIfAbsent(etcKey, () => '기타');
    emojiByKey.putIfAbsent(etcKey, () => '🧩');

    // planned에 없는 spent는 etc로 몰기
    int etcSpent = spentByKey[etcKey] ?? 0;
    spentByKey.forEach((k, v) {
      if (k == etcKey) return;
      if (!plannedByKey.containsKey(k)) {
        etcSpent += v;
      }
    });
    spentByKey[etcKey] = etcSpent;

    final keys = plannedByKey.keys.toSet();
    if ((spentByKey[etcKey] ?? 0) > 0) keys.add(etcKey);

    final rows = keys.map((k) {
      final name = nameByKey[k] ??
          (k == etcKey ? '기타' : (_lastRecordNameByKey[k] ?? k));

      final emoji = emojiByKey[k] ?? (k == etcKey ? '🧩' : '💰');

      return ReportCategoryBudgetRow(
        categoryKey: k,
        name: name,
        emoji: emoji,
        planned: plannedByKey[k] ?? 0,
        spent: spentByKey[k] ?? 0,
        isTotal: false,
      );
    }).toList();

    // 4) 정렬: spent 큰 순, 기타는 맨 뒤
    rows.sort((a, b) => b.spent.compareTo(a.spent));
    final etcIndex = rows.indexWhere((e) => e.categoryKey == etcKey);
    if (etcIndex >= 0) {
      final etc = rows.removeAt(etcIndex);
      rows.add(etc);
    }

    // 5) 총소비 row
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

    return ReportCategoryBudgetChart(range: range, rows: List.unmodifiable(rows));
  }

  // ─────────────────────────────
  // totals for month section (임시: record기반)
  // ─────────────────────────────
  void _recomputeMonthTotalsFromRecords() {
    final monthly = _monthCache[_monthKey(DateTime(selectedYear, selectedMonth, 1))];
    if (monthly == null) {
      _incomeTotal = 0;
      _savingTotal = 0;
      _fixedExpenseTotal = 0;
      _variableExpenseTotal = 0;
      return;
    }

    int sum = 0;
    for (final d in monthly.days.values) {
      for (final e in d.entries) {
        sum += e.amount.round();
      }
    }

    _variableExpenseTotal = sum;
    _fixedExpenseTotal = 0;

    _incomeTotal = 0;
    _savingTotal = 0;
  }

  // ─────────────────────────────
  // range helpers
  // ─────────────────────────────
  List<DaySpending> _daysInRange(ReportRange r) {
    final start = _dateOnly(r.start);
    final end = _dateOnly(r.end);

    final out = <DaySpending>[];
    final months = _monthsCovered(start, end);
    for (final m in months) {
      final mm = _monthCache[_monthKey(m)];
      if (mm == null) continue;

      for (final d in mm.days.values) {
        final day = _dateOnly(d.date);
        if (day.isBefore(start) || day.isAfter(end)) continue;

        // ✅ record 기반 "마지막 이름" 캐시
        for (final e in d.entries) {
          final key = e.categoryKey.trim();
          if (key.isEmpty) continue;
          final name = e.category.trim();
          if (name.isNotEmpty) _lastRecordNameByKey[key] = name;
        }

        out.add(d);
      }
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  // ─────────────────────────────
  // insight helpers
  // ─────────────────────────────
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
      for (final e in d.entries) {
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

  // ✅ FIX: top category는 categoryKey로 집계
  // 표시명은 (1) 플랜 이름(dailyConsume) (2) record 마지막 이름 (3) fallback
  String? _topCategoryNameInRange(ReportRange r) {
    const etcKey = 'etc';

    final days = _daysInRange(r);
    final spentByKey = <String, int>{};

    for (final d in days) {
      for (final e in d.entries) {
        final key = e.categoryKey.trim().isEmpty ? etcKey : e.categoryKey.trim();
        spentByKey[key] = (spentByKey[key] ?? 0) + e.amount.round();
      }
    }
    if (spentByKey.isEmpty) return null;

    final top = spentByKey.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final topKey = top.key;

    final planName = _planNameForKey(topKey);
    if (planName != null && planName.trim().isNotEmpty) return planName.trim();

    final recordName = _lastRecordNameByKey[topKey];
    if (recordName != null && recordName.trim().isNotEmpty) return recordName.trim();

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

  // ─────────────────────────────
  // overlap logic
  // ─────────────────────────────
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

    return end.difference(start).inDays + 1; // inclusive
  }

  // ─────────────────────────────
  // cache load helpers
  // ─────────────────────────────
  Future<void> _ensureMonthLoaded(DateTime anchorMonthFirstDay) async {
    final key = _monthKey(anchorMonthFirstDay);
    if (_monthCache.containsKey(key)) return;

    final loaded = await _recordRepo.loadMonthlySpendingByDate(anchorMonthFirstDay);
    _monthCache[key] = loaded;

    // prev / next pre-load (기존 구조 유지)
    final prev = DateTime(anchorMonthFirstDay.year, anchorMonthFirstDay.month - 1, 1);
    final next = DateTime(anchorMonthFirstDay.year, anchorMonthFirstDay.month + 1, 1);

    if (!_monthCache.containsKey(_monthKey(prev))) {
      final prevLoaded = await _recordRepo.loadMonthlySpendingByDate(prev);
      _monthCache[_monthKey(prev)] = prevLoaded;
    }
    if (!_monthCache.containsKey(_monthKey(next))) {
      final nextLoaded = await _recordRepo.loadMonthlySpendingByDate(next);
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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  void _setLoading(bool v) => _isLoading = v;
  void _setError(String? msg) => _error = msg;
}
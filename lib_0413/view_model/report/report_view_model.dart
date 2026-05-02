// lib/view_model/report/report_view_model.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, IconData, Icons;
import 'package:intl/intl.dart';

import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/services/spending_event_bus.dart';

import '../../repository/record_repository.dart';
import '../../model/record/monthly_record.dart';
import '../../model/record/day_record.dart';
import '../../model/refData/ref_data.dart';
import '../../model/report/report_models.dart';
import '../../repository/ref_data_repository.dart';

class ReportViewModel extends ChangeNotifier {
  ReportViewModel(
      this._recordRepo,
      this._refRepo, {
        SpendingEventBus? eventBus,
      }) {
    if (eventBus != null) {
      _spendingSub = eventBus.stream.listen((_) {
        _spendingDebounce?.cancel();
        _spendingDebounce = Timer(const Duration(milliseconds: 120), () async {
          await refreshAfterSpendingUpdated();
        });
      });
    }
  }

  final RecordRepository _recordRepo;
  final RefDataRepository _refRepo;

  StreamSubscription<SpendingUpdatedEvent>? _spendingSub;
  Timer? _spendingDebounce;

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
    if (_didInit) return;
    _didInit = true;
    await _rebuildAll();
  }

  ReportRange get chartRange {
    final now = _dateOnly(DateTime.now());

    if (_rangeType == ReportRangeType.weekly) {
      final monday = now.subtract(Duration(days: (now.weekday + 6) % 7));
      final sunday = monday.add(const Duration(days: 6));
      return ReportRange(start: _dateOnly(monday), end: _dateOnly(sunday));
    } else {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return ReportRange(start: _dateOnly(start), end: _dateOnly(end));
    }
  }

  String get rangeLabel => (_rangeType == ReportRangeType.weekly) ? '주간' : '월간';

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

  List<Map<String, dynamic>> _buildReportInsights() {
    final r7 = _recent7Range();
    final spent7 = _sumSpentInRange(r7);
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

  List<({String name, int spent})> unplannedSpentListForChartRange({
    int maxItems = 8,
  }) {
    final r = chartRange;
    return _unplannedSpentList(range: r, maxItems: maxItems);
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
        final k = e.categoryKey.trim().isEmpty ? etcKey : e.categoryKey.trim();
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
      _refData ??= await _refRepo.loadAll();

      final r = chartRange;
      await _ensureMonthsLoadedForRange(r);

      await _ensureMonthLoaded(DateTime(monthSectionYear, monthSectionMonth, 1));

      _budgetChart = _buildBudgetChart(range: r);

      _recomputeMonthTotalsFromRecords();

      _setError(null);
    } catch (e) {
      _setError('리포트 로드 실패: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refreshAfterSpendingUpdated() async {
    _invalidateMonthsForRefresh();
    await _rebuildAll();
  }

  void _invalidateMonthsForRefresh() {
    final r = chartRange;
    final months = _monthsCovered(_dateOnly(r.start), _dateOnly(r.end));
    for (final m in months) {
      _monthCache.remove(_monthKey(DateTime(m.year, m.month, 1)));
    }
    _monthCache.remove(_monthKey(DateTime(monthSectionYear, monthSectionMonth, 1)));
  }

  ReportCategoryBudgetChart _buildBudgetChart({required ReportRange range}) {
    const etcKey = 'etc';

    final plannedByKey = <String, int>{};
    final nameByKey = <String, String>{};
    final spentByKey = <String, int>{};

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
        }
      }
    }

    final days = _daysInRange(range);
    for (final d in days) {
      for (final e in d.spendingEntries) {
        final key = (e.categoryKey.trim().isEmpty) ? etcKey : e.categoryKey.trim();
        spentByKey[key] = (spentByKey[key] ?? 0) + e.amount.round();
      }
    }

    nameByKey.putIfAbsent(etcKey, () => '기타');

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

      return ReportCategoryBudgetRow(
        categoryKey: k,
        name: name,
        emoji: (k == etcKey) ? '🧩' : '💰',
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

    return ReportCategoryBudgetChart(range: range, rows: List.unmodifiable(rows));
  }

  void _recomputeMonthTotalsFromRecords() {
    final monthly = _monthCache[_monthKey(DateTime(monthSectionYear, monthSectionMonth, 1))];
    if (monthly == null) {
      _incomeTotal = 0;
      _savingTotal = 0;
      _fixedExpenseTotal = 0;
      _variableExpenseTotal = 0;
      return;
    }

    int spendingSum = 0;
    int incomeSum = 0;

    for (final d in monthly.days.values) {
      for (final e in d.spendingEntries) {
        spendingSum += e.amount.round();
      }
      for (final e in d.incomeEntries) {
        incomeSum += e.amount.round();
      }
    }

    _variableExpenseTotal = spendingSum;
    _fixedExpenseTotal = 0;
    _incomeTotal = incomeSum;
    _savingTotal = incomeSum - spendingSum;
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
          if (name.isNotEmpty) _lastRecordNameByKey[key] = name;
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
    final months = _monthsCovered(_dateOnly(r.start), _dateOnly(r.end));
    for (final m in months) {
      await _ensureMonthLoaded(DateTime(m.year, m.month, 1));
    }
  }

  Future<void> _ensureMonthLoaded(DateTime anchorMonthFirstDay) async {
    final key = _monthKey(anchorMonthFirstDay);
    if (_monthCache.containsKey(key)) return;

    final loaded = await _recordRepo.loadMonthlyRecordByDate(anchorMonthFirstDay);
    _monthCache[key] = loaded;

    final prev = DateTime(anchorMonthFirstDay.year, anchorMonthFirstDay.month - 1, 1);
    final next = DateTime(anchorMonthFirstDay.year, anchorMonthFirstDay.month + 1, 1);

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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  void _setLoading(bool v) => _isLoading = v;
  void _setError(String? msg) => _error = msg;

  @override
  void dispose() {
    _spendingDebounce?.cancel();
    _spendingSub?.cancel();
    super.dispose();
  }
}
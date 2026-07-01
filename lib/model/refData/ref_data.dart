import 'daily_consume.dart';
import 'entry.dart';
import 'monthly_consume.dart';
import 'monthly_income.dart';

/// Container that holds all reference data (income/consume definitions) linked to a plan.
class RefData {
  RefData({
    this.planId = '',
    Map<String, MonthlyIncome>? monthlyIncomes,
    Map<String, MonthlyConsume>? monthlyConsumes,
    Map<String, DailyConsume>? dailyConsumes,
    Map<String, DailyConsume>? dailyVariableConsumes,
    DateTime? referenceDate,
  })  : monthlyIncomeMap =
  Map<String, MonthlyIncome>.from(monthlyIncomes ?? const {}),
        monthlyConsumeMap =
        Map<String, MonthlyConsume>.from(monthlyConsumes ?? const {}),
        dailyConsumeMap =
        Map<String, DailyConsume>.from(dailyConsumes ?? const {}),
        dailyVariableConsumeMap =
        Map<String, DailyConsume>.from(dailyVariableConsumes ?? const {}),
        _referenceDate = _normalizeDay(referenceDate ?? DateTime.now()) {
    _refreshPrimaryIds();
  }

  /// Plan identifier this reference data belongs to.
  String planId;

  /// Monthly income definitions keyed by document id.
  final Map<String, MonthlyIncome> monthlyIncomeMap;

  /// Monthly consume definitions keyed by document id.
  final Map<String, MonthlyConsume> monthlyConsumeMap;

  /// Daily consume definitions keyed by document id.
  final Map<String, DailyConsume> dailyConsumeMap;

  /// Daily variable consume definitions keyed by document id.
  final Map<String, DailyConsume> dailyVariableConsumeMap;

  DateTime _referenceDate;

  DateTime get referenceDate => _referenceDate;

  void setReferenceDate(DateTime date) {
    final normalized = _normalizeDay(date);

    // 날짜가 같아도 dailyConsumeMap/monthlyMap이 바뀐 직후에는
    // primary id를 다시 잡아야 할 수 있음.
    _referenceDate = normalized;
    _refreshPrimaryIds();
  }

  /// 같은 날짜 기준으로 primary id만 강제로 다시 계산하고 싶을 때 사용.
  void refreshPrimaryIds() {
    _refreshPrimaryIds();
  }

  String? _primaryMonthlyIncomeId;
  String? _primaryMonthlyConsumeId;
  String? _primaryDailyConsumeId;

  String? get primaryMonthlyIncomeId => _primaryMonthlyIncomeId;
  String? get primaryMonthlyConsumeId => _primaryMonthlyConsumeId;
  String? get primaryDailyConsumeId => _primaryDailyConsumeId;

  List<Entry> get primaryMonthlyIncomeEntries =>
      _primaryMonthlyIncomeId != null
          ? monthlyIncomeEntries(_primaryMonthlyIncomeId!)
          : const [];

  List<Entry> get primaryMonthlyConsumeEntries =>
      _primaryMonthlyConsumeId != null
          ? monthlyConsumeEntries(_primaryMonthlyConsumeId!)
          : const [];

  List<Entry> get primaryDailyConsumeEntries =>
      _primaryDailyConsumeId != null
          ? dailyConsumeEntries(_primaryDailyConsumeId!)
          : const [];

  double get primaryMonthlyIncomeSum => _primaryMonthlyIncomeId != null
      ? monthlyIncomeSum(_primaryMonthlyIncomeId!)
      : 0;

  double get primaryMonthlyConsumeSum => _primaryMonthlyConsumeId != null
      ? monthlyConsumeSum(_primaryMonthlyConsumeId!)
      : 0;

  double get primaryDailyConsumeSum => _primaryDailyConsumeId != null
      ? dailyConsumeSum(_primaryDailyConsumeId!)
      : 0;

  /// Returns income by id or null when absent.
  MonthlyIncome? monthlyIncomeById(String id) => monthlyIncomeMap[id];

  /// Returns consume by id or null when absent.
  MonthlyConsume? monthlyConsumeById(String id) => monthlyConsumeMap[id];

  /// Returns daily consume by id or null when absent.
  DailyConsume? dailyConsumeById(String id) => dailyConsumeMap[id];

  /// Returns daily variable consume by id or null when absent.
  DailyConsume? dailyVariableConsumeById(String id) =>
      dailyVariableConsumeMap[id];

  /// Entries for a given monthly income id.
  List<Entry> monthlyIncomeEntries(String id) =>
      monthlyIncomeMap[id]?.entries ?? const [];

  /// Entries for a given monthly consume id.
  List<Entry> monthlyConsumeEntries(String id) =>
      monthlyConsumeMap[id]?.entries ?? const [];

  /// Entries for a given daily consume id.
  List<Entry> dailyConsumeEntries(String id) =>
      dailyConsumeMap[id]?.entries ?? const [];

  /// Entries for a given daily variable consume id.
  List<Entry> dailyVariableEntries(String id) =>
      dailyVariableConsumeMap[id]?.entries ?? const [];

  /// Sum for a specific monthly income id.
  double monthlyIncomeSum(String id) =>
      _sumEntries(monthlyIncomeMap[id]?.entries ?? const []);

  /// Sum for a specific monthly consume id.
  double monthlyConsumeSum(String id) =>
      _sumEntries(monthlyConsumeMap[id]?.entries ?? const []);

  /// Sum for a specific daily consume id.
  double dailyConsumeSum(String id) =>
      _sumEntries(dailyConsumeMap[id]?.entries ?? const []);

  /// Sum for a specific daily variable consume id.
  double dailyVariableConsumeSum(String id) =>
      _sumEntries(dailyVariableConsumeMap[id]?.entries ?? const []);

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'monthlyIncomeMap': monthlyIncomeMap.map(
            (key, income) => MapEntry(
          key,
          {
            ...income.toMap(),
            'id': key,
          },
        ),
      ),
      'monthlyConsumeMap': monthlyConsumeMap.map(
            (key, consume) => MapEntry(
          key,
          {
            ...consume.toMap(),
            'id': key,
          },
        ),
      ),
      'dailyConsumeMap': dailyConsumeMap.map(
            (key, consume) => MapEntry(
          key,
          {
            ...consume.toMap(),
            'id': key,
          },
        ),
      ),
      'dailyVariableConsumeMap': dailyVariableConsumeMap.map(
            (key, consume) => MapEntry(
          key,
          {
            ...consume.toMap(),
            'id': key,
          },
        ),
      ),
    };
  }

  static RefData fromMap(Map<String, dynamic> map) {
    final planId = map['planId'] as String? ?? '';
    final monthlyIncomesRaw =
    (map['monthlyIncomeMap'] as Map<String, dynamic>? ?? {});
    final monthlyConsumesRaw =
    (map['monthlyConsumeMap'] as Map<String, dynamic>? ?? {});
    final dailyConsumesRaw =
    (map['dailyConsumeMap'] as Map<String, dynamic>? ?? {});
    final dailyVariableConsumesRaw =
    (map['dailyVariableConsumeMap'] as Map<String, dynamic>? ?? {});

    return RefData(
      planId: planId,
      monthlyIncomes: monthlyIncomesRaw.map(
            (key, value) => MapEntry(
          key,
          MonthlyIncome.fromMap(key, Map<String, dynamic>.from(value)),
        ),
      ),
      monthlyConsumes: monthlyConsumesRaw.map(
            (key, value) => MapEntry(
          key,
          MonthlyConsume.fromMap(key, Map<String, dynamic>.from(value)),
        ),
      ),
      dailyConsumes: dailyConsumesRaw.map(
            (key, value) => MapEntry(
          key,
          DailyConsume.fromMap(key, Map<String, dynamic>.from(value)),
        ),
      ),
      dailyVariableConsumes: dailyVariableConsumesRaw.map(
            (key, value) => MapEntry(
          key,
          DailyConsume.fromMap(key, Map<String, dynamic>.from(value)),
        ),
      ),
    );
  }

  @override
  String toString() {
    return '''
RefData(
  planId: $planId,
  monthlyIncomeMap: ${monthlyIncomeMap.length}개 (primary: $_primaryMonthlyIncomeId),
  monthlyConsumeMap: ${monthlyConsumeMap.length}개 (primary: $_primaryMonthlyConsumeId),
  dailyConsumeMap: ${dailyConsumeMap.length}개 (primary: $_primaryDailyConsumeId),
  dailyVariableConsumeMap: ${dailyVariableConsumeMap.length}개
)
''';
  }

  /// Creates a new monthly income entry, assigns an S1 id, and deactivates overlaps.
  MonthlyIncome addMonthlyIncome({
    required DateTime applyMonth,
    required DateTime modEndMonth,
    required List<Entry> entries,
  }) {
    final months = _monthRange(applyMonth, modEndMonth);
    final id = _nextSequentialId(applyMonth, monthlyIncomeMap.keys);
    final monthSet = months.toSet();
    final keys = monthlyIncomeMap.keys.toList(growable: false);
    for (final key in keys) {
      final income = monthlyIncomeMap[key];
      if (income == null || !income.isActive) continue;
      final overlapMonths = income.yearMonthList
          .where((month) => monthSet.contains(month))
          .toList(growable: false);
      if (overlapMonths.isEmpty) continue;
      monthlyIncomeMap[key] = income.removeMonths(overlapMonths);
    }
    final income = MonthlyIncome.newForMonths(
      id: id,
      yearMonthList: months,
      entries: entries,
    );
    monthlyIncomeMap[id] = income;
    _primaryMonthlyIncomeId = id;
    return income;
  }

  /// Creates a new monthly consume entry, assigns an S1 id, and deactivates overlaps.
  MonthlyConsume addMonthlyConsume({
    required DateTime applyMonth,
    required DateTime modEndMonth,
    required List<Entry> entries,
  }) {
    final months = _monthRange(applyMonth, modEndMonth);
    final id = _nextSequentialId(applyMonth, monthlyConsumeMap.keys);
    final monthSet = months.toSet();
    final keys = monthlyConsumeMap.keys.toList(growable: false);
    for (final key in keys) {
      final consume = monthlyConsumeMap[key];
      if (consume == null || !consume.isActive) continue;
      final overlapMonths = consume.yearMonthList
          .where((month) => monthSet.contains(month))
          .toList(growable: false);
      if (overlapMonths.isEmpty) continue;
      monthlyConsumeMap[key] = consume.removeMonths(overlapMonths);
    }
    final consume = MonthlyConsume.newForMonths(
      id: id,
      yearMonthList: months,
      entries: entries,
    );
    monthlyConsumeMap[id] = consume;
    _primaryMonthlyConsumeId = id;
    return consume;
  }

  /// Creates a new daily consume entry, assigns an S1 id, and truncates overlaps.
  DailyConsume addDailyConsume({
    required DateTime applyDate,
    required DateTime modEndDate,
    required List<Entry> entries,
  }) {
    final normalizedApply = _normalizeDay(applyDate);
    final normalizedEnd = _normalizeDay(modEndDate);
    final id = _nextSequentialId(normalizedApply, dailyConsumeMap.keys);
    final keys = dailyConsumeMap.keys.toList(growable: false);
    for (final key in keys) {
      final daily = dailyConsumeMap[key];
      if (daily == null || !daily.isActive) continue;
      if (normalizedApply.isAfter(daily.endDate)) continue;
      if (normalizedApply.isAfter(daily.startDate)) {
        final adjusted = daily.endAt(
          normalizedApply.subtract(const Duration(days: 1)),
        );
        dailyConsumeMap[key] = adjusted;
      } else {
        dailyConsumeMap[key] = daily.softDelete(
          normalizedApply.subtract(const Duration(days: 1)),
        );
      }
    }
    final consume = DailyConsume.newRange(
      id: id,
      startDate: normalizedApply,
      endDate: normalizedEnd,
      entries: entries,
    );
    dailyConsumeMap[id] = consume;
    _primaryDailyConsumeId = id;
    return consume;
  }

  void _refreshPrimaryIds() {
    final targetMonth =
    DateTime(_referenceDate.year, _referenceDate.month, 1);
    _primaryMonthlyIncomeId =
        _monthlyIncomeCovering(targetMonth) ?? _latestMonthlyIncomeId();
    _primaryMonthlyConsumeId =
        _monthlyConsumeCovering(targetMonth) ?? _latestMonthlyConsumeId();
    _primaryDailyConsumeId =
        _dailyIdCovering(_referenceDate, dailyConsumeMap) ??
            _latestDailyConsumeId();
  }

  String? _latestMonthlyIncomeId() {
    DateTime? maxMonth;
    String? latestId;
    for (final entry in monthlyIncomeMap.entries) {
      final income = entry.value;
      if (!income.isActive) continue;
      final months = income.yearMonthList;
      if (months.isEmpty) continue;
      final last = months.reduce((a, b) => a.isAfter(b) ? a : b);
      if (maxMonth == null || last.isAfter(maxMonth!)) {
        maxMonth = last;
        latestId = entry.key;
      }
    }
    return latestId;
  }

  String? _monthlyIncomeCovering(DateTime month) {
    return _monthlyIdCovering(
      month,
      monthlyIncomeMap,
          (MonthlyIncome income) => income.yearMonthList,
          (MonthlyIncome income) => income.isActive,
    );
  }

  String? _latestMonthlyConsumeId() {
    DateTime? maxMonth;
    String? latestId;
    for (final entry in monthlyConsumeMap.entries) {
      final consume = entry.value;
      if (!consume.isActive) continue;
      final months = consume.yearMonthList;
      if (months.isEmpty) continue;
      final last = months.reduce((a, b) => a.isAfter(b) ? a : b);
      if (maxMonth == null || last.isAfter(maxMonth!)) {
        maxMonth = last;
        latestId = entry.key;
      }
    }
    return latestId;
  }

  String? _monthlyConsumeCovering(DateTime month) {
    return _monthlyIdCovering(
      month,
      monthlyConsumeMap,
          (MonthlyConsume consume) => consume.yearMonthList,
          (MonthlyConsume consume) => consume.isActive,
    );
  }

  String? _latestDailyConsumeId() {
    DateTime? maxEnd;
    String? latestId;
    for (final entry in dailyConsumeMap.entries) {
      final daily = entry.value;
      if (!daily.isActive) continue;
      if (maxEnd == null || daily.endDate.isAfter(maxEnd)) {
        maxEnd = daily.endDate;
        latestId = entry.key;
      }
    }
    return latestId;
  }

  String? _dailyIdCovering(
      DateTime date,
      Map<String, DailyConsume> source,
      ) {
    final target = _normalizeDay(date);

    final candidates = source.entries.where((entry) {
      final daily = entry.value;
      if (!daily.isActive) return false;

      final start = _normalizeDay(daily.startDate);
      final end = _normalizeDay(daily.endDate);

      return !target.isBefore(start) && !target.isAfter(end);
    }).toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final aStart = _normalizeDay(a.value.startDate);
      final bStart = _normalizeDay(b.value.startDate);

      // 최신 적용일 우선
      final startCompare = bStart.compareTo(aStart);
      if (startCompare != 0) return startCompare;

      final aEnd = _normalizeDay(a.value.endDate);
      final bEnd = _normalizeDay(b.value.endDate);

      // endDate도 최신인 것 우선
      final endCompare = bEnd.compareTo(aEnd);
      if (endCompare != 0) return endCompare;

      // 마지막 fallback: id가 큰 것 우선
      return b.key.compareTo(a.key);
    });

    return candidates.first.key;
  }

  String? _monthlyIdCovering<T>(
      DateTime month,
      Map<String, T> source,
      List<DateTime> Function(T item) monthsSelector,
      bool Function(T item) activeSelector,
      ) {
    String? candidate;
    DateTime? candidateEnd;
    for (final entry in source.entries) {
      final item = entry.value;
      if (!activeSelector(item)) continue;
      final months = monthsSelector(item);
      final match = months.any(
            (m) => m.year == month.year && m.month == month.month,
      );
      if (!match) continue;
      final lastMonth = months.isEmpty
          ? DateTime(month.year, month.month)
          : months.reduce((a, b) => a.isAfter(b) ? a : b);
      if (candidate == null ||
          candidateEnd == null ||
          lastMonth.isAfter(candidateEnd)) {
        candidate = entry.key;
        candidateEnd = lastMonth;
      }
    }
    return candidate;
  }

  List<DateTime> _monthRange(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var cursor = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  static DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _nextSequentialId(DateTime date, Iterable<String> existingIds) {
    final planPrefix = planId.isEmpty ? '' : '${planId}_';
    final base =
        '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}';
    var maxSeq = 0;
    for (final id in existingIds) {
      final normalizedId =
      planPrefix.isNotEmpty && id.startsWith(planPrefix) ? id.substring(planPrefix.length) : id;
      if (!normalizedId.startsWith(base)) continue;
      final parts = normalizedId.split('-');
      if (parts.length != 2) continue;
      final seq = int.tryParse(parts[1]) ?? 0;
      if (seq > maxSeq) maxSeq = seq;
    }
    final nextSeq = (maxSeq + 1).toString().padLeft(3, '0');
    return '$base-$nextSeq';
  }

  double _sumEntries(Iterable<Entry> entries) =>
      entries.fold<double>(0, (prev, e) => prev + e.amount);
}

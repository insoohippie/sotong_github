import 'package:meta/meta.dart';

import 'mini_plan.dart';
import 'plan_metrics.dart';
import 'sub_plan.dart';

/// Root aggregate object holding all sub-plans and summary results.
@immutable
class TotalPlan {
  const TotalPlan({ // 개념적 관련 정보 저장
    required this.planId,
    required this.currentAmount, // 현재 플랜 저축액
    required this.currentAsset, // 기존 보유 금액(플랜 무관)
    required this.subPlans,
    required this.result,
    this.planName,
    this.targetAmount,
    this.startDate,
    this.endDate, // 처음 플랜 생성시 종료일
    this.modEndDate, // 변경된 종료일
    this.creationDate,
    this.autoService,
    //하경 - 모인 금액 계산용
    this.extraIncomeTotal = 0,
    this.snapshotAmount = 0,
    this.snapshotAt,
    this.extraIncomeRecords = const [],
  });

  final String planId;
  final String? planName;
  final int? targetAmount;
  final int currentAmount;
  final int currentAsset;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? modEndDate;
  final DateTime? creationDate;
  final bool? autoService;
  final Map<String, SubPlan> subPlans;
  final TotalResult result; // planMetrics 저장소
  //하경 - 모인 금액 계산용
  final int extraIncomeTotal;  // 플랜 중간 추가 수입 누적
  final int snapshotAmount;    // snapshotAt 시점까지 자동저축 누적
  final DateTime? snapshotAt;  // 스냅샷 기준 시각
  final List<ExtraIncomeRecord> extraIncomeRecords;

  /// Factory for a blank plan used as a draft during onboarding.
  factory TotalPlan.empty() {
    final now = DateTime.now();
    final normalizedNow = _normalizeDate(now);
    final metrics = PlanMetrics.fromRange(
      startDate: normalizedNow,
      endDate: normalizedNow.add(const Duration(days: 29)),
      monthlyIncomeAmount: 0,
      monthlyConsumeAmount: 0,
      dailyConsumeAmount: 0,
    );
    final initialSubPlans = _bootstrapSubPlans(
      metrics: metrics,
      planStart: normalizedNow,
    );
    return TotalPlan(
      planId: '',
      planName: '',
      targetAmount: 0,
      currentAmount: 0,
      currentAsset: 0,
      startDate: normalizedNow,
      endDate: null,
      modEndDate: null,
      creationDate: normalizedNow,
      autoService: false,
      subPlans: initialSubPlans,
      result: TotalResult(
        totalMetrics: metrics, // totalPlan 관련 metrics 관리
        subResult: SubPlanResult( // subPlan관련 metrics 관리
          subMetrics:
          initialSubPlans.values.map((sub) => sub.monthlySummary()).toList(),
          subPlanList: initialSubPlans.values.toList(),
        ),
      ),
      //하경 - 모인 금액 계산용
      extraIncomeTotal: 0,
      snapshotAmount: 0,
      snapshotAt: normalizedNow,
      extraIncomeRecords: const [],
    );
  }

  /// Creates a [TotalPlan] from a new-architecture Firestore map.
  factory TotalPlan.fromMap(String id, Map<String, dynamic> map) {
    final planStartDate = _parseDate(map['startDate']);
    final metrics = _parseMetrics(map['result']?['totalMetrics']);
    final subPlans = _parseSubPlans(map['subPlans']);
    final normalizedSubPlans = subPlans.isNotEmpty
        ? subPlans
        : _bootstrapSubPlans(metrics: metrics, planStart: planStartDate);
    return TotalPlan(
      planId: id,
      planName: map['planName'] as String?,
      targetAmount: (map['targetAmount'] as num?)?.round(),
      currentAmount: (map['currentAmount'] as num?)?.round() ?? 0,
      currentAsset: (map['currentAsset'] as num?)?.round() ?? 0,
      startDate: planStartDate,
      endDate: _parseDate(map['endDate']),
      modEndDate: _parseDate(map['modEndDate']),
      creationDate: _parseDate(map['creationDate']),
      autoService: map['autoService'] as bool?,
      subPlans: normalizedSubPlans,
      result: TotalResult(
        totalMetrics: metrics,
        subResult: _parseSubResult(
          map['result']?['subResult'],
          normalizedSubPlans,
        ),
      ),
      //하경 - 모인 금액 계산용
      extraIncomeTotal:
      (map['extraIncomeTotal'] as num?)?.round() ?? 0,
      snapshotAmount:
      (map['snapshotAmount'] as num?)?.round() ?? 0,
      snapshotAt: _parseDate(map['snapshotAt']),
      extraIncomeRecords: (map['extraIncomeRecords'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => ExtraIncomeRecord.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planName': planName,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currentAsset': currentAsset,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'modEndDate': modEndDate?.toIso8601String(),
      'creationDate': creationDate?.toIso8601String(),
      'autoService': autoService,
      'subPlans': _serializeSubPlans(subPlans),
      'result': {
        'totalMetrics': _serializeMetrics(result.totalMetrics),
        'subResult': _serializeSubResult(result.subResult),
      },
      //하경 - 모인 금액 계산용
      'extraIncomeTotal': extraIncomeTotal,
      'snapshotAmount': snapshotAmount,
      'snapshotAt': snapshotAt?.toIso8601String(),
      'extraIncomeRecords':
      extraIncomeRecords.map((e) => e.toMap()).toList(growable: false),
    };
  }

  SubPlan? subPlanByKey(String yearMonthKey) => subPlans[yearMonthKey];

  TotalPlan replaceSubPlan(String key, SubPlan subPlan) {
    final updated = Map<String, SubPlan>.from(subPlans)..[key] = subPlan;
    return copyWith(subPlans: updated).recalculateTotals();
  }

  TotalPlan addSubPlan(String key, SubPlan subPlan) {
    final updated = Map<String, SubPlan>.from(subPlans)..[key] = subPlan;
    return copyWith(subPlans: updated).recalculateTotals();
  }

  TotalPlan recalculateTotals() {
    final updatedSubPlans = <String, SubPlan>{};
    final monthlySummaries = <PlanMetrics>[];
    for (final entry in subPlans.entries) {
      final recalculated = entry.value.recalculate();
      updatedSubPlans[entry.key] = recalculated;
      monthlySummaries.add(recalculated.monthlySummary());
    }
    monthlySummaries.sort((a, b) => a.startDate.compareTo(b.startDate));
    final subResult = SubPlanResult(
      subMetrics: monthlySummaries,
      subPlanList: updatedSubPlans.values.toList(),
    );
    final totalMetricsBase = monthlySummaries.isEmpty
        ? _emptyMetrics()
        : PlanMetrics.merge(monthlySummaries);
    PlanMetrics totalMetrics = totalMetricsBase;
    final currentMini = _miniPlanForDate(DateTime.now());
    if (currentMini != null) {
      totalMetrics = totalMetrics.copyWith(
        monthlyIncomeAmount: currentMini.monthlyIncomeAmount,
        monthlyConsumeAmount: currentMini.monthlyConsumeAmount,
        dailyConsumeAmount: currentMini.dailyConsumeAmount,
      );
    } else if (monthlySummaries.isNotEmpty) {
      final latestSummary = monthlySummaries.last;
      totalMetrics = totalMetrics.copyWith(
        monthlyIncomeAmount: latestSummary.monthlyIncomeAmount,
        monthlyConsumeAmount: latestSummary.monthlyConsumeAmount,
        dailyConsumeAmount: latestSummary.dailyConsumeAmount,
      );
    }
    return copyWith(
      subPlans: updatedSubPlans,
      result: result.copyWith(
        totalMetrics: totalMetrics,
        subResult: subResult,
      ),
    );
  }

  TotalPlan copyWith({
    String? planId,
    String? planName,
    int? targetAmount,
    int? currentAmount,
    int? currentAsset,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? modEndDate,
    DateTime? creationDate,
    bool? autoService,
    Map<String, SubPlan>? subPlans,
    TotalResult? result,
    //하경 - 모인 금액 계산용
    int? extraIncomeTotal,
    int? snapshotAmount,
    DateTime? snapshotAt,
    List<ExtraIncomeRecord>? extraIncomeRecords,
  }) {
    return TotalPlan(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currentAsset: currentAsset ?? this.currentAsset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      modEndDate: modEndDate ?? this.modEndDate,
      creationDate: creationDate ?? this.creationDate,
      autoService: autoService ?? this.autoService,
      subPlans: subPlans ?? this.subPlans,
      result: result ?? this.result,
      //하경 - 모인 금액 계산용
      extraIncomeTotal: extraIncomeTotal ?? this.extraIncomeTotal,
      snapshotAmount: snapshotAmount ?? this.snapshotAmount,
      snapshotAt: snapshotAt ?? this.snapshotAt,
      extraIncomeRecords: extraIncomeRecords ?? this.extraIncomeRecords,
    );
  }

  PlanMetrics _emptyMetrics() {
    final baseline = startDate ?? DateTime.now();
    return PlanMetrics.fromRange(
      startDate: baseline,
      endDate: baseline.add(const Duration(days: 29)),
      monthlyIncomeAmount: 0,
      monthlyConsumeAmount: 0,
      dailyConsumeAmount: 0,
    );
  }

  MiniPlan? _miniPlanForDate(DateTime date) {
    if (subPlans.isEmpty) return null;
    final key = _formatYearMonth(date);
    final direct = _miniCoveringDate(subPlans[key], date);
    if (direct != null) return direct;

    final targetMonth = DateTime(date.year, date.month, 1);
    final entries = subPlans.entries.toList()
      ..sort((a, b) => a.value.yearMonth.compareTo(b.value.yearMonth));
    SubPlan? before;
    SubPlan? after;
    for (final entry in entries) {
      final month = entry.value.yearMonth;
      if (month.isAfter(targetMonth)) {
        after ??= entry.value;
        break;
      }
      before = entry.value;
    }
    final fallback =
        _closestSubPlan(before, after, targetMonth) ?? entries.last.value;
    return _miniClosestWithin(fallback, date);
  }

  MiniPlan? _miniCoveringDate(SubPlan? subPlan, DateTime date) {
    if (subPlan == null) return null;
    for (final mini in subPlan.orderedMinis()) {
      final startsBefore = !date.isBefore(mini.startDate);
      final endsAfter = !date.isAfter(mini.endDate);
      if (startsBefore && endsAfter) {
        return mini;
      }
    }
    return null;
  }

  MiniPlan? _miniClosestWithin(SubPlan? subPlan, DateTime date) {
    if (subPlan == null) return null;
    final minis = subPlan.orderedMinis();
    if (minis.isEmpty) return null;
    final covering = _miniCoveringDate(subPlan, date);
    if (covering != null) {
      return covering;
    }
    if (date.isBefore(minis.first.startDate)) {
      return minis.first;
    }
    return minis.last;
  }

  SubPlan? _closestSubPlan(
      SubPlan? before,
      SubPlan? after,
      DateTime targetMonth,
      ) {
    if (before == null && after == null) return null;
    if (before == null) return after;
    if (after == null) return before;
    final beforeDiff = targetMonth.difference(before.yearMonth).inDays;
    final afterDiff = after.yearMonth.difference(targetMonth).inDays;
    return beforeDiff <= afterDiff ? before : after;
  }

  static Map<String, SubPlan> _bootstrapSubPlans({
    required PlanMetrics metrics,
    required DateTime? planStart,
  }) {
    final baseline = planStart ?? DateTime.now();
    final monthStart = DateTime(baseline.year, baseline.month, 1);
    final monthEnd = DateTime(baseline.year, baseline.month + 1, 0);
    final key = _formatYearMonth(monthStart);
    final miniId = '${key}_mini_head';
    final mini = MiniPlan(
      docId: miniId,
      yearMonth: monthStart,
      startDate: monthStart,
      endDate: monthEnd,
      monthlyIncomeId: '${key}_income_bootstrap',
      monthlyConsumeId: '${key}_consume_bootstrap',
      dailyConsumeId: '${key}_daily_bootstrap',
      monthlyIncomeAmount: metrics.monthlyIncomeAmount,
      monthlyConsumeAmount: metrics.monthlyConsumeAmount,
      dailyConsumeAmount: metrics.dailyConsumeAmount,
    ).recalculateNetAmounts();
    final subPlan = SubPlan(
      yearMonth: monthStart,
      headDocId: miniId,
      miniPlans: {miniId: mini},
      miniResult: MiniPlanResult(
        headDocId: miniId,
        miniMetrics: [mini.toMetrics()],
        miniPlanHead: mini,
      ),
    );
    return {key: subPlan};
  }

  static String _formatYearMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    DateTime? parsed;
    if (value is DateTime) {
      parsed = value;
    } else if (value is String) {
      parsed = DateTime.tryParse(value);
    } else {
      try {
        // ignore: avoid_dynamic_calls
        parsed = (value as dynamic).toDate() as DateTime;
      } catch (_) {
        parsed = null;
      }
    }
    return parsed != null ? _normalizeDate(parsed) : null;
  }

  static DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static PlanMetrics _parseMetrics(dynamic map) {
    if (map is Map<String, dynamic>) {
      final start = _parseDate(map['startDate']) ?? DateTime.now();
      final end = _parseDate(map['endDate']) ?? start.add(const Duration(days: 29));
      final monthlyNetIncome = (map['monthlyNetIncome'] as num?)?.round() ?? 0;
      final monthlyNetConsume = (map['monthlyNetConsume'] as num?)?.round() ?? 0;
      final dailyNetConsume = (map['dailyNetConsume'] as num?)?.round() ?? 0;
      final incomeAmount =
          (map['monthlyIncomeAmount'] ?? map['sumMonthlyIncome']) as num? ?? 0;
      final consumeAmount =
          (map['monthlyConsumeAmount'] ?? map['sumMonthlyConsume']) as num? ?? 0;
      final dailyAmount =
          (map['dailyConsumeAmount'] ?? map['sumDailyConsume']) as num? ?? 0;
      return PlanMetrics.fromRange(
        startDate: start,
        endDate: end,
        monthlyIncomeAmount: incomeAmount.round(),
        monthlyConsumeAmount: consumeAmount.round(),
        dailyConsumeAmount: dailyAmount.round(),
        monthlyNetIncome: monthlyNetIncome,
        monthlyNetConsume: monthlyNetConsume,
        dailyNetConsume: dailyNetConsume,
      ).copyWith(
        dailyNetSaving: (map['dailyNetSaving'] as num?)?.round(),
        monthlyNetSaving: (map['monthlyNetSaving'] as num?)?.round(),
        perSecondSaving:
        (map['perSecondSaving'] as num?)?.toDouble() ?? 0.0,
      );
    }
    final now = DateTime.now();
    return PlanMetrics.fromRange(
      startDate: now,
      endDate: now.add(const Duration(days: 29)),
      monthlyIncomeAmount: 0,
      monthlyConsumeAmount: 0,
      dailyConsumeAmount: 0,
    );
  }

  static Map<String, SubPlan> _parseSubPlans(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) {
        final subPlanMap = Map<String, dynamic>.from(value as Map);
        final miniPlansData =
        Map<String, dynamic>.from(subPlanMap['miniPlans'] as Map? ?? {});
        final miniPlans = miniPlansData.map(
              (docId, miniMap) => MapEntry(
            docId,
            MiniPlan.fromMap(Map<String, dynamic>.from(miniMap as Map)),
          ),
        );
        final headDocId = subPlanMap['headDocId'] as String? ?? '';
        final headMini = miniPlans[headDocId];
        if (headMini == null) {
          throw StateError('SubPlan($key) missing head mini plan $headDocId');
        }
        return MapEntry(
          key,
          SubPlan(
            yearMonth: DateTime.parse(subPlanMap['yearMonth'] as String),
            headDocId: headDocId,
            miniPlans: miniPlans,
            miniResult: MiniPlanResult(
              headDocId: headDocId,
              miniMetrics: const [],
              miniPlanHead: headMini,
            ),
            fractionalEndSeconds:
            subPlanMap['fractionalEndSeconds'] as int? ?? 0,
          ),
        );
      });
    }
    return const {};
  }

  static SubPlanResult _parseSubResult(
      dynamic data,
      Map<String, SubPlan> subPlans,
      ) {
    if (data is Map<String, dynamic>) {
      final subMetricRaw = data['subMetrics'] ?? data['metrics'];
      final metricsList = (subMetricRaw as List<dynamic>? ?? [])
          .map((m) => _parseMetrics(m as Map<String, dynamic>))
          .toList(growable: false);
      return SubPlanResult(
        subMetrics: metricsList,
        subPlanList: subPlans.values.toList(growable: false),
      );
    }
    return SubPlanResult(
      subMetrics: const [],
      subPlanList: subPlans.values.toList(growable: false),
    );
  }

  static Map<String, dynamic> _serializeMetrics(PlanMetrics metrics) {
    return {
      'startDate': metrics.startDate.toIso8601String(),
      'endDate': metrics.endDate.toIso8601String(),
      'kDays': metrics.kDays,
      'monthlyIncomeAmount': metrics.monthlyIncomeAmount,
      'monthlyConsumeAmount': metrics.monthlyConsumeAmount,
      'dailyConsumeAmount': metrics.dailyConsumeAmount,
      'monthlyNetIncome': metrics.monthlyNetIncome,
      'monthlyNetConsume': metrics.monthlyNetConsume,
      'dailyNetConsume': metrics.dailyNetConsume,
      'dailyNetSaving': metrics.dailyNetSaving,
      'monthlyNetSaving': metrics.monthlyNetSaving,
      'perSecondSaving': metrics.perSecondSaving,
    };
  }

  static Map<String, dynamic> _serializeSubPlans(
      Map<String, SubPlan> subPlans,
      ) {
    final result = <String, dynamic>{};
    subPlans.forEach((key, subPlan) {
      result[key] = {
        'yearMonth': subPlan.yearMonth.toIso8601String(),
        'headDocId': subPlan.headDocId,
        'miniPlans':
        subPlan.miniPlans.map((docId, mini) => MapEntry(docId, mini.toMap())),
        'fractionalEndSeconds': subPlan.fractionalEndSeconds,
      };
    });
    return result;
  }

  static Map<String, dynamic> _serializeSubResult(SubPlanResult result) {
    return {
      'subMetrics':
      result.subMetrics.map(_serializeMetrics).toList(growable: false),
      'subPlanDocIds': result.subPlanList.map((sub) => sub.headDocId).toList(),
    };
  }
}

/// Holds the precomputed total metrics and monthly breakdown.
@immutable
class TotalResult {
  const TotalResult({
    required this.totalMetrics,
    required this.subResult,
  });

  final PlanMetrics totalMetrics;
  final SubPlanResult subResult;

  TotalResult copyWith({
    PlanMetrics? totalMetrics,
    SubPlanResult? subResult,
  }) {
    return TotalResult(
      totalMetrics: totalMetrics ?? this.totalMetrics,
      subResult: subResult ?? this.subResult,
    );
  }
}

@immutable
class ExtraIncomeRecord {
  const ExtraIncomeRecord({
    required this.date,
    required this.amount,
  });

  final DateTime date;
  final int amount;

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };

  factory ExtraIncomeRecord.fromMap(Map<String, dynamic> map) {
    return ExtraIncomeRecord(
      date: TotalPlan._parseDate(map['date']) ?? DateTime.now(),
      amount: (map['amount'] as num?)?.round() ?? 0,
    );
  }
}

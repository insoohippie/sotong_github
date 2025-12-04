import 'package:meta/meta.dart';

import 'mini_plan.dart';
import 'plan_metrics.dart';
import 'sub_plan.dart';

/// Root aggregate object holding all sub-plans and summary results.
@immutable
class TotalPlan {
  const TotalPlan({
    required this.planId,
    required this.currentAmount,
    required this.currentAsset,
    required this.subPlans,
    required this.result,
    this.planName,
    this.targetAmount,
    this.startDate,
    this.endDate, // 처음 플랜 생성시 종료일
    this.modEndDate, // 변경된 종료일
    this.creationDate,
    this.autoService,
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
  final TotalResult result;

  /// Factory for a blank plan used as a draft during onboarding.
  factory TotalPlan.empty() {
    final now = DateTime.now();
    final metrics = PlanMetrics.fromRange(
      startDate: now,
      endDate: now.add(const Duration(days: 29)),
      sumMonthlyIncome: 0,
      sumMonthlyConsume: 0,
      sumDailyConsume: 0,
    );
    final initialSubPlans = _bootstrapSubPlans(
      metrics: metrics,
      planStart: now,
    );
    return TotalPlan(
      planId: '',
      planName: '',
      targetAmount: 0,
      currentAmount: 0,
      currentAsset: 0,
      startDate: now,
      endDate: null,
      modEndDate: null,
      creationDate: now,
      autoService: false,
      subPlans: initialSubPlans,
      result: TotalResult(
        totalMetrics: metrics,
        subResult: SubPlanResult(
          subMetrics:
              initialSubPlans.values.map((sub) => sub.monthlySummary()).toList(),
          subPlanList: initialSubPlans.values.toList(),
        ),
      ),
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
    final totalMetrics = monthlySummaries.isEmpty
        ? _emptyMetrics()
        : PlanMetrics.merge(monthlySummaries);
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
    );
  }

  PlanMetrics _emptyMetrics() {
    final baseline = startDate ?? DateTime.now();
    return PlanMetrics.fromRange(
      startDate: baseline,
      endDate: baseline.add(const Duration(days: 29)),
      sumMonthlyIncome: 0,
      sumMonthlyConsume: 0,
      sumDailyConsume: 0,
    );
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
      sumMonthlyIncome: metrics.sumMonthlyIncome,
      sumMonthlyConsume: metrics.sumMonthlyConsume,
      sumDailyConsume: metrics.sumDailyConsume,
    );
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
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      // ignore: avoid_dynamic_calls
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  static PlanMetrics _parseMetrics(dynamic map) {
    if (map is Map<String, dynamic>) {
      final start = _parseDate(map['startDate']) ?? DateTime.now();
      final end = _parseDate(map['endDate']) ?? start.add(const Duration(days: 29));
      return PlanMetrics.fromRange(
        startDate: start,
        endDate: end,
        sumMonthlyIncome: (map['sumMonthlyIncome'] as num?)?.round() ?? 0,
        sumMonthlyConsume: (map['sumMonthlyConsume'] as num?)?.round() ?? 0,
        sumDailyConsume: (map['sumDailyConsume'] as num?)?.round() ?? 0,
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
      sumMonthlyIncome: 0,
      sumMonthlyConsume: 0,
      sumDailyConsume: 0,
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
      'sumMonthlyIncome': metrics.sumMonthlyIncome,
      'sumMonthlyConsume': metrics.sumMonthlyConsume,
      'sumDailyConsume': metrics.sumDailyConsume,
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

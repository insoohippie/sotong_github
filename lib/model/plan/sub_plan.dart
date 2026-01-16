import 'package:meta/meta.dart';

import 'mini_plan.dart';
import 'plan_metrics.dart';

/// Groups mini plans for a specific month and keeps derived metrics.

@immutable
class SubPlan {
  const SubPlan({
    required this.yearMonth,
    required this.headDocId,
    required this.miniPlans,
    required this.miniResult,
  });

  final DateTime yearMonth;
  final String headDocId;
  final Map<String, MiniPlan> miniPlans;
  final MiniPlanResult miniResult;

  MiniPlan get head => miniPlans[headDocId]!;

  List<MiniPlan> orderedMinis() {
    final result = <MiniPlan>[];
    var current = head;
    while (true) {
      result.add(current);
      final nextId = current.nextDocId;
      if (nextId == null) break;
      final next = miniPlans[nextId];
      if (next == null) {
        throw StateError('Broken mini plan chain: missing $nextId');
      }
      current = next;
    }
    return result;
  }

  SubPlan replaceMini(MiniPlan mini) {
    if (!miniPlans.containsKey(mini.docId)) {
      throw ArgumentError('Mini plan ${mini.docId} does not belong to this SubPlan');
    }
    final updated = Map<String, MiniPlan>.from(miniPlans);
    updated[mini.docId] = mini;
    return copyWith(miniPlans: updated).recalculate();
  }

  SubPlan insertAfter({
    required String prevDocId,
    required MiniPlan newMini,
  }) {
    final prev = miniPlans[prevDocId];
    if (prev == null) {
      throw ArgumentError('Prev mini $prevDocId not found.');
    }
    final updatedPrev = prev.copyWith(nextDocId: newMini.docId);
    final updated = Map<String, MiniPlan>.from(miniPlans);
    updated[prevDocId] = updatedPrev;
    updated[newMini.docId] = newMini;
    if (newMini.nextDocId != null) {
      final next = miniPlans[newMini.nextDocId];
      if (next != null) {
        updated[newMini.nextDocId!] = next.copyWith(prevDocId: newMini.docId);
      }
    }
    return copyWith(miniPlans: updated).recalculate();
  }

  SubPlan recalculate() {
    final ordered = orderedMinis();
    final validated = <MiniPlan>[];
    MiniPlan? previous;
    for (final mini in ordered) {
      validated.add(mini.validateContinuity(previous: previous));
      previous = mini;
    }
    final metrics = validated.map((mini) => mini.toMetrics()).toList();
    final head = validated.isNotEmpty ? validated.first : miniResult.miniPlanHead;
    final result = miniResult.copyWith(
      headDocId: headDocId,
      miniMetrics: metrics,
      miniPlanHead: head,
    );
    return copyWith(miniResult: result);
  }

  PlanMetrics monthlySummary() {
    final ordered = orderedMinis();
    if (ordered.isEmpty) {
      final monthStart = DateTime(yearMonth.year, yearMonth.month, 1);
      return PlanMetrics.fromRange(
        startDate: monthStart,
        endDate: monthStart,
        sumMonthlyIncome: 0,
        sumMonthlyConsume: 0,
        sumDailyConsume: 0,
      );
    }
    final metrics = miniResult.miniMetrics.isNotEmpty
        ? miniResult.miniMetrics
        : ordered.map((mini) => mini.toMetrics()).toList();
    final monthStart = DateTime(yearMonth.year, yearMonth.month, 1);
    final monthEnd = DateTime(yearMonth.year, yearMonth.month + 1, 0);
    final daysInMonth = _daysInMonth(yearMonth);
    final totalDaily = metrics.fold<int>(
      0,
      (sum, metric) => sum + metric.sumDailyConsume * metric.kDays,
    );
    final avgDaily =
        PlanMetrics.halfUp(totalDaily / (daysInMonth == 0 ? 1 : daysInMonth));
    final firstMetric = metrics.first;
    return PlanMetrics.fromRange(
      startDate: monthStart,
      endDate: monthEnd,
      sumMonthlyIncome: firstMetric.sumMonthlyIncome,
      sumMonthlyConsume: firstMetric.sumMonthlyConsume,
      sumDailyConsume: avgDaily,
    );
  }

  SubPlan copyWith({
    DateTime? yearMonth,
    String? headDocId,
    Map<String, MiniPlan>? miniPlans,
    MiniPlanResult? miniResult,
  }) {
    return SubPlan(
      yearMonth: yearMonth ?? this.yearMonth,
      headDocId: headDocId ?? this.headDocId,
      miniPlans: miniPlans ?? this.miniPlans,
      miniResult: miniResult ?? this.miniResult,
    );
  }
}

/// Monthly summaries cached inside the total plan result.
@immutable
class SubPlanResult {
  const SubPlanResult({
    required this.subMetrics,
    required this.subPlanList,
  });

  final List<PlanMetrics> subMetrics;
  final List<SubPlan> subPlanList;

  SubPlanResult copyWith({
    List<PlanMetrics>? subMetrics,
    List<SubPlan>? subPlanList,
  }) {
    return SubPlanResult(
      subMetrics: subMetrics ?? this.subMetrics,
      subPlanList: subPlanList ?? this.subPlanList,
    );
  }
}

int _daysInMonth(DateTime yearMonth) {
  final firstDay = DateTime(yearMonth.year, yearMonth.month, 1);
  final nextMonth = DateTime(yearMonth.year, yearMonth.month + 1, 1);
  return nextMonth.difference(firstDay).inDays;
}

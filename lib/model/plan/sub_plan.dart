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
    this.fractionalEndSeconds = 0,
  });

  final DateTime yearMonth;
  final String headDocId;
  final Map<String, MiniPlan> miniPlans;
  final MiniPlanResult miniResult;
  final int fractionalEndSeconds;

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
        monthlyIncomeAmount: 0,
        monthlyConsumeAmount: 0,
        dailyConsumeAmount: 0,
      );
    }
    final metrics = miniResult.miniMetrics.isNotEmpty
        ? miniResult.miniMetrics
        : ordered.map((mini) => mini.toMetrics()).toList();
    // 기간은 달력 1일~말일이 아니라 이 달의 미니가 실제로 덮는 구간이어야 한다.
    // 금액(net*)은 미니 실제 기간분 합계이므로, 기간도 같은 기준이어야
    // dailyNetSaving(= 순저축 ÷ kDays)이 하루 페이스와 일치한다.
    // (달력 전체로 잡으면 잘린 달(시작월/종료월)의 kDays가 부풀어 값이 왜곡됨)
    final rangeStart = ordered.first.startDate;
    final rangeEnd = ordered.last.endDate;
    final latestMini = ordered.isNotEmpty ? ordered.last : miniResult.miniPlanHead;
    final totalMonthlyNetIncome =
        ordered.fold<int>(0, (sum, mini) => sum + mini.monthlyNetIncome);
    final totalMonthlyNetConsume =
        ordered.fold<int>(0, (sum, mini) => sum + mini.monthlyNetConsume);
    final totalDailyNetConsume =
    ordered.fold<int>(0, (sum, mini) => sum + mini.dailyNetConsume);
    final latestMonthlyIncome = latestMini.monthlyIncomeAmount;
    final latestMonthlyConsume = latestMini.monthlyConsumeAmount;
    final latestDailyLimit = latestMini.dailyConsumeAmount;
    return PlanMetrics.fromRange(
      startDate: rangeStart,
      endDate: rangeEnd,
      monthlyIncomeAmount: latestMonthlyIncome,
      monthlyConsumeAmount: latestMonthlyConsume,
      dailyConsumeAmount: latestDailyLimit,
      monthlyNetIncome: totalMonthlyNetIncome,
      monthlyNetConsume: totalMonthlyNetConsume,
      dailyNetConsume: totalDailyNetConsume,
    );
  }

  SubPlan copyWith({
    DateTime? yearMonth,
    String? headDocId,
    Map<String, MiniPlan>? miniPlans,
    MiniPlanResult? miniResult,
    int? fractionalEndSeconds,
  }) {
    return SubPlan(
      yearMonth: yearMonth ?? this.yearMonth,
      headDocId: headDocId ?? this.headDocId,
      miniPlans: miniPlans ?? this.miniPlans,
      miniResult: miniResult ?? this.miniResult,
      fractionalEndSeconds: fractionalEndSeconds ?? this.fractionalEndSeconds,
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

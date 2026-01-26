import '../../model/plan/plan_metrics.dart';
import '../../model/plan/total_plan.dart';

/// View-model helper that mutates a [TotalPlan] draft.
class TotalPlanViewModel {
  TotalPlanViewModel(this.plan);

  TotalPlan plan;

  void updateMeta({
    String? planName,
    double? targetAmount,
    double? currentAmount,
    double? currentAsset,
    bool? autoService,
    DateTime? startDate,
  }) {
    final metrics = plan.result.totalMetrics;
    final nextMetrics = startDate != null
        ? _rebuildMetrics(
            startDate: startDate,
            monthlyIncomeAmount: metrics.monthlyIncomeAmount,
            monthlyConsumeAmount: metrics.monthlyConsumeAmount,
            dailyConsumeAmount: metrics.dailyConsumeAmount,
          )
        : metrics;
    plan = plan.copyWith(
      planName: planName ?? plan.planName,
      targetAmount: targetAmount != null ? targetAmount.round() : plan.targetAmount,
      currentAmount: currentAmount != null ? currentAmount.round() : plan.currentAmount,
      currentAsset: currentAsset != null ? currentAsset.round() : plan.currentAsset,
      autoService: autoService ?? plan.autoService,
      startDate: startDate ?? plan.startDate,
      result: plan.result.copyWith(totalMetrics: nextMetrics),
    );
  }

  void updateMetrics({
    double? monthlyIncome,
    double? monthlyConsume,
    double? dailyConsume,
  }) {
    final metrics = plan.result.totalMetrics;
    final updatedMetrics = _rebuildMetrics(
      monthlyIncomeAmount: monthlyIncome != null ? monthlyIncome.round() : null,
      monthlyConsumeAmount:
          monthlyConsume != null ? monthlyConsume.round() : null,
      dailyConsumeAmount: dailyConsume != null ? dailyConsume.round() : null,
    );
    plan = plan.copyWith(
      result: plan.result.copyWith(totalMetrics: updatedMetrics),
    );
  }

  PlanMetrics _rebuildMetrics({
    int? monthlyIncomeAmount,
    int? monthlyConsumeAmount,
    int? dailyConsumeAmount,
    DateTime? startDate,
  }) {
    final metrics = plan.result.totalMetrics;
    final baseStart = startDate ?? metrics.startDate;
    final effectiveDays = metrics.kDays <= 0 ? 30 : metrics.kDays;
    final baseEnd = baseStart.add(Duration(days: effectiveDays - 1));
    return PlanMetrics.fromRange(
      startDate: baseStart,
      endDate: baseEnd,
      monthlyIncomeAmount: monthlyIncomeAmount ?? metrics.monthlyIncomeAmount,
      monthlyConsumeAmount:
          monthlyConsumeAmount ?? metrics.monthlyConsumeAmount,
      dailyConsumeAmount: dailyConsumeAmount ?? metrics.dailyConsumeAmount,
    );
  }
}

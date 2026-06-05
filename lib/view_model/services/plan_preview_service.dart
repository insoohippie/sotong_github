import '../../../model/plan/total_plan.dart';
import '../../../model/refData/ref_data.dart';
import '../../../model/saving_calculation_result.dart';
import 'saving_calculator.dart';

class PlanPreviewInput {
  const PlanPreviewInput({
    required this.plan,
    required this.refData,
    required this.applyDate,
    required this.targetAmount,
    required this.currentAsset,
    required this.monthlyIncome,
    required this.monthlyFixedCost,
    required this.dailySpendingLimit,
    this.monthlyIncomeApplyDate,
    this.monthlyFixedCostApplyDate,
    this.dailySpendingApplyDate,
  });

  final TotalPlan plan;
  final RefData refData;
  final DateTime applyDate;
  final double targetAmount;
  final double currentAsset;
  final double monthlyIncome;
  final double monthlyFixedCost;
  final double dailySpendingLimit;
  final DateTime? monthlyIncomeApplyDate;
  final DateTime? monthlyFixedCostApplyDate;
  final DateTime? dailySpendingApplyDate;
}

class PlanPreviewService {
  const PlanPreviewService();

  SavingCalculationResult? calculatePreview(PlanPreviewInput input) {
    final normalizedApply = _normalizeDay(input.applyDate);
    final adjustedTarget = _targetAfterPreSaved(input, normalizedApply);
    final remainingTarget = adjustedTarget - input.currentAsset;
    if (remainingTarget <= 0) {
      return SavingCalculationResult(
        dailyNetSaving: 0,
        daysToGoal: 0,
        goalDateTime: normalizedApply,
      );
    }

    final calculator = UpdateEndDateCalculator(
      plan: input.plan,
      targetAmount: adjustedTarget,
      currentAsset: input.currentAsset,
      monthlyIncome: input.monthlyIncome,
      monthlyFixedCost: input.monthlyFixedCost,
      dailySpendingLimit: input.dailySpendingLimit,
      monthlyIncomeApplyDate: input.monthlyIncomeApplyDate,
      monthlyFixedCostApplyDate: input.monthlyFixedCostApplyDate,
      dailySpendingApplyDate: input.dailySpendingApplyDate,
      today: normalizedApply,
    );
    return calculator.calculate();
  }

  int remainingTargetFor({
    required PlanPreviewInput input,
    required DateTime applyDate,
  }) {
    return _remainingTarget(input, _normalizeDay(applyDate));
  }

  int _remainingTarget(PlanPreviewInput input, DateTime applyDate) {
    final baseTarget = _targetAfterPreSaved(input, applyDate);
    final remaining = baseTarget - input.currentAsset;
    return remaining.isNegative ? 0 : remaining.round();
  }

  double _targetAfterPreSaved(PlanPreviewInput input, DateTime applyDate) {
    final preSaved = _preSavedAmountBefore(input.plan, applyDate);
    final adjusted = input.targetAmount - preSaved;
    return adjusted.isNegative ? 0 : adjusted;
  }

  double _preSavedAmountBefore(TotalPlan plan, DateTime applyDate) {
    if (plan.subPlans.isEmpty) {
      return 0;
    }
    final targetDay = _normalizeDay(applyDate);
    double total = 0;
    final subEntries = plan.subPlans.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in subEntries) {
      final minis = entry.value.orderedMinis();
      for (final mini in minis) {
        if (!mini.endDate.isBefore(targetDay)) {
          if (mini.startDate.isBefore(targetDay)) {
            final clipEnd = targetDay.subtract(const Duration(days: 1));
            if (!clipEnd.isBefore(mini.startDate)) {
              final clipped = mini
                  .copyWith(endDate: clipEnd)
                  .recalculateNetAmounts();
              total += clipped.toMetrics().monthlyNetSaving.toDouble();
            }
          }
          return total;
        }
        total += mini.toMetrics().monthlyNetSaving.toDouble();
      }
    }
    return total;
  }

  static DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

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
  });

  final TotalPlan plan;
  final RefData refData;
  final DateTime applyDate;
  final double targetAmount;
  final double currentAsset;
  final double monthlyIncome;
  final double monthlyFixedCost;
  final double dailySpendingLimit;
}

class PlanPreviewService {
  const PlanPreviewService();

  SavingCalculationResult? calculatePreview(PlanPreviewInput input) {
    final normalizedApply = _normalizeDay(input.applyDate);
    final remainingTarget = _remainingTarget(input, normalizedApply);
    if (remainingTarget <= 0) {
      return SavingCalculationResult(
        dailyNetSaving: 0,
        daysToGoal: 0,
        goalDateTime: normalizedApply,
      );
    }

    final calculator = UpdateEndDateCalculator(
      plan: input.plan,
      targetAmount: remainingTarget.toDouble(),
      currentAsset: input.currentAsset,
      monthlyIncome: input.monthlyIncome,
      monthlyFixedCost: input.monthlyFixedCost,
      dailySpendingLimit: input.dailySpendingLimit,
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
    final baseTarget = input.targetAmount;
    final preSaved = _preSavedAmountBefore(input.plan, applyDate);
    final alreadySaved = input.currentAsset + preSaved;
    final remaining = baseTarget - alreadySaved;
    return remaining.isNegative ? 0 : remaining.round();
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
              final clipped = mini.copyWith(endDate: clipEnd)
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

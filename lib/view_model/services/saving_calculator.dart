import 'dart:math';

import '../../model/plan/mini_plan.dart';
import '../../model/plan/plan_metrics.dart';
import '../../model/plan/sub_plan.dart';
import '../../model/plan/total_plan.dart';
import '../../model/saving_calculation_result.dart';

/// Calculates saving pace, goal date, and related metrics for a [TotalPlan].
class SavingPlanCalculator {
  SavingPlanCalculator({required TotalPlan plan}) : _plan = plan;

  TotalPlan _plan;

  void updatePlan(TotalPlan plan) => _plan = plan;

  PlanMetrics get _metrics => _plan.result.totalMetrics;

  double get _monthlyIncome => _metrics.sumMonthlyIncome.toDouble();
  double get _monthlyFixedCost => _metrics.sumMonthlyConsume.toDouble();
  double get _dailyLimit => _metrics.sumDailyConsume.toDouble();
  double get _targetAmount => (_plan.targetAmount ?? 0).toDouble();
  double get _currentAsset => _plan.currentAsset.toDouble();
  DateTime get _planStart => _plan.startDate ?? DateTime.now();

  SavingCalculationResult calculate() {
    final requiredSaving = _targetAmount - _currentAsset;

    final monthlyVariable = _dailyLimit * 30;
    final monthlySavingDisplay =
        _monthlyIncome - _monthlyFixedCost - monthlyVariable;
    final dailySavingBeforeVariable =
        (_monthlyIncome - _monthlyFixedCost) / 30.0;
    final savingRatioDisplay = _monthlyIncome <= 0
        ? 0.0
        : max(0.0, monthlySavingDisplay / _monthlyIncome);

    if (requiredSaving <= 0) {
      return SavingCalculationResult(
        monthlySaving: monthlySavingDisplay,
        dailySaving: dailySavingBeforeVariable,
        savingRatio: savingRatioDisplay.clamp(0.0, 1.0),
        dailyNetSaving: dailySavingBeforeVariable - _dailyLimit,
        requiredSaving: requiredSaving,
        daysToGoal: 0,
        totalSeconds: 0,
        goalDateTime: _planStart,
        savingPerSecond: 0,
      );
    }

    final timeline = _generateTimeline();
    if (timeline.isEmpty) {
      return _simpleCalculation(
        requiredSaving: requiredSaving,
        monthlySavingDisplay: monthlySavingDisplay,
        dailySavingBeforeVariable: dailySavingBeforeVariable,
        savingRatioDisplay: savingRatioDisplay,
      );
    }

    double accumulated = 0.0;
    double totalSeconds = 0.0;
    DateTime? goalDate;
    bool insufficient = false;

    for (final slice in timeline) {
      final dailyNet = slice.dailyNet;
      if (dailyNet <= 0) {
        insufficient = true;
        break;
      }

      if (accumulated + dailyNet >= requiredSaving) {
        final remaining = requiredSaving - accumulated;
        final fraction = (remaining / dailyNet).clamp(0.0, 1.0);
        totalSeconds += fraction * 86400.0;
        goalDate = slice.date.add(
          Duration(seconds: (fraction * 86400).round()),
        );
        accumulated = requiredSaving;
        break;
      } else {
        accumulated += dailyNet;
        totalSeconds += 86400.0;
      }
    }

    if (accumulated < requiredSaving) {
      insufficient = true;
    }

    if (insufficient || totalSeconds <= 0) {
      return SavingCalculationResult(
        monthlySaving: monthlySavingDisplay,
        dailySaving: dailySavingBeforeVariable,
        savingRatio: savingRatioDisplay.clamp(0.0, 1.0),
        dailyNetSaving: 0,
        requiredSaving: requiredSaving,
        daysToGoal: 0,
        totalSeconds: 0,
        goalDateTime: null,
        savingPerSecond: 0,
      );
    }

    final averageDailyNet = requiredSaving / (totalSeconds / 86400.0);
    final savingPerSecond = requiredSaving / totalSeconds;
    final daysToGoal = totalSeconds / 86400.0;
    final modEndDate =
        goalDate ?? _planStart.add(Duration(seconds: totalSeconds.round()));

    return SavingCalculationResult(
      monthlySaving: monthlySavingDisplay,
      dailySaving: dailySavingBeforeVariable,
      savingRatio: savingRatioDisplay.clamp(0.0, 1.0),
      dailyNetSaving: averageDailyNet,
      requiredSaving: requiredSaving,
      daysToGoal: daysToGoal,
      totalSeconds: totalSeconds,
      goalDateTime: modEndDate,
      savingPerSecond: savingPerSecond,
    );
  }

  List<_DailySlice> _generateTimeline() {
    final ordered = _orderedMinis();
    if (ordered.isEmpty) return const [];

    final planStart = _planStart;
    final slices = <_DailySlice>[];

    for (final mini in ordered) {
      final metrics = mini.toMetrics();
      final monthlyIncome = metrics.sumMonthlyIncome.toDouble();
      final monthlyConsume = metrics.sumMonthlyConsume.toDouble();
      final dailyLimit = metrics.sumDailyConsume.toDouble();

      var cursor = mini.startDate;
      while (!cursor.isAfter(mini.endDate)) {
        if (cursor.isBefore(planStart)) {
          cursor = cursor.add(const Duration(days: 1));
          continue;
        }

        final daysInMonth = _daysInMonth(cursor.year, cursor.month);
        final monthlyVariable = dailyLimit * daysInMonth;
        final dailyNet =
            (monthlyIncome - monthlyConsume - monthlyVariable) / daysInMonth;

        slices.add(_DailySlice(date: cursor, dailyNet: dailyNet));
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    return slices;
  }

  List<MiniPlan> _orderedMinis() {
    final result = <MiniPlan>[];
    final entries = _plan.subPlans.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      final subPlan = entry.value;
      result.addAll(subPlan.orderedMinis());
    }
    return result;
  }

  static int _daysInMonth(int year, int month) {
    final firstOfNextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  static String formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  SavingCalculationResult _simpleCalculation({
    required double requiredSaving,
    required double monthlySavingDisplay,
    required double dailySavingBeforeVariable,
    required double savingRatioDisplay,
  }) {
    final dailyNet = dailySavingBeforeVariable - _dailyLimit;
    if (dailyNet <= 0) {
      return SavingCalculationResult(
        monthlySaving: monthlySavingDisplay,
        dailySaving: dailySavingBeforeVariable,
        savingRatio: savingRatioDisplay.clamp(0.0, 1.0),
        dailyNetSaving: 0,
        requiredSaving: requiredSaving,
        daysToGoal: 0,
        totalSeconds: 0,
        goalDateTime: null,
        savingPerSecond: 0,
      );
    }

    final daysToGoal = requiredSaving / dailyNet;
    final totalSeconds = daysToGoal * 86400.0;
    final goalDate = _planStart.add(
      Duration(seconds: totalSeconds.round()),
    );

    return SavingCalculationResult(
      monthlySaving: monthlySavingDisplay,
      dailySaving: dailySavingBeforeVariable,
      savingRatio: savingRatioDisplay.clamp(0.0, 1.0),
      dailyNetSaving: dailyNet,
      requiredSaving: requiredSaving,
      daysToGoal: daysToGoal,
      totalSeconds: totalSeconds,
      goalDateTime: goalDate,
      savingPerSecond: dailyNet / 86400.0,
    );
  }
}

class _DailySlice {
  const _DailySlice({required this.date, required this.dailyNet});

  final DateTime date;
  final double dailyNet;
}

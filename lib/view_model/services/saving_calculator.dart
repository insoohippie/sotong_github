import 'dart:math';
import 'package:flutter/foundation.dart';

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

  double get _monthlyIncome => _metrics.monthlyIncomeAmount.toDouble();
  double get _monthlyFixedCost => _metrics.monthlyConsumeAmount.toDouble();
  double get _dailyLimit => _metrics.dailyConsumeAmount.toDouble();
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
    final fractionalSeconds = _fractionalEndSeconds();
    if (timeline.isEmpty) {
      debugPrint('[SavingCalc] timeline empty '
          '(planId=${_plan.planId}) start=$_planStart target=$requiredSaving '
          'monthlyIncome=$_monthlyIncome monthlyFixed=$_monthlyFixedCost '
          'dailyLimit=$_dailyLimit');
      return _simpleCalculation(
        requiredSaving: requiredSaving,
        monthlySavingDisplay: monthlySavingDisplay,
        dailySavingBeforeVariable: dailySavingBeforeVariable,
        savingRatioDisplay: savingRatioDisplay,
      );
    }
    debugPrint('[SavingCalc] timeline stats '
        'len=${timeline.length} '
        'range=${timeline.first.date}~${timeline.last.date} '
        'planStart=$_planStart target=$requiredSaving');

    double accumulated = 0.0;
    double totalSeconds = 0.0;
    DateTime? goalDate;
    bool insufficient = false;

    for (final slice in timeline) {
      final dailyNet = slice.dailyNet;
      if (dailyNet <= 0) {
        debugPrint('[SavingCalc] non-positive dailyNet '
            'date=${slice.date} dailyNet=$dailyNet');
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

    if (accumulated < requiredSaving &&
        fractionalSeconds > 0 &&
        timeline.isNotEmpty) {
      final lastSlice = timeline.last;
      final lastDailyNet = lastSlice.dailyNet;
      if (lastDailyNet > 0) {
        final fractionalRatio = fractionalSeconds / 86400.0;
        final extra = lastDailyNet * fractionalRatio;
        if (accumulated + extra >= requiredSaving) {
          final remaining = requiredSaving - accumulated;
          final neededSeconds =
              (remaining / lastDailyNet * 86400.0).clamp(
            0.0,
            fractionalSeconds.toDouble(),
          );
          totalSeconds += neededSeconds;
          accumulated = requiredSaving;
          goalDate = lastSlice.date.add(
            Duration(seconds: neededSeconds.round()),
          );
          insufficient = false;
        } else {
          accumulated += extra;
          totalSeconds += fractionalSeconds;
        }
      }
    }

    if (accumulated < requiredSaving) {
      debugPrint('[SavingCalc] insufficient accumulation '
          'accumulated=$accumulated required=$requiredSaving '
          'timelineLen=${timeline.length}');
      insufficient = true;
    }

    if (insufficient || totalSeconds <= 0) {
      debugPrint('[SavingCalc] fallback simple calculation '
          'insufficient=$insufficient totalSeconds=$totalSeconds');
      return _simpleCalculation(
        requiredSaving: requiredSaving,
        monthlySavingDisplay: monthlySavingDisplay,
        dailySavingBeforeVariable: dailySavingBeforeVariable,
        savingRatioDisplay: savingRatioDisplay,
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
      final monthlyIncome = metrics.monthlyIncomeAmount.toDouble();
      final monthlyConsume = metrics.monthlyConsumeAmount.toDouble();
      final dailyLimit = metrics.dailyConsumeAmount.toDouble();

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

  int _fractionalEndSeconds() {
    if (_plan.subPlans.isEmpty) return 0;
    final entries = _plan.subPlans.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.last.value.fractionalEndSeconds;
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

import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../model/plan/mini_plan.dart';
import '../../model/plan/sub_plan.dart';
import '../../model/plan/total_plan.dart';
import '../../model/saving_calculation_result.dart';

/// Calculates saving pace, goal date, and related metrics for a [TotalPlan].
class SavingPlanCalculator {
  SavingPlanCalculator({required TotalPlan plan}) : _plan = plan;

  static const Duration _kProjectionHorizon = Duration(days: 1095);

  TotalPlan _plan;

  void updatePlan(TotalPlan plan) => _plan = plan;

  double get _targetAmount => (_plan.targetAmount ?? 0).toDouble();
  double get _currentAsset => _plan.currentAsset.toDouble();
  DateTime get _planStart => _plan.startDate ?? DateTime.now();

  SavingCalculationResult calculate() {
    final requiredSaving = _targetAmount - _currentAsset;

    final slices = _buildSlices();
    final representative = _representativeSlice(slices);
    final repMonthlyIncome = representative?.monthlyIncome.toDouble() ?? 0.0;
    final repMonthlyConsume = representative?.monthlyConsume.toDouble() ?? 0.0;
    final repDailyLimit = representative?.dailyLimit.toDouble() ?? 0.0;
    final monthlyVariable = repDailyLimit * 30;
    final monthlySavingDisplay =
        repMonthlyIncome - repMonthlyConsume - monthlyVariable;
    final dailySavingBeforeVariable =
        (repMonthlyIncome - repMonthlyConsume) / 30.0;
    final savingRatioDisplay = repMonthlyIncome <= 0
        ? 0.0
        : max(0.0, monthlySavingDisplay / repMonthlyIncome);

    if (requiredSaving <= 0) {
      return SavingCalculationResult(
        monthlySaving: monthlySavingDisplay,
        dailySaving: dailySavingBeforeVariable,
        savingRatio: savingRatioDisplay.clamp(0.0, 1.0),
        dailyNetSaving: dailySavingBeforeVariable - repDailyLimit,
        requiredSaving: requiredSaving,
        daysToGoal: 0,
        totalSeconds: 0,
        goalDateTime: _planStart,
        savingPerSecond: 0,
      );
    }

    final timeline = _buildTimeline(slices);
    if (timeline.isEmpty) {
      debugPrint('[SavingCalc] timeline empty '
          '(planId=${_plan.planId}) start=$_planStart target=$requiredSaving');
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
    debugPrint('[SavingCalc] timeline stats '
        'len=${timeline.length} '
        'range=${timeline.first.date}~${timeline.last.date} '
        'planStart=$_planStart target=$requiredSaving');

    double accumulated = 0.0;
    double totalSeconds = 0.0;
    DateTime? goalDate;
    bool insufficient = false;
    bool nonPositiveDailyNet = false;

    for (final slice in timeline) {
      final dailyNet = slice.dailyNet;
      if (dailyNet <= 0) {
        debugPrint('[SavingCalc] non-positive dailyNet '
            'date=${slice.date} dailyNet=$dailyNet');
        nonPositiveDailyNet = true;
        continue;
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
      debugPrint('[SavingCalc] insufficient accumulation '
          'accumulated=$accumulated required=$requiredSaving '
          'timelineLen=${timeline.length}');
      insufficient = true;
    }

    if (insufficient || totalSeconds <= 0) {
      final goal = goalDate ??
          (timeline.isNotEmpty ? timeline.last.date : _planStart);
      return SavingCalculationResult(
        monthlySaving: monthlySavingDisplay,
        dailySaving: dailySavingBeforeVariable,
        savingRatio: savingRatioDisplay.clamp(0.0, 1.0),
        dailyNetSaving: 0,
        requiredSaving: requiredSaving,
        daysToGoal: 0,
        totalSeconds: 0,
        goalDateTime: nonPositiveDailyNet ? goal : null,
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

  List<_DailySlice> _buildTimeline(List<_PlanSlice> slices) {
    if (slices.isEmpty) return const [];
    final planStart = _planStart;
    final results = <_DailySlice>[];
    for (final slice in slices) {
      var cursor = slice.start;
      if (cursor.isBefore(planStart)) {
        cursor = planStart;
      }
      if (cursor.isAfter(slice.end)) continue;
      while (!cursor.isAfter(slice.end)) {
        if (cursor.isBefore(planStart)) {
          cursor = cursor.add(const Duration(days: 1));
          continue;
        }
        final daysInMonth = _daysInMonth(cursor.year, cursor.month);
        final monthlyVariable = slice.dailyLimit.toDouble() * daysInMonth;
        final dailyNet =
            (slice.monthlyIncome - slice.monthlyConsume - monthlyVariable) /
                daysInMonth;
        results.add(_DailySlice(date: cursor, dailyNet: dailyNet));
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    return results;
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

  List<_PlanSlice> _buildSlices() {
    final ordered = _orderedMinis();
    if (ordered.isEmpty) return const [];
    final slices = ordered
        .map(
          (mini) => _PlanSlice(
            start: mini.startDate,
            end: mini.endDate,
            monthlyIncome: mini.monthlyIncomeAmount.toDouble(),
            monthlyConsume: mini.monthlyConsumeAmount.toDouble(),
            dailyLimit: mini.dailyConsumeAmount.toDouble(),
          ),
        )
        .toList();
    final desiredEnd = _projectionEnd();
    var lastEnd = slices.last.end;
    if (lastEnd.isBefore(desiredEnd)) {
      final template = slices.last;
      var cursor = lastEnd.add(const Duration(days: 1));
      while (!cursor.isAfter(desiredEnd)) {
        final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
        final sliceEnd = monthEnd.isAfter(desiredEnd) ? desiredEnd : monthEnd;
        slices.add(
          _PlanSlice(
            start: cursor,
            end: sliceEnd,
            monthlyIncome: template.monthlyIncome,
            monthlyConsume: template.monthlyConsume,
            dailyLimit: template.dailyLimit,
          ),
        );
        cursor = sliceEnd.add(const Duration(days: 1));
      }
    }
    return slices;
  }

  _PlanSlice? _representativeSlice(List<_PlanSlice> slices) {
    if (slices.isEmpty) return null;
    final planStart = _planStart;
    for (final slice in slices) {
      if (!planStart.isAfter(slice.end)) {
        return slice;
      }
    }
    return slices.last;
  }

  DateTime _projectionEnd() {
    final planEnd = _plan.modEndDate ?? _plan.endDate ?? _planStart;
    final horizonEnd = _planStart.add(_kProjectionHorizon);
    return planEnd.isAfter(horizonEnd) ? planEnd : horizonEnd;
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

}

class _DailySlice {
  const _DailySlice({required this.date, required this.dailyNet});

  final DateTime date;
  final double dailyNet;
}

class _PlanSlice {
  const _PlanSlice({
    required this.start,
    required this.end,
    required this.monthlyIncome,
    required this.monthlyConsume,
    required this.dailyLimit,
  });

  final DateTime start;
  final DateTime end;
  final double monthlyIncome;
  final double monthlyConsume;
  final double dailyLimit;
}

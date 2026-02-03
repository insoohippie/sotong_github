import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../model/plan/mini_plan.dart';
import '../../model/plan/sub_plan.dart';
import '../../model/plan/total_plan.dart';
import '../../model/saving_calculation_result.dart';

const Duration _kProjectionHorizon = Duration(days: 1095);

/// Calculates saving pace, goal date, and related metrics for a [TotalPlan].
class SavingPlanCalculator {
  SavingPlanCalculator({required TotalPlan plan}) : _plan = plan;

  TotalPlan _plan;

  void updatePlan(TotalPlan plan) => _plan = plan;

  double get _targetAmount => (_plan.targetAmount ?? 0).toDouble();
  double get _currentAsset => _plan.currentAsset.toDouble();
  DateTime get _planStart => _plan.startDate ?? DateTime.now();

  SavingCalculationResult calculate() {
    final slices = _extendSlicesTo(
      _convertPlanToSlices(_plan),
      _projectionEnd(_planStart, _plan),
    );
    return _runProjection(
      slices: slices,
      targetAmount: _targetAmount,
      currentAsset: _currentAsset,
      startDate: _planStart,
      logTag: 'SavingCalc(planId=${_plan.planId})',
    );
  }

  static String formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

/// Calculator used during onboarding when the entire plan shares identical inputs.
class InitEndDateCalculator {
  InitEndDateCalculator({required TotalPlan plan})
      : _delegate = SavingPlanCalculator(plan: plan);

  final SavingPlanCalculator _delegate;

  void updatePlan(TotalPlan plan) => _delegate.updatePlan(plan);

  SavingCalculationResult calculate() => _delegate.calculate();
}

/// Calculator used during plan edits to preview the impact of new inputs.
class UpdateEndDateCalculator {
  UpdateEndDateCalculator({
    required TotalPlan plan,
    required double targetAmount,
    required double currentAsset,
    required double monthlyIncome,
    required double monthlyFixedCost,
    required double dailySpendingLimit,
    DateTime? today,
  })  : _plan = plan,
        _targetAmount = targetAmount,
        _currentAsset = currentAsset,
        _monthlyIncome = monthlyIncome,
        _monthlyFixedCost = monthlyFixedCost,
        _dailySpendingLimit = dailySpendingLimit,
        _today = _normalizeDay(today ?? DateTime.now());

  final TotalPlan _plan;
  final double _targetAmount;
  final double _currentAsset;
  final double _monthlyIncome;
  final double _monthlyFixedCost;
  final double _dailySpendingLimit;
  final DateTime _today;

  SavingCalculationResult? calculate() {
    final planStart = _plan.startDate != null
        ? _normalizeDay(_plan.startDate!)
        : _today;
    final effectiveStart =
        _today.isBefore(planStart) ? planStart : _today;
    final slices = <_PlanSlice>[
      ..._historicalSlices(_plan, effectiveStart),
    ];

    final projectionEnd = _projectionEnd(effectiveStart, _plan);
    if (!projectionEnd.isBefore(effectiveStart)) {
      slices.add(
        _PlanSlice(
          start: effectiveStart,
          end: projectionEnd,
          monthlyIncome: _monthlyIncome,
          monthlyConsume: _monthlyFixedCost,
          dailyLimit: _dailySpendingLimit,
        ),
      );
    }

    if (slices.isEmpty) {
      return null;
    }

    return _runProjection(
      slices: slices,
      targetAmount: _targetAmount,
      currentAsset: _currentAsset,
      startDate: effectiveStart,
      logTag: 'UpdateEndDate(planId=${_plan.planId})',
    );
  }

  List<_PlanSlice> _historicalSlices(
    TotalPlan plan,
    DateTime cutoff,
  ) {
    final slices = <_PlanSlice>[];
    for (final slice in _convertPlanToSlices(plan)) {
      if (slice.end.isBefore(cutoff)) {
        slices.add(slice);
        continue;
      }
      if (slice.start.isBefore(cutoff)) {
        final clippedEnd = cutoff.subtract(const Duration(days: 1));
        if (!clippedEnd.isBefore(slice.start)) {
          slices.add(
            slice.copyWith(
              end: clippedEnd,
            ),
          );
        }
      }
    }
    return slices;
  }
}

SavingCalculationResult _runProjection({
  required List<_PlanSlice> slices,
  required double targetAmount,
  required double currentAsset,
  required DateTime startDate,
  required String logTag,
}) {
  final requiredSaving = targetAmount - currentAsset;
  final representative = _representativeSlice(slices, startDate);
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
      goalDateTime: startDate,
      savingPerSecond: 0,
    );
  }

  final timeline = _buildTimeline(slices, startDate);
  if (timeline.isEmpty) {
    debugPrint('[$logTag] timeline empty '
        'start=$startDate target=$requiredSaving');
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
  debugPrint('[$logTag] timeline stats '
      'len=${timeline.length} '
      'range=${timeline.first.date}~${timeline.last.date} '
      'start=$startDate target=$requiredSaving');

  double accumulated = 0.0;
  double totalSeconds = 0.0;
  DateTime? goalDate;
  bool insufficient = false;
  bool nonPositiveDailyNet = false;

  for (final slice in timeline) {
    final dailyNet = slice.dailyNet;
    if (dailyNet <= 0) {
      debugPrint('[$logTag] non-positive dailyNet '
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
    debugPrint('[$logTag] insufficient accumulation '
        'accumulated=$accumulated required=$requiredSaving '
        'timelineLen=${timeline.length}');
    insufficient = true;
  }

  if (insufficient || totalSeconds <= 0) {
    final goal =
        goalDate ?? (timeline.isNotEmpty ? timeline.last.date : startDate);
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
      goalDate ?? startDate.add(Duration(seconds: totalSeconds.round()));

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

List<_PlanSlice> _convertPlanToSlices(TotalPlan plan) {
  final ordered = _orderedMinis(plan);
  if (ordered.isEmpty) return const [];
  return ordered
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
}

List<_PlanSlice> _extendSlicesTo(
  List<_PlanSlice> slices,
  DateTime desiredEnd,
) {
  if (slices.isEmpty) return slices;
  final extended = List<_PlanSlice>.from(slices);
  var lastEnd = extended.last.end;
  if (!lastEnd.isBefore(desiredEnd)) {
    return extended;
  }
  final template = extended.last;
  var cursor = lastEnd.add(const Duration(days: 1));
  while (!cursor.isAfter(desiredEnd)) {
    final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
    final sliceEnd = monthEnd.isAfter(desiredEnd) ? desiredEnd : monthEnd;
    extended.add(
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
  return extended;
}

List<_DailySlice> _buildTimeline(
  List<_PlanSlice> slices,
  DateTime startDate,
) {
  if (slices.isEmpty) return const [];
  final results = <_DailySlice>[];
  for (final slice in slices) {
    var cursor = slice.start;
    if (cursor.isBefore(startDate)) {
      cursor = startDate;
    }
    if (cursor.isAfter(slice.end)) continue;
    while (!cursor.isAfter(slice.end)) {
      if (cursor.isBefore(startDate)) {
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

_PlanSlice? _representativeSlice(List<_PlanSlice> slices, DateTime startDate) {
  if (slices.isEmpty) return null;
  for (final slice in slices) {
    if (!startDate.isAfter(slice.end)) {
      return slice;
    }
  }
  return slices.last;
}

List<MiniPlan> _orderedMinis(TotalPlan plan) {
  final result = <MiniPlan>[];
  final entries = plan.subPlans.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in entries) {
    final subPlan = entry.value;
    result.addAll(subPlan.orderedMinis());
  }
  return result;
}

DateTime _projectionEnd(DateTime start, TotalPlan plan) {
  final planEnd = plan.modEndDate ?? plan.endDate ?? start;
  final horizonEnd = start.add(_kProjectionHorizon);
  if (planEnd.isAfter(horizonEnd)) {
    return planEnd;
  }
  return horizonEnd;
}

int _daysInMonth(int year, int month) {
  final firstOfNextMonth = month == 12
      ? DateTime(year + 1, 1, 1)
      : DateTime(year, month + 1, 1);
  return firstOfNextMonth.subtract(const Duration(days: 1)).day;
}

DateTime _normalizeDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

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

  _PlanSlice copyWith({
    DateTime? start,
    DateTime? end,
    double? monthlyIncome,
    double? monthlyConsume,
    double? dailyLimit,
  }) {
    return _PlanSlice(
      start: start ?? this.start,
      end: end ?? this.end,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyConsume: monthlyConsume ?? this.monthlyConsume,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}


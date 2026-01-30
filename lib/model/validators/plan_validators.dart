import 'dart:developer' as developer;

import '../refData/daily_consume.dart';
import '../plan/mini_plan.dart';
import '../refData/monthly_consume.dart';
import '../refData/monthly_income.dart';
import '../plan/sub_plan.dart';
import '../plan/total_plan.dart';

/// Stateless guard methods used to keep plan edits consistent.

class ValidationResult {
  const ValidationResult._(this.isValid, this.message);

  final bool isValid;
  final String? message;

  static ValidationResult ok() => const ValidationResult._(true, null);

  static ValidationResult fail(String message) =>
      ValidationResult._(false, message);
}

ValidationResult ensureWithinPlan(DateTime date, TotalPlan plan) {
  final start = plan.startDate;
  final end = plan.modEndDate ?? plan.endDate;
  if (start != null && date.isBefore(_normalize(date: start))) {
    developer.log(
      '[ensureWithinPlan] start-boundary failed: date=$date start=$start',
      name: 'PlanValidators',
    );
    return ValidationResult.fail('APPLY_DATE_OUT_OF_RANGE');
  }
  if (end != null && date.isAfter(_normalize(date: end))) {
    developer.log(
      '[ensureWithinPlan] end-boundary failed: date=$date end=$end',
      name: 'PlanValidators',
    );
    return ValidationResult.fail('APPLY_DATE_OUT_OF_RANGE');
  }
  return ValidationResult.ok();
}

ValidationResult ensureDailyContinuity(SubPlan subPlan) {
  final ordered = subPlan.orderedMinis();
  MiniPlan? previous;
  for (final mini in ordered) {
    try {
      mini.validateContinuity(previous: previous);
    } catch (err) {
      return ValidationResult.fail('CONTINUITY_BROKEN');
    }
    previous = mini;
  }
  return ValidationResult.ok();
}

ValidationResult ensureMiniChain(SubPlan subPlan) {
  final ordered = subPlan.orderedMinis();
  for (final mini in ordered) {
    if (mini.startDate.month != subPlan.yearMonth.month ||
        mini.endDate.month != subPlan.yearMonth.month) {
      return ValidationResult.fail('MINI_MONTH_CLIP_VIOLATION');
    }
  }
  return ValidationResult.ok();
}

ValidationResult ensureMonthlyUniqueness({
  required DateTime targetMonth,
  required Iterable<MonthlyIncome> incomes,
  required Iterable<MonthlyConsume> consumes,
}) {
  final normalized = _normalizeMonth(targetMonth);
  final incomeCount = incomes
      .where(
        (income) =>
          income.isActive &&
          income.yearMonthList.contains(normalized),
      )
      .length;
  if (incomeCount > 1) {
    developer.log(
      '[ensureMonthlyUniqueness] income duplication: month=$normalized '
          'ids=${incomes.where((inc) => inc.isActive && inc.yearMonthList.contains(normalized)).map((e) => e.id)}',
      name: 'PlanValidators',
    );
    return ValidationResult.fail('MONTH_DUPLICATION_INCOME');
  }
  final consumeCount = consumes
      .where(
        (consume) =>
          consume.isActive &&
          consume.yearMonthList.contains(normalized),
      )
      .length;
  if (consumeCount > 1) {
    developer.log(
      '[ensureMonthlyUniqueness] consume duplication: month=$normalized '
          'ids=${consumes.where((c) => c.isActive && c.yearMonthList.contains(normalized)).map((e) => e.id)}',
      name: 'PlanValidators',
    );
    return ValidationResult.fail('MONTH_DUPLICATION_CONSUME');
  }
  return ValidationResult.ok();
}

ValidationResult ensureNoDailyOverlap({
  required DateTime targetMonth,
  required Iterable<DailyConsume> dailyConsumes,
}) {
  final normalizedMonth = _normalizeMonth(targetMonth);
  final monthConsumes = dailyConsumes
      .where(
        (daily) =>
            daily.isActive &&
            (_normalizeMonth(daily.startDate) == normalizedMonth ||
                _normalizeMonth(daily.endDate) == normalizedMonth),
      )
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  for (var i = 0; i < monthConsumes.length - 1; i++) {
    final current = monthConsumes[i];
    final next = monthConsumes[i + 1];
    if (!current.endDate.isBefore(next.startDate)) {
      developer.log(
        '[ensureNoDailyOverlap] overlap: month=$normalizedMonth '
            'current=${current.id}(${current.startDate}~${current.endDate}) '
            'next=${next.id}(${next.startDate}~${next.endDate})',
        name: 'PlanValidators',
      );
      return ValidationResult.fail('OVERLAPPING_DAILY_RANGE');
    }
  }
  return ValidationResult.ok();
}

DateTime _normalize({required DateTime date}) =>
    DateTime(date.year, date.month, date.day);

DateTime _normalizeMonth(DateTime date) => DateTime(date.year, date.month);

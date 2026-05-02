import 'package:meta/meta.dart';

import '../refData/daily_consume.dart';
import '../refData/monthly_consume.dart';
import '../refData/monthly_income.dart';
import 'total_plan.dart';

/// Snapshot returned after applying a mutation, including recalculated state.

@immutable
class PlanMutationResult {
  const PlanMutationResult({
    required this.totalPlan,
    required this.monthlyIncomes,
    required this.monthlyConsumes,
    required this.dailyConsumes,
    required this.affectedMonths,
    required this.propagatedMonths,
  });

  final TotalPlan totalPlan;
  final Map<String, MonthlyIncome> monthlyIncomes;
  final Map<String, MonthlyConsume> monthlyConsumes;
  final Map<String, DailyConsume> dailyConsumes;
  final List<DateTime> affectedMonths;
  final List<DateTime> propagatedMonths;

  PlanMutationResult copyWith({
    TotalPlan? totalPlan,
    Map<String, MonthlyIncome>? monthlyIncomes,
    Map<String, MonthlyConsume>? monthlyConsumes,
    Map<String, DailyConsume>? dailyConsumes,
    List<DateTime>? affectedMonths,
    List<DateTime>? propagatedMonths,
  }) {
    return PlanMutationResult(
      totalPlan: totalPlan ?? this.totalPlan,
      monthlyIncomes: monthlyIncomes ?? this.monthlyIncomes,
      monthlyConsumes: monthlyConsumes ?? this.monthlyConsumes,
      dailyConsumes: dailyConsumes ?? this.dailyConsumes,
      affectedMonths: affectedMonths ?? this.affectedMonths,
      propagatedMonths: propagatedMonths ?? this.propagatedMonths,
    );
  }
}

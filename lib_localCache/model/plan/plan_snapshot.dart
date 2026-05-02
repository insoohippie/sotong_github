import 'package:meta/meta.dart';

import '../refData/daily_consume.dart';
import '../refData/monthly_consume.dart';
import '../refData/monthly_income.dart';
import '../refData/ref_data.dart';
import 'total_plan.dart';

/// Immutable in-memory cache that feeds plan mutation operations.

@immutable
class PlanSnapshot {
  const PlanSnapshot({
    required this.totalPlan,
    required this.monthlyIncomes,
    required this.monthlyConsumes,
    required this.dailyConsumes,
  });

  final TotalPlan totalPlan;
  final Map<String, MonthlyIncome> monthlyIncomes;
  final Map<String, MonthlyConsume> monthlyConsumes;
  final Map<String, DailyConsume> dailyConsumes;

  PlanSnapshot copyWith({
    TotalPlan? totalPlan,
    Map<String, MonthlyIncome>? monthlyIncomes,
    Map<String, MonthlyConsume>? monthlyConsumes,
    Map<String, DailyConsume>? dailyConsumes,
  }) {
    return PlanSnapshot(
      totalPlan: totalPlan ?? this.totalPlan,
      monthlyIncomes: monthlyIncomes ?? this.monthlyIncomes,
      monthlyConsumes: monthlyConsumes ?? this.monthlyConsumes,
      dailyConsumes: dailyConsumes ?? this.dailyConsumes,
    );
  }

  factory PlanSnapshot.fromRefData({
    required TotalPlan plan,
    required RefData refData,
  }) {
    return PlanSnapshot(
      totalPlan: plan,
      monthlyIncomes: Map<String, MonthlyIncome>.from(refData.monthlyIncomeMap),
      monthlyConsumes: Map<String, MonthlyConsume>.from(refData.monthlyConsumeMap),
      dailyConsumes: Map<String, DailyConsume>.from(refData.dailyConsumeMap),
    );
  }
}

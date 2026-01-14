import 'dart:math';

import 'package:meta/meta.dart';

// 엮어서 계산하는 파트
/// Immutable snapshot of income/consume aggregates for a date range.

/// Snapshot of monetary metrics calculated over a date range.
@immutable
class PlanMetrics {
  const PlanMetrics({
    required this.startDate,
    required this.endDate,
    required this.kDays,
    required this.monthlyIncomeAmount, // Ref 원본 값
    required this.monthlyConsumeAmount,
    required this.dailyConsumeAmount,
    required this.monthlyNetIncome, // 실제 금액
    required this.monthlyNetConsume,
    required this.dailyNetConsume,
    required this.dailyNetSaving,
    required this.monthlyNetSaving,
    required this.perSecondSaving,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int kDays;
  final int monthlyIncomeAmount;
  final int monthlyConsumeAmount;
  final int dailyConsumeAmount;
  final int monthlyNetIncome;
  final int monthlyNetConsume;
  final int dailyNetConsume;
  final int dailyNetSaving;
  final int monthlyNetSaving;
  final double perSecondSaving;

  /// Constructs a [PlanMetrics] for the supplied range and sums.
  factory PlanMetrics.fromRange({
    required DateTime startDate,
    required DateTime endDate,
    required int sumMonthlyIncome,
    required int sumMonthlyConsume,
    required int sumDailyConsume,
    int monthlyNetIncome = 0,
    int monthlyNetConsume = 0,
    int dailyNetConsume = 0,
  }) {
    final normalizedStart = _normalizeDate(startDate);
    final normalizedEnd = _normalizeDate(endDate);
    final days = _inclusiveDays(normalizedStart, normalizedEnd);
    final daily = _computeDailyNetSaving(
      sumMonthlyIncome: monthlyNetIncome,
      sumMonthlyConsume: monthlyNetConsume + dailyNetConsume,
      sumDailyConsume: 0,
      kDays: days,
    );
    final monthly = daily * days;
    final perSecond = _computePerSecond(daily);
    return PlanMetrics(
      startDate: normalizedStart,
      endDate: normalizedEnd,
      kDays: days,
      monthlyIncomeAmount: sumMonthlyIncome,
      monthlyConsumeAmount: sumMonthlyConsume,
      dailyConsumeAmount: sumDailyConsume,
      monthlyNetIncome: monthlyNetIncome,
      monthlyNetConsume: monthlyNetConsume,
      dailyNetConsume: dailyNetConsume,
      dailyNetSaving: daily,
      monthlyNetSaving: monthly,
      perSecondSaving: perSecond,
    );
  }

  /// Aggregates multiple metric slices into a single result.
  factory PlanMetrics.merge(List<PlanMetrics> slices) {
    if (slices.isEmpty) {
      throw ArgumentError('At least one PlanMetrics slice is required.');
    }
    final sorted = List<PlanMetrics>.from(slices)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final start = sorted.first.startDate;
    final end = sorted.last.endDate;
    final kDays = sorted.fold<int>(0, (sum, m) => sum + m.kDays);
    final sumIncome = sorted.last.monthlyIncomeAmount;
    final sumConsume = sorted.last.monthlyConsumeAmount;
    final sumDaily = sorted.last.dailyConsumeAmount;
    final netIncomeSum =
        sorted.fold<int>(0, (sum, m) => sum + m.monthlyNetIncome);
    final netConsumeSum =
        sorted.fold<int>(0, (sum, m) => sum + m.monthlyNetConsume);
    final netDailySum =
        sorted.fold<int>(0, (sum, m) => sum + m.dailyNetConsume);
    final avgDaily = _computeDailyNetSaving(
      sumMonthlyIncome: netIncomeSum,
      sumMonthlyConsume: netConsumeSum + netDailySum,
      sumDailyConsume: 0,
      kDays: kDays,
    );
    return PlanMetrics(
      startDate: start,
      endDate: end,
      kDays: kDays,
      monthlyIncomeAmount: sumIncome,
      monthlyConsumeAmount: sumConsume,
      dailyConsumeAmount: sumDaily,
      monthlyNetIncome: netIncomeSum,
      monthlyNetConsume: netConsumeSum,
      dailyNetConsume: netDailySum,
      dailyNetSaving: avgDaily,
      monthlyNetSaving: avgDaily * kDays,
      perSecondSaving: _computePerSecond(avgDaily),
    );
  }

  PlanMetrics copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? kDays,
    int? sumMonthlyIncome,
    int? sumMonthlyConsume,
    int? sumDailyConsume,
    int? monthlyNetIncome,
    int? monthlyNetConsume,
    int? dailyNetConsume,
    int? dailyNetSaving,
    int? monthlyNetSaving,
    double? perSecondSaving,
  }) {
    return PlanMetrics(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      kDays: kDays ?? this.kDays,
      monthlyIncomeAmount: sumMonthlyIncome ?? this.monthlyIncomeAmount,
      monthlyConsumeAmount: sumMonthlyConsume ?? this.monthlyConsumeAmount,
      dailyConsumeAmount: sumDailyConsume ?? this.dailyConsumeAmount,
      monthlyNetIncome: monthlyNetIncome ?? this.monthlyNetIncome,
      monthlyNetConsume: monthlyNetConsume ?? this.monthlyNetConsume,
      dailyNetConsume: dailyNetConsume ?? this.dailyNetConsume,
      dailyNetSaving: dailyNetSaving ?? this.dailyNetSaving,
      monthlyNetSaving: monthlyNetSaving ?? this.monthlyNetSaving,
      perSecondSaving: perSecondSaving ?? this.perSecondSaving,
    );
  }

  static DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _inclusiveDays(DateTime start, DateTime end) {
    final diff = end.difference(start).inDays;
    return diff + 1;
  }

  static int _computeDailyNetSaving({
    required int sumMonthlyIncome,
    required int sumMonthlyConsume,
    required int sumDailyConsume,
    required int kDays,
  }) {
    if (kDays <= 0) return 0;
    final numerator =
        sumMonthlyIncome - sumMonthlyConsume - (sumDailyConsume * kDays);
    final raw = numerator / kDays;
    return halfUp(raw);
  }

  static double _computePerSecond(int dailyNetSaving) {
    if (dailyNetSaving == 0) {
      return 0;
    }
    final perSecond = dailyNetSaving / 86400;
    return double.parse(perSecond.toStringAsFixed(2));
  }

  static int halfUp(num value) {
    return value >= 0 ? (value + 0.5).floor() : (value - 0.5).ceil();
  }
}

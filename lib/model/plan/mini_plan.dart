import 'package:meta/meta.dart';

import '../refData/daily_consume.dart';
import '../refData/entry.dart';
import '../refData/monthly_consume.dart';
import '../refData/monthly_income.dart';
import 'plan_metrics.dart';

/// Linked-list node representing a mini plan slice within a month.

@immutable
class MiniPlan {
  const MiniPlan({
    required this.docId,
    required this.yearMonth,
    required this.startDate,
    required this.endDate,
    required this.monthlyIncomeId,
    required this.monthlyConsumeId,
    required this.dailyConsumeId,
    this.prevDocId,
    this.nextDocId,
    this.monthlyIncomeRef,
    this.monthlyConsumeRef,
    this.dailyConsumeRef,
    this.sumMonthlyIncome = 0,
    this.sumMonthlyConsume = 0,
    this.sumDailyConsume = 0,
  }); //: assert(!startDate.isAfter(endDate), 'startDate must be <= endDate');

  final String docId;
  final DateTime yearMonth;
  final DateTime startDate;
  final DateTime endDate;
  final String? prevDocId;
  final String? nextDocId;
  final String monthlyIncomeId;
  final String monthlyConsumeId;
  final String dailyConsumeId;
  final MonthlyIncome? monthlyIncomeRef;
  final MonthlyConsume? monthlyConsumeRef;
  final DailyConsume? dailyConsumeRef;
  final int sumMonthlyIncome;
  final int sumMonthlyConsume;
  final int sumDailyConsume;

  MiniPlan clipToMonth() {
    final clippedStart = DateTime(yearMonth.year, yearMonth.month, 1);
    final clippedEnd = DateTime(yearMonth.year, yearMonth.month + 1, 0);
    return copyWith(
      startDate: startDate.isBefore(clippedStart) ? clippedStart : startDate,
      endDate: endDate.isAfter(clippedEnd) ? clippedEnd : endDate,
    );
  }

  MiniPlan validateContinuity({MiniPlan? previous}) {
    if (previous != null) {
      final expectedStart = previous.endDate.add(const Duration(days: 1));
      if (!expectedStart.isSameDayAs(startDate)) {
        throw StateError(
          'MiniPlan continuity broken: ${previous.docId} -> $docId',
        );
      }
    }
    if (startDate.isAfter(endDate)) {
      throw StateError('MiniPlan range invalid: $docId');
    }
    if (startDate.month != yearMonth.month ||
        endDate.month != yearMonth.month ||
        startDate.year != yearMonth.year ||
        endDate.year != yearMonth.year) {
      throw StateError('MiniPlan must stay within its month: $docId');
    }
    return this;
  }

  MiniPlan attachNext(MiniPlan next) {
    validateContinuity(previous: this);
    return copyWith(nextDocId: next.docId);
  }

  MiniPlanSplit splitAt({
    required DateTime splitDate,
    required String newDocId,
  }) {
    final normalized = DateTime(splitDate.year, splitDate.month, splitDate.day);
    if (normalized.isBefore(startDate) || normalized.isAfter(endDate)) {
      throw StateError('Split date must fall within the mini plan.');
    }
    if (normalized.isAtSameMomentAs(startDate)) {
      throw StateError('Split date must be after startDate.');
    }
    final left = copyWith(
      endDate: normalized.subtract(const Duration(days: 1)),
      nextDocId: newDocId,
    );
    final right = MiniPlan(
      docId: newDocId,
      yearMonth: yearMonth,
      startDate: normalized,
      endDate: endDate,
      prevDocId: left.docId,
      nextDocId: nextDocId,
      monthlyIncomeId: monthlyIncomeId,
      monthlyConsumeId: monthlyConsumeId,
      dailyConsumeId: dailyConsumeId,
      monthlyIncomeRef: monthlyIncomeRef,
      monthlyConsumeRef: monthlyConsumeRef,
      dailyConsumeRef: dailyConsumeRef,
      sumMonthlyIncome: sumMonthlyIncome,
      sumMonthlyConsume: sumMonthlyConsume,
      sumDailyConsume: sumDailyConsume,
    );
    return MiniPlanSplit(left: left, right: right);
  }

  PlanMetrics toMetrics() {
    final monthlyIncomeSum = sumMonthlyIncome != 0
        ? sumMonthlyIncome
        : _sumEntries(monthlyIncomeRef?.entries ?? const []);
    final monthlyConsumeSum = sumMonthlyConsume != 0
        ? sumMonthlyConsume
        : _sumEntries(monthlyConsumeRef?.entries ?? const []);
    final dailyConsumeSum = sumDailyConsume != 0
        ? sumDailyConsume
        : _sumEntries(dailyConsumeRef?.entries ?? const []);
    return PlanMetrics.fromRange(
      startDate: startDate,
      endDate: endDate,
      sumMonthlyIncome: monthlyIncomeSum,
      sumMonthlyConsume: monthlyConsumeSum,
      sumDailyConsume: dailyConsumeSum,
    );
  }

  MiniPlan copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? prevDocId,
    String? nextDocId,
    MonthlyIncome? monthlyIncomeRef,
    MonthlyConsume? monthlyConsumeRef,
    DailyConsume? dailyConsumeRef,
    int? sumMonthlyIncome,
    int? sumMonthlyConsume,
    int? sumDailyConsume,
    String? monthlyIncomeId,
    String? monthlyConsumeId,
    String? dailyConsumeId,
  }) {
    return MiniPlan(
      docId: docId,
      yearMonth: yearMonth,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      prevDocId: prevDocId ?? this.prevDocId,
      nextDocId: nextDocId ?? this.nextDocId,
      monthlyIncomeId: monthlyIncomeId ?? this.monthlyIncomeId,
      monthlyConsumeId: monthlyConsumeId ?? this.monthlyConsumeId,
      dailyConsumeId: dailyConsumeId ?? this.dailyConsumeId,
      monthlyIncomeRef: monthlyIncomeRef ?? this.monthlyIncomeRef,
      monthlyConsumeRef: monthlyConsumeRef ?? this.monthlyConsumeRef,
      dailyConsumeRef: dailyConsumeRef ?? this.dailyConsumeRef,
      sumMonthlyIncome: sumMonthlyIncome ?? this.sumMonthlyIncome,
      sumMonthlyConsume: sumMonthlyConsume ?? this.sumMonthlyConsume,
      sumDailyConsume: sumDailyConsume ?? this.sumDailyConsume,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'yearMonth': DateTime(yearMonth.year, yearMonth.month, 1)
          .toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'prevDocId': prevDocId,
      'nextDocId': nextDocId,
      'monthlyIncomeId': monthlyIncomeId,
      'monthlyConsumeId': monthlyConsumeId,
      'dailyConsumeId': dailyConsumeId,
      'sumMonthlyIncome': sumMonthlyIncome,
      'sumMonthlyConsume': sumMonthlyConsume,
      'sumDailyConsume': sumDailyConsume,
    };
  }

  factory MiniPlan.fromMap(Map<String, dynamic> map) {
    final yearMonth = DateTime.parse(map['yearMonth'] as String);
    return MiniPlan(
      docId: map['docId'] as String,
      yearMonth: DateTime(yearMonth.year, yearMonth.month),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      prevDocId: map['prevDocId'] as String?,
      nextDocId: map['nextDocId'] as String?,
      monthlyIncomeId: map['monthlyIncomeId'] as String,
      monthlyConsumeId: map['monthlyConsumeId'] as String,
      dailyConsumeId: map['dailyConsumeId'] as String,
      sumMonthlyIncome: map['sumMonthlyIncome'] as int? ?? 0,
      sumMonthlyConsume: map['sumMonthlyConsume'] as int? ?? 0,
      sumDailyConsume: map['sumDailyConsume'] as int? ?? 0,
    );
  }

  static int _sumEntries(List<Entry> entries) {
    return entries.fold<int>(
      0,
      (sum, entry) => sum + entry.amount.round(),
    );
  }
}

class MiniPlanSplit {
  const MiniPlanSplit({
    required this.left,
    required this.right,
  });

  final MiniPlan left;
  final MiniPlan right;
}

/// Renders per-mini metrics cached alongside a sub-plan.
@immutable
class MiniPlanResult {
  const MiniPlanResult({
    required this.headDocId,
    required this.miniMetrics,
    required this.miniPlanHead,
  });

  final String headDocId;
  final List<PlanMetrics> miniMetrics;
  final MiniPlan miniPlanHead;

  MiniPlanResult copyWith({
    String? headDocId,
    List<PlanMetrics>? miniMetrics,
    MiniPlan? miniPlanHead,
  }) {
    return MiniPlanResult(
      headDocId: headDocId ?? this.headDocId,
      miniMetrics: miniMetrics ?? this.miniMetrics,
      miniPlanHead: miniPlanHead ?? this.miniPlanHead,
    );
  }
}

extension _DateTimeEx on DateTime {
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

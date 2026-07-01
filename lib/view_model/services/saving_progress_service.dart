import 'dart:math';

import 'package:intl/intl.dart';

import '../../model/plan/mini_plan.dart';
import '../../model/plan/sub_plan.dart';
import '../../model/plan/total_plan.dart';
import '../../model/record/day_record.dart';
import '../../model/record/monthly_record.dart';

enum SavingProgressMode {
  /// 홈:
  /// 보유금액 포함 + 전체 기간 누적 저축분
  homeWithCurrentAsset,

  /// 레포트:
  /// 보유금액 제외 + 선택 범위 누적 저축분
  rangeWithoutCurrentAsset,
}

class SavingProgressService {
  const SavingProgressService();

  SavingProgressResult calculate({
    required TotalPlan? plan,
    required Map<String, MonthlyRecord> monthlyCache,
    required DateTime start,
    required DateTime end,
    required SavingProgressMode mode,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    if (plan == null) {
      return SavingProgressResult.zero();
    }

    final normalizedStart = _dateOnly(start);
    final normalizedEnd = _dateOnly(end);
    final today = _dateOnly(current);

    if (normalizedEnd.isBefore(normalizedStart)) {
      return SavingProgressResult.zero();
    }

    double confirmedSaved = 0.0;

    var cursor = normalizedStart;

    while (!cursor.isAfter(normalizedEnd)) {
      if (cursor.isAfter(today)) break;

      final record = _recordForDate(
        monthlyCache: monthlyCache,
        date: cursor,
      );

      final plannedBudget = _dailyBudgetForDate(
        plan: plan,
        date: cursor,
      );

      final plannedDailySaving = _plannedDailyNetForDate(
        plan: plan,
        date: cursor,
      );

      final actualSpending = _actualSpendingFromRecord(record);
      final extraIncome = record?.totalIncomeAmount ?? 0;

      final hasSpendingEntries = record?.spendingEntries.isNotEmpty ?? false;

      final isBeforeToday = cursor.isBefore(today);
      final isToday = cursor.isAtSameMomentAs(today);

      // 홈 기존 로직과 동일:
      // 과거 날짜는 확정값으로 더함.
      // 오늘은 소비 기록이 있으면 확정값으로 더함.
      // 오늘 소비 기록이 없으면 아래 guideSum에서 초당 증가분으로 처리.
      if (isBeforeToday || (isToday && hasSpendingEntries)) {
        confirmedSaved +=
            plannedDailySaving + plannedBudget - actualSpending + extraIncome;
      }

      cursor = _nextDay(cursor);
    }

    final includesToday =
        !today.isBefore(normalizedStart) && !today.isAfter(normalizedEnd);

    final todayRecord = _recordForDate(
      monthlyCache: monthlyCache,
      date: today,
    );

    final todayHasSpendingEntries =
        todayRecord?.spendingEntries.isNotEmpty ?? false;

    final todayPerSecondSaving =
        _plannedDailyNetForDate(plan: plan, date: today) / 86400.0;

    // 오늘 기록 전이면 오늘 하루저축분을 초당으로 쌓음.
    // 오늘 기록 완료 후에는 이미 confirmedSaved에 확정값으로 들어갔으므로 0.
    final guideSum = includesToday && !todayHasSpendingEntries
        ? _secondsElapsedToday(current) * todayPerSecondSaving
        : 0.0;

    final rangeSavedAmount = confirmedSaved + guideSum;

    final currentAsset = mode == SavingProgressMode.homeWithCurrentAsset
        ? plan.currentAsset.toDouble()
        : 0.0;

    final liveSavedAmount = currentAsset + rangeSavedAmount;

    final plannedSavedAmount = _plannedSavedInRange(
      plan: plan,
      start: normalizedStart,
      end: normalizedEnd.isAfter(today) ? today : normalizedEnd,
      now: current,
      todayConfirmed: todayHasSpendingEntries,
    );

    final plannedAmountWithMode =
    mode == SavingProgressMode.homeWithCurrentAsset
        ? currentAsset + plannedSavedAmount
        : plannedSavedAmount;

    return SavingProgressResult(
      confirmedSaved: confirmedSaved,
      guideSum: guideSum,
      rangeSavedAmount: rangeSavedAmount,
      liveSavedAmount: liveSavedAmount,
      plannedSavedAmount: plannedAmountWithMode,
      perSecondSaving: todayPerSecondSaving,
    );
  }

  double _plannedSavedInRange({
    required TotalPlan plan,
    required DateTime start,
    required DateTime end,
    required DateTime now,
    required bool todayConfirmed,
  }) {
    final today = _dateOnly(now);

    if (end.isBefore(start)) return 0;

    double sum = 0.0;

    var cursor = start;

    while (!cursor.isAfter(end)) {
      if (cursor.isAfter(today)) break;

      final isToday = cursor.isAtSameMomentAs(today);
      final dailyNet = _plannedDailyNetForDate(
        plan: plan,
        date: cursor,
      );

      if (isToday && !todayConfirmed) {
        sum += _secondsElapsedToday(now) * (dailyNet / 86400.0);
      } else {
        sum += dailyNet;
      }

      cursor = _nextDay(cursor);
    }

    return sum;
  }

  DayRecord? _recordForDate({
    required Map<String, MonthlyRecord> monthlyCache,
    required DateTime date,
  }) {
    final normalized = _dateOnly(date);
    final monthKey = DateFormat('yyyy-MM').format(normalized);
    final dateKey = DateFormat('yyyy-MM-dd').format(normalized);

    return monthlyCache[monthKey]?.days[dateKey];
  }

  int _actualSpendingFromRecord(DayRecord? day) {
    if (day == null) return 0;

    final entrySum = day.spendingEntries.fold<int>(
      0,
          (sum, e) => sum + e.amount.round(),
    );

    if (entrySum > 0) return entrySum;

    return day.totalSpendingAmount;
  }

  int _dailyBudgetForDate({
    required TotalPlan plan,
    required DateTime date,
  }) {
    final normalized = _dateOnly(date);
    final key = DateFormat('yyyyMM').format(normalized);
    final subPlan = plan.subPlans[key];

    if (subPlan == null) return 0;

    final mini = _miniForDate(subPlan, normalized);

    if (mini != null) {
      return mini.dailyConsumeAmount;
    }

    return 0;
  }

  double _plannedDailyNetForDate({
    required TotalPlan plan,
    required DateTime date,
  }) {
    final normalized = _dateOnly(date);
    final key = DateFormat('yyyyMM').format(normalized);
    final subPlan = plan.subPlans[key];

    if (subPlan == null) return 0;

    final mini = _miniForDate(subPlan, normalized);

    if (mini == null) return 0;

    final daysInMonth = DateTime(
      normalized.year,
      normalized.month + 1,
      0,
    ).day;

    final monthlyNet = mini.monthlyIncomeAmount -
        mini.monthlyConsumeAmount -
        (mini.dailyConsumeAmount * daysInMonth);

    return monthlyNet / daysInMonth;
  }

  MiniPlan? _miniForDate(SubPlan subPlan, DateTime date) {
    final normalized = _dateOnly(date);

    for (final mini in subPlan.orderedMinis()) {
      final start = _dateOnly(mini.startDate);
      final end = _dateOnly(mini.endDate);

      if (!normalized.isBefore(start) && !normalized.isAfter(end)) {
        return mini;
      }
    }

    return null;
  }

  int _secondsElapsedToday(DateTime now) {
    final todayStart = _dateOnly(now);
    return max(0, now.difference(todayStart).inSeconds);
  }

  DateTime _dateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  DateTime _nextDay(DateTime d) {
    return DateTime(d.year, d.month, d.day).add(const Duration(days: 1));
  }
}

class SavingProgressResult {
  const SavingProgressResult({
    required this.confirmedSaved,
    required this.guideSum,
    required this.rangeSavedAmount,
    required this.liveSavedAmount,
    required this.plannedSavedAmount,
    required this.perSecondSaving,
  });

  factory SavingProgressResult.zero() {
    return const SavingProgressResult(
      confirmedSaved: 0,
      guideSum: 0,
      rangeSavedAmount: 0,
      liveSavedAmount: 0,
      plannedSavedAmount: 0,
      perSecondSaving: 0,
    );
  }

  /// 기록 완료된 날짜들의 확정 저축분.
  /// 보유금액 미포함.
  final double confirmedSaved;

  /// 오늘 기록 전일 때 초당으로 쌓이는 오늘 저축분.
  /// 보유금액 미포함.
  final double guideSum;

  /// 해당 범위 안에서 쌓인 금액.
  /// 보유금액 미포함.
  final double rangeSavedAmount;

  /// 화면에 최종 표시할 금액.
  /// homeWithCurrentAsset 모드에서는 보유금액 포함.
  /// rangeWithoutCurrentAsset 모드에서는 보유금액 미포함.
  final double liveSavedAmount;

  /// 계획상 현재까지 쌓였어야 하는 금액.
  final double plannedSavedAmount;

  /// 오늘 기준 초당 저축액.
  final double perSecondSaving;
}
import 'dart:developer' as developer;

import '../model/commands/update_daily_command.dart';
import '../model/commands/update_monthly_command.dart';
import '../model/plan/plan_mutation_exception.dart';
import '../model/plan/plan_mutation_result.dart';
import '../model/plan/plan_snapshot.dart';
import '../model/validators/plan_validators.dart';
import '../repository/plan_mutation_repository.dart';
import '../model/refData/ref_data.dart';
import 'plan_debug_printer.dart';

/// Orchestrates mutation commands with validation before persisting changes.

class PlanMutationService {
  PlanMutationService(this._repository);

  final PlanMutationRepository _repository;

  PlanMutationResult applyMonthly({
    required UpdateMonthlyCommand command,
    required PlanSnapshot snapshot,
  }) {
    developer.log(
      '[applyMonthly] month=${command.applyMonth} '
          'modEnd=${command.modEndMonth} '
          'newId=${command.newDocumentId} prev=${command.previousDocumentId}',
      name: 'PlanMutationService',
    );
    final plan = snapshot.totalPlan;
    final originalApplyMonth = command.applyMonth;
    final originalModEndMonth = command.modEndMonth;
    final boundaryPlan = plan;
    final planStart = plan.startDate;
    final planEnd = plan.modEndDate ?? plan.endDate;
    final clampedApplyMonth = _clampMonth(command.applyMonth, planStart, planEnd);
    final clampedModEndMonth = _clampMonth(command.modEndMonth, planStart, planEnd);
    if (clampedApplyMonth.isAfter(clampedModEndMonth)) {
      developer.log(
        'applyMonthly clamped range empty: apply=$clampedApplyMonth modEnd=$clampedModEndMonth planStart=$planStart planEnd=$planEnd',
        name: 'PlanMutationService',
      );
      return PlanMutationResult(
        totalPlan: snapshot.totalPlan,
        monthlyIncomes: snapshot.monthlyIncomes,
        monthlyConsumes: snapshot.monthlyConsumes,
        dailyConsumes: snapshot.dailyConsumes,
        affectedMonths: const [],
        propagatedMonths: const [],
      );
    }
    final clampedApplyBoundary =
    _clampDay(command.applyMonth, planStart, planEnd);
    final boundaryCheck = ensureWithinPlan(clampedApplyBoundary, boundaryPlan);
    if (!boundaryCheck.isValid) {
      developer.log(
        'applyMonthly boundary fail: ${boundaryCheck.message} (plan start=${plan.startDate}, end=${plan.modEndDate ?? plan.endDate})',
        name: 'PlanMutationService',
      );
      throw PlanMutationException(boundaryCheck.message ?? 'OUT_OF_RANGE');
    }

    final effectiveCommand =
    (clampedApplyMonth == originalApplyMonth &&
        clampedModEndMonth == originalModEndMonth)
        ? command
        : UpdateMonthlyCommand(
      applyMonth: clampedApplyMonth,
      modEndMonth: clampedModEndMonth,
      entries: command.entries,
      newDocumentId: command.newDocumentId,
      previousDocumentId: command.previousDocumentId,
      isIncome: command.isIncome,
      allowBeforePlanStart: command.allowBeforePlanStart,
    );

    final uniqueness = ensureMonthlyUniqueness(
      targetMonth: effectiveCommand.applyMonth,
      incomes: snapshot.monthlyIncomes.values,
      consumes: snapshot.monthlyConsumes.values,
    );
    if (!uniqueness.isValid && command.previousDocumentId == null) {
      developer.log(
        'applyMonthly uniqueness fail: ${uniqueness.message} '
            '(existing income=${snapshot.monthlyIncomes.keys} consumes=${snapshot.monthlyConsumes.keys})',
        name: 'PlanMutationService',
      );
      throw PlanMutationException(uniqueness.message ?? 'MONTH_DUPLICATION');
    }

    final result = _repository.applyMonthly(
      totalPlan: plan,
      monthlyIncomes: snapshot.monthlyIncomes,
      monthlyConsumes: snapshot.monthlyConsumes,
      dailyConsumes: snapshot.dailyConsumes,
      command: effectiveCommand,
    );

    for (final month in result.affectedMonths) {
      final subPlan = result.totalPlan.subPlanByKey(
        _formatYearMonth(month),
      );
      if (subPlan == null) continue;
      final continuity = ensureDailyContinuity(subPlan);
      if (!continuity.isValid) {
        throw PlanMutationException(continuity.message ?? 'CONTINUITY_BROKEN');
      }
    }
    _logPlanResult('applyMonthly', result);

    return result;
  }

  PlanMutationResult applyDaily({
    required UpdateDailyCommand command,
    required PlanSnapshot snapshot,
  }) {
    developer.log(
      '[applyDaily] apply=${command.applyDate} end=${command.modEndDate} '
          'newId=${command.newDailyId} prev=${command.previousDailyId}',
      name: 'PlanMutationService',
    );
    final boundaryPlan = snapshot.totalPlan;
    final planStart = boundaryPlan.startDate;
    final planEnd = boundaryPlan.modEndDate ?? boundaryPlan.endDate;
    final clampedApplyDate = _clampDay(command.applyDate, planStart, planEnd);
    final clampedModEndDate = _clampDay(command.modEndDate, planStart, planEnd);
    if (clampedApplyDate.isAfter(clampedModEndDate)) {
      developer.log(
        'applyDaily clamped range empty: apply=$clampedApplyDate modEnd=$clampedModEndDate planStart=$planStart planEnd=$planEnd',
        name: 'PlanMutationService',
      );
      return PlanMutationResult(
        totalPlan: snapshot.totalPlan,
        monthlyIncomes: snapshot.monthlyIncomes,
        monthlyConsumes: snapshot.monthlyConsumes,
        dailyConsumes: snapshot.dailyConsumes,
        affectedMonths: const [],
        propagatedMonths: const [],
      );
    }
    final boundaryCheck = ensureWithinPlan(clampedApplyDate, boundaryPlan);
    if (!boundaryCheck.isValid) {
      developer.log(
        'applyDaily boundary fail: ${boundaryCheck.message}',
        name: 'PlanMutationService',
      );
      throw PlanMutationException(boundaryCheck.message ?? 'OUT_OF_RANGE');
    }

    final preOverlap = ensureNoDailyOverlap(
      targetMonth: clampedApplyDate,
      dailyConsumes: snapshot.dailyConsumes.values,
    );
    if (!preOverlap.isValid && command.previousDailyId == null) {
      developer.log(
        'applyDaily overlap fail: ${preOverlap.message}',
        name: 'PlanMutationService',
      );
      throw PlanMutationException(preOverlap.message ?? 'OVERLAPPING_DAILY_RANGE');
    }

    final adjustedDailyCommand = (clampedApplyDate == command.applyDate &&
        clampedModEndDate == command.modEndDate)
        ? command
        : UpdateDailyCommand(
      applyDate: clampedApplyDate,
      modEndDate: clampedModEndDate,
      entries: command.entries,
      newDailyId: command.newDailyId,
      newMiniDocId: command.newMiniDocId,
      previousDailyId: command.previousDailyId,
      allowBeforePlanStart: command.allowBeforePlanStart,
    );

    final result = _repository.applyDaily(
      totalPlan: snapshot.totalPlan,
      monthlyIncomes: snapshot.monthlyIncomes,
      monthlyConsumes: snapshot.monthlyConsumes,
      dailyConsumes: snapshot.dailyConsumes,
      command: adjustedDailyCommand,
    );

    final monthKey = _formatYearMonth(adjustedDailyCommand.applyDate);
    final subPlan = result.totalPlan.subPlanByKey(monthKey);
    if (subPlan != null) {
      final continuity = ensureDailyContinuity(subPlan);
      if (!continuity.isValid) {
        throw PlanMutationException(continuity.message ?? 'CONTINUITY_BROKEN');
      }
      final monthClip = ensureMiniChain(subPlan);
      if (!monthClip.isValid) {
        throw PlanMutationException(monthClip.message ?? 'MINI_MONTH_CLIP');
      }
    }
    _logPlanResult('applyDaily', result);

    return result;
  }

  String _formatYearMonth(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}${month.month.toString().padLeft(2, '0')}';

  PlanMutationResult applyCommands({
    required List<UpdateMonthlyCommand> monthlyCommands,
    required List<UpdateDailyCommand> dailyCommands,
    required PlanSnapshot snapshot,
  }) {
    var currentSnapshot = snapshot;
    PlanMutationResult? lastResult;

    for (final command in monthlyCommands) {
      lastResult = applyMonthly(command: command, snapshot: currentSnapshot);
      currentSnapshot = PlanSnapshot(
        totalPlan: lastResult.totalPlan,
        monthlyIncomes: lastResult.monthlyIncomes,
        monthlyConsumes: lastResult.monthlyConsumes,
        dailyConsumes: lastResult.dailyConsumes,
      );
    }

    for (final command in dailyCommands) {
      lastResult = applyDaily(command: command, snapshot: currentSnapshot);
      currentSnapshot = PlanSnapshot(
        totalPlan: lastResult.totalPlan,
        monthlyIncomes: lastResult.monthlyIncomes,
        monthlyConsumes: lastResult.monthlyConsumes,
        dailyConsumes: lastResult.dailyConsumes,
      );
    }

    if (lastResult == null) {
      return PlanMutationResult(
        totalPlan: snapshot.totalPlan,
        monthlyIncomes: snapshot.monthlyIncomes,
        monthlyConsumes: snapshot.monthlyConsumes,
        dailyConsumes: snapshot.dailyConsumes,
        affectedMonths: const [],
        propagatedMonths: const [],
      );
    }

    return lastResult;
  }

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _normalizeMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  DateTime _clampDay(
      DateTime date,
      DateTime? planStart,
      DateTime? planEnd,
      ) {
    var result = _normalizeDay(date);
    if (planStart != null) {
      final normalizedStart = _normalizeDay(planStart);
      if (result.isBefore(normalizedStart)) {
        result = normalizedStart;
      }
    }
    if (planEnd != null) {
      final normalizedEnd = _normalizeDay(planEnd);
      if (result.isAfter(normalizedEnd)) {
        result = normalizedEnd;
      }
    }
    return result;
  }

  DateTime _clampMonth(
      DateTime month,
      DateTime? planStart,
      DateTime? planEnd,
      ) {
    var result = _normalizeMonth(month);
    if (planStart != null) {
      final startMonth = _normalizeMonth(planStart);
      if (result.isBefore(startMonth)) {
        result = startMonth;
      }
    }
    if (planEnd != null) {
      final endMonth = _normalizeMonth(planEnd);
      if (result.isAfter(endMonth)) {
        result = endMonth;
      }
    }
    return result;
  }

  void _logPlanResult(String label, PlanMutationResult result) {
    final debugRef = RefData(
      planId: result.totalPlan.planId,
      monthlyIncomes: result.monthlyIncomes,
      monthlyConsumes: result.monthlyConsumes,
      dailyConsumes: result.dailyConsumes,
    );
    final tree = PlanDebugPrinter.describe(
      plan: result.totalPlan,
      refData: debugRef,
    );
    developer.log(
      '[$label] result plan:\n$tree',
      name: 'PlanMutationService',
    );
  }
}
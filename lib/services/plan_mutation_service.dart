import 'dart:developer' as developer;

import '../model/commands/update_daily_command.dart';
import '../model/commands/update_monthly_command.dart';
import '../model/plan/plan_mutation_exception.dart';
import '../model/plan/plan_mutation_result.dart';
import '../model/plan/plan_snapshot.dart';
import '../model/validators/plan_validators.dart';
import '../repository/plan_mutation_repository.dart';

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
    final startOfMonth =
        DateTime(command.applyMonth.year, command.applyMonth.month, 1);
    final boundaryCheck = ensureWithinPlan(startOfMonth, plan);
    if (!boundaryCheck.isValid) {
      developer.log(
        'applyMonthly boundary fail: ${boundaryCheck.message} (plan start=${plan.startDate}, end=${plan.modEndDate ?? plan.endDate})',
        name: 'PlanMutationService',
      );
      throw PlanMutationException(boundaryCheck.message ?? 'OUT_OF_RANGE');
    }

    final uniqueness = ensureMonthlyUniqueness(
      targetMonth: command.applyMonth,
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
      command: command,
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
    final boundaryCheck = ensureWithinPlan(command.applyDate, snapshot.totalPlan);
    if (!boundaryCheck.isValid) {
      developer.log(
        'applyDaily boundary fail: ${boundaryCheck.message}',
        name: 'PlanMutationService',
      );
      throw PlanMutationException(boundaryCheck.message ?? 'OUT_OF_RANGE');
    }

    final preOverlap = ensureNoDailyOverlap(
      targetMonth: command.applyDate,
      dailyConsumes: snapshot.dailyConsumes.values,
    );
    if (!preOverlap.isValid && command.previousDailyId == null) {
      developer.log(
        'applyDaily overlap fail: ${preOverlap.message}',
        name: 'PlanMutationService',
      );
      throw PlanMutationException(preOverlap.message ?? 'OVERLAPPING_DAILY_RANGE');
    }

    final result = _repository.applyDaily(
      totalPlan: snapshot.totalPlan,
      monthlyIncomes: snapshot.monthlyIncomes,
      monthlyConsumes: snapshot.monthlyConsumes,
      dailyConsumes: snapshot.dailyConsumes,
      command: command,
    );

    final monthKey = _formatYearMonth(command.applyDate);
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
}

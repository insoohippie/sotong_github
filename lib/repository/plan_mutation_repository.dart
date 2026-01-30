import 'dart:math';

import '../model/commands/update_daily_command.dart';
import '../model/commands/update_monthly_command.dart';
import '../model/refData/entry.dart';
import '../model/plan/mini_plan.dart';
import '../model/plan/plan_mutation_result.dart';
import '../model/plan/sub_plan.dart';
import '../model/plan/total_plan.dart';
import '../model/refData/daily_consume.dart';
import '../model/refData/monthly_consume.dart';
import '../model/refData/monthly_income.dart';

/// Applies transactional plan edits to in-memory aggregates before persistence.

class PlanMutationRepository {
  PlanMutationResult applyMonthly({
    required TotalPlan totalPlan,
    required Map<String, MonthlyIncome> monthlyIncomes,
    required Map<String, MonthlyConsume> monthlyConsumes,
    required Map<String, DailyConsume> dailyConsumes,
    required UpdateMonthlyCommand command,
  }) {
    final months = command.affectedMonths();
    final updatedSubPlans = Map<String, SubPlan>.from(totalPlan.subPlans);
    final updatedIncomes = Map<String, MonthlyIncome>.from(monthlyIncomes);
    final updatedConsumes = Map<String, MonthlyConsume>.from(monthlyConsumes);

    final monthlySum = _sumEntries(command.entries);

    if (command.isIncome) {
      final newIncome = MonthlyIncome.newForMonths(
        id: command.newDocumentId,
        yearMonthList: months,
        entries: command.entries,
      );
      updatedIncomes[newIncome.id] = newIncome;
      if (command.previousDocumentId != null) {
        final prev = updatedIncomes[command.previousDocumentId];
        if (prev != null) {
          updatedIncomes[prev.id] = prev.removeMonths(months);
        }
      }
      for (final month in months) {
        final key = _formatYearMonth(month);
        final subPlan = updatedSubPlans[key];
        if (subPlan == null) {
          throw StateError('Missing SubPlan for month $key');
        }
        final patched = <String, MiniPlan>{};
        subPlan.miniPlans.forEach((docId, mini) {
          patched[docId] = mini
              .copyWith(
            monthlyIncomeId: newIncome.id,
            monthlyIncomeRef: newIncome,
            sumMonthlyIncome: monthlySum,
          )
              .recalculateNetAmounts();
        });
        updatedSubPlans[key] =
            subPlan.copyWith(miniPlans: patched).recalculate();
      }
    } else {
      final newConsume = MonthlyConsume.newForMonths(
        id: command.newDocumentId,
        yearMonthList: months,
        entries: command.entries,
      );
      updatedConsumes[newConsume.id] = newConsume;
      if (command.previousDocumentId != null) {
        final prev = updatedConsumes[command.previousDocumentId];
        if (prev != null) {
          updatedConsumes[prev.id] = prev.removeMonths(months);
        }
      }
      for (final month in months) {
        final key = _formatYearMonth(month);
        final subPlan = updatedSubPlans[key];
        if (subPlan == null) {
          throw StateError('Missing SubPlan for month $key');
        }
        final patched = <String, MiniPlan>{};
        subPlan.miniPlans.forEach((docId, mini) {
          patched[docId] = mini
              .copyWith(
            monthlyConsumeId: newConsume.id,
            monthlyConsumeRef: newConsume,
            sumMonthlyConsume: monthlySum,
          )
              .recalculateNetAmounts();
        });
        updatedSubPlans[key] =
            subPlan.copyWith(miniPlans: patched).recalculate();
      }
    }

    final recalculatedPlan =
        totalPlan.copyWith(subPlans: updatedSubPlans).recalculateTotals();

    return PlanMutationResult(
      totalPlan: recalculatedPlan,
      monthlyIncomes: updatedIncomes,
      monthlyConsumes: updatedConsumes,
      dailyConsumes: dailyConsumes,
      affectedMonths: months,
      propagatedMonths: months,
    );
  }

  PlanMutationResult applyDaily({
    required TotalPlan totalPlan,
    required Map<String, MonthlyIncome> monthlyIncomes,
    required Map<String, MonthlyConsume> monthlyConsumes,
    required Map<String, DailyConsume> dailyConsumes,
    required UpdateDailyCommand command,
  }) {
    final months = command.propagatedMonths();
    final updatedSubPlans = Map<String, SubPlan>.from(totalPlan.subPlans);
    final updatedDaily = Map<String, DailyConsume>.from(dailyConsumes);

    final normalizedApply =
        DateTime(command.applyDate.year, command.applyDate.month, command.applyDate.day);
    if (command.previousDailyId != null) {
      final prev = updatedDaily[command.previousDailyId];
      if (prev != null) {
        if (normalizedApply.isAfter(prev.startDate)) {
          updatedDaily[prev.id] = prev.endAt(
            normalizedApply.subtract(const Duration(days: 1)),
          );
        } else {
          updatedDaily[prev.id] = prev.softDelete(
            normalizedApply.subtract(const Duration(days: 1)),
          );
        }
      }
    } else {
      final existing = _findDailyForDate(updatedDaily.values, normalizedApply);
      if (existing != null) {
        if (normalizedApply.isAfter(existing.startDate)) {
          updatedDaily[existing.id] = existing.endAt(
            normalizedApply.subtract(const Duration(days: 1)),
          );
        } else {
          updatedDaily[existing.id] = existing.softDelete(
            normalizedApply.subtract(const Duration(days: 1)),
          );
        }
      }
    }

    final newDaily = DailyConsume.newRange(
      id: command.newDailyId,
      startDate: normalizedApply,
      endDate: command.modEndDate,
      entries: command.entries,
    );
    updatedDaily[newDaily.id] = newDaily;

    final dailySum = _sumEntries(command.entries);
    final applyKey = _formatYearMonth(normalizedApply);
    final applySubPlan = updatedSubPlans[applyKey];
    if (applySubPlan == null) {
      throw StateError('Missing SubPlan for month $applyKey');
    }
    final targetMini = _findMiniForDate(applySubPlan, normalizedApply);
    if (targetMini == null) {
      throw StateError('Missing MiniPlan for apply date $normalizedApply');
    }

    SubPlan patchedSubPlan;
    if (normalizedApply.isAfter(targetMini.startDate)) {
      final split = targetMini.splitAt(
        splitDate: normalizedApply,
        newDocId: command.newMiniDocId,
      );
      final left = split.left;
      final rightEnd = _isSameMonth(normalizedApply, command.modEndDate)
          ? _minDate(split.right.endDate, command.modEndDate)
          : split.right.endDate;
      final right = split.right
          .copyWith(
        dailyConsumeId: newDaily.id,
        dailyConsumeRef: newDaily,
        sumDailyConsume: dailySum,
        endDate: rightEnd,
      )
          .recalculateNetAmounts();
      final updatedMinis = Map<String, MiniPlan>.from(applySubPlan.miniPlans);
      updatedMinis[left.docId] = left;
      updatedMinis[right.docId] = right;
      if (right.nextDocId != null) {
        final next = updatedMinis[right.nextDocId!];
        if (next != null) {
          updatedMinis[right.nextDocId!] =
              next.copyWith(prevDocId: right.docId);
        }
      }
      patchedSubPlan =
          applySubPlan.copyWith(miniPlans: updatedMinis).recalculate();
      if (_isSameMonth(normalizedApply, command.modEndDate)) {
        patchedSubPlan = _truncateSubPlan(patchedSubPlan, command.modEndDate);
      }
    } else {
      final endDate = _isSameMonth(normalizedApply, command.modEndDate)
          ? _minDate(targetMini.endDate, command.modEndDate)
          : targetMini.endDate;
      final updatedMini = targetMini
          .copyWith(
        dailyConsumeId: newDaily.id,
        dailyConsumeRef: newDaily,
        sumDailyConsume: dailySum,
        endDate: endDate,
      )
          .recalculateNetAmounts();
      patchedSubPlan = applySubPlan.replaceMini(updatedMini);
      if (_isSameMonth(normalizedApply, command.modEndDate)) {
        patchedSubPlan = _truncateSubPlan(patchedSubPlan, command.modEndDate);
      }
    }
    updatedSubPlans[applyKey] = patchedSubPlan.recalculate();

    for (final month in months.skip(1)) {
      final key = _formatYearMonth(month);
      final subPlan = updatedSubPlans[key];
      if (subPlan == null) {
        continue;
      }
      final patched = <String, MiniPlan>{};
      subPlan.miniPlans.forEach((docId, mini) {
        patched[docId] = mini
            .copyWith(
          dailyConsumeId: newDaily.id,
          dailyConsumeRef: newDaily,
          sumDailyConsume: dailySum,
        )
            .recalculateNetAmounts();
      });
      var truncatedSubPlan =
          subPlan.copyWith(miniPlans: patched).recalculate();
      if (_isSameMonth(month, command.modEndDate)) {
        truncatedSubPlan = _truncateSubPlan(truncatedSubPlan, command.modEndDate);
      }
      updatedSubPlans[key] = truncatedSubPlan;
    }

    _removeSubPlansAfter(command.modEndDate, updatedSubPlans);

    final recalculatedPlan =
        totalPlan.copyWith(subPlans: updatedSubPlans, modEndDate: command.modEndDate)
            .recalculateTotals();

    return PlanMutationResult(
      totalPlan: recalculatedPlan,
      monthlyIncomes: monthlyIncomes,
      monthlyConsumes: monthlyConsumes,
      dailyConsumes: updatedDaily,
      affectedMonths: [DateTime(normalizedApply.year, normalizedApply.month)],
      propagatedMonths: months,
    );
  }

  static int _sumEntries(List<Entry> entries) {
    return entries.fold<int>(
      0,
      (sum, entry) => sum + entry.amount.round(),
    );
  }

  static String _formatYearMonth(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}${month.month.toString().padLeft(2, '0')}';

  static DailyConsume? _findDailyForDate(
    Iterable<DailyConsume> dailyConsumes,
    DateTime date,
  ) {
    for (final daily in dailyConsumes) {
      if (!daily.startDate.isAfter(date) && !daily.endDate.isBefore(date)) {
        return daily;
      }
    }
    return null;
  }

  static MiniPlan? _findMiniForDate(SubPlan subPlan, DateTime date) {
    for (final mini in subPlan.orderedMinis()) {
      if (!mini.startDate.isAfter(date) && !mini.endDate.isBefore(date)) {
        return mini;
      }
    }
    return null;
  }

  SubPlan _truncateSubPlan(SubPlan subPlan, DateTime cutoff) {
    final normalizedCutoff =
    DateTime(cutoff.year, cutoff.month, cutoff.day);
    final fractionalSeconds = min(
      86399,
      max(0, cutoff.difference(normalizedCutoff).inSeconds),
    );
    final ordered = subPlan.orderedMinis();
    final updated = <String, MiniPlan>{};
    MiniPlan? previous;
    String? headId;
    for (final mini in ordered) {
      if (mini.startDate.isAfter(normalizedCutoff)) {
        continue;
      }
      var current = mini;
      if (mini.endDate.isAfter(normalizedCutoff)) {
        current = current.copyWith(endDate: normalizedCutoff);
      }
      current = current.copyWith(
        prevDocId: previous?.docId,
        nextDocId: null,
      ).recalculateNetAmounts();
      if (previous != null) {
        updated[previous.docId] = updated[previous.docId]!
            .copyWith(nextDocId: current.docId);
      }
      updated[current.docId] = current;
      previous = current;
      headId ??= current.docId;
      if (current.endDate.isAtSameMomentAs(normalizedCutoff)) {
        break;
      }
    }
    if (updated.isEmpty) {
      return subPlan;
    }
    return subPlan
        .copyWith(
          headDocId: headId!,
          miniPlans: updated,
          fractionalEndSeconds: fractionalSeconds,
        )
        .recalculate();
  }

  void _removeSubPlansAfter(
    DateTime cutoff,
    Map<String, SubPlan> subPlans,
  ) {
    final cutoffKey = _formatYearMonth(cutoff);
    final toRemove = subPlans.keys
        .where((key) => key.compareTo(cutoffKey) > 0)
        .toList(growable: false);
    for (final key in toRemove) {
      subPlans.remove(key);
    }
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

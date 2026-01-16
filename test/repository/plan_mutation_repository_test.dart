import 'package:flutter_test/flutter_test.dart';
import 'package:sotong_local/model/commands/update_daily_command.dart';
import 'package:sotong_local/model/plan/mini_plan.dart';
import 'package:sotong_local/model/plan/plan_metrics.dart';
import 'package:sotong_local/model/plan/sub_plan.dart';
import 'package:sotong_local/model/plan/total_plan.dart';
import 'package:sotong_local/model/refData/daily_consume.dart';
import 'package:sotong_local/model/refData/entry.dart';
import 'package:sotong_local/model/refData/monthly_consume.dart';
import 'package:sotong_local/model/refData/monthly_income.dart';
import 'package:sotong_local/repository/plan_mutation_repository.dart';

MiniPlan _buildMini({
  required String docId,
  required DateTime month,
  required DateTime start,
  required DateTime end,
  required String dailyId,
}) {
  return MiniPlan(
    docId: docId,
    yearMonth: DateTime(month.year, month.month),
    startDate: start,
    endDate: end,
    monthlyIncomeId: 'inc-001',
    monthlyConsumeId: 'con-001',
    dailyConsumeId: dailyId,
    sumMonthlyIncome: 0,
    sumMonthlyConsume: 0,
    sumDailyConsume: 0,
  );
}

SubPlan _buildSubPlan(String key, MiniPlan mini) {
  return SubPlan(
    yearMonth: DateTime(mini.yearMonth.year, mini.yearMonth.month),
    headDocId: mini.docId,
    miniPlans: {mini.docId: mini},
    miniResult: MiniPlanResult(
      headDocId: mini.docId,
      miniMetrics: const [],
      headMiniPlan: mini,
    ),
  );
}

TotalPlan _buildTotalPlan({
  required Map<String, SubPlan> subPlans,
}) {
  final metrics = PlanMetrics.fromRange(
    startDate: DateTime(2025, 9, 1),
    endDate: DateTime(2025, 10, 31),
    sumMonthlyIncome: 0,
    sumMonthlyConsume: 0,
    sumDailyConsume: 0,
  );
  return TotalPlan(
    planId: 'plan',
    planName: 'Test Plan',
    targetAmount: 0,
    currentAmount: 0,
    currentAsset: 0,
    startDate: DateTime(2025, 9, 1),
    endDate: DateTime(2025, 12, 31),
    modEndDate: DateTime(2025, 12, 31),
    creationDate: DateTime(2025, 1, 1),
    autoService: false,
    subPlans: subPlans,
    result: TotalResult(
      totalMetrics: metrics,
      subResult: SubPlanResult(subMetrics: const [], subPlanList: subPlans.values.toList()),
    ),
  );
}

void main() {
  group('PlanMutationRepository.applyDaily', () {
    test('splits mini plan and propagates new daily consume to future months', () {
      final monthlyIncome = MonthlyIncome.newForMonths(
        id: 'inc-001',
        yearMonthList: [DateTime(2025, 9), DateTime(2025, 10)],
        entries: [
          Entry(
            idx: 0,
            amount: 1500000.0,
            category: 'Salary',
            type: EntryType.fixed,
          ),
        ],
      );
      final monthlyConsume = MonthlyConsume.newForMonths(
        id: 'con-001',
        yearMonthList: [DateTime(2025, 9), DateTime(2025, 10)],
        entries: [
          Entry(
            idx: 0,
            amount: 500000.0,
            category: 'Rent',
            type: EntryType.fixed,
          ),
        ],
      );
      final baseDaily = DailyConsume.newRange(
        id: 'day-202509-001',
        startDate: DateTime(2025, 9, 1),
        endDate: DateTime(2025, 10, 31),
        entries: [
          Entry(
            idx: 0,
            amount: 20000.0,
            category: 'Baseline',
            type: EntryType.daily,
          ),
        ],
      );

      final septemberMini = _buildMini(
        docId: '202509-001',
        month: DateTime(2025, 9),
        start: DateTime(2025, 9, 1),
        end: DateTime(2025, 9, 30),
        dailyId: baseDaily.id,
      );
      final octoberMini = _buildMini(
        docId: '202510-001',
        month: DateTime(2025, 10),
        start: DateTime(2025, 10, 1),
        end: DateTime(2025, 10, 31),
        dailyId: baseDaily.id,
      );

      final totalPlan = _buildTotalPlan(
        subPlans: {
          '202509': _buildSubPlan('202509', septemberMini),
          '202510': _buildSubPlan('202510', octoberMini),
        },
      );

      final repository = PlanMutationRepository();
      final result = repository.applyDaily(
        totalPlan: totalPlan,
        monthlyIncomes: {monthlyIncome.id: monthlyIncome},
        monthlyConsumes: {monthlyConsume.id: monthlyConsume},
        dailyConsumes: {baseDaily.id: baseDaily},
        command: UpdateDailyCommand(
          applyDate: DateTime(2025, 9, 15),
          modEndDate: DateTime(2025, 10, 31),
          entries: [
            Entry(
              idx: 1,
              amount: 25000.0,
              category: 'Updated Daily',
              type: EntryType.daily,
            ),
          ],
          newDailyId: 'day-202509-002',
          newMiniDocId: '202509-002',
          previousDailyId: baseDaily.id,
        ),
      );

      final updatedSept = result.totalPlan.subPlans['202509']!;
      expect(updatedSept.miniPlans.length, 2);
      final left = updatedSept.miniPlans['202509-001']!;
      final right = updatedSept.miniPlans['202509-002']!;
      expect(left.endDate, equals(DateTime(2025, 9, 14)));
      expect(right.startDate, equals(DateTime(2025, 9, 15)));
      expect(right.dailyConsumeId, equals('day-202509-002'));
      expect(right.prevDocId, equals('202509-001'));

      final updatedOct = result.totalPlan.subPlans['202510']!;
      final octoberSlice = updatedOct.miniPlans['202510-001']!;
      expect(octoberSlice.dailyConsumeId, equals('day-202509-002'));

      final truncatedDaily = result.dailyConsumes[baseDaily.id]!;
      expect(truncatedDaily.endDate, equals(DateTime(2025, 9, 14)));
      expect(truncatedDaily.isActive, isTrue);
      final newDaily = result.dailyConsumes['day-202509-002']!;
      expect(newDaily.startDate, equals(DateTime(2025, 9, 15)));
      expect(newDaily.endDate, equals(DateTime(2025, 10, 31)));
      expect(result.affectedMonths.single, equals(DateTime(2025, 9, 1)));
      expect(
        result.propagatedMonths,
        equals([DateTime(2025, 9), DateTime(2025, 10)]),
      );
    });

    test('soft deletes previous daily when the new range starts on the same day', () {
      final monthlyIncome = MonthlyIncome.newForMonths(
        id: 'inc-001',
        yearMonthList: [DateTime(2025, 9)],
        entries: [
          Entry(
            idx: 0,
            amount: 1500000.0,
            category: 'Salary',
            type: EntryType.fixed,
          ),
        ],
      );
      final monthlyConsume = MonthlyConsume.newForMonths(
        id: 'con-001',
        yearMonthList: [DateTime(2025, 9)],
        entries: [
          Entry(
            idx: 0,
            amount: 500000.0,
            category: 'Rent',
            type: EntryType.fixed,
          ),
        ],
      );
      final daily = DailyConsume.newRange(
        id: 'day-202509-001',
        startDate: DateTime(2025, 9, 15),
        endDate: DateTime(2025, 9, 30),
        entries: [
          Entry(
            idx: 0,
            amount: 20000.0,
            category: 'Baseline',
            type: EntryType.daily,
          ),
        ],
      );

      final mini = _buildMini(
        docId: '202509-001',
        month: DateTime(2025, 9),
        start: DateTime(2025, 9, 15),
        end: DateTime(2025, 9, 30),
        dailyId: daily.id,
      );
      final totalPlan = _buildTotalPlan(subPlans: {'202509': _buildSubPlan('202509', mini)});

      final repository = PlanMutationRepository();
      final result = repository.applyDaily(
        totalPlan: totalPlan,
        monthlyIncomes: {monthlyIncome.id: monthlyIncome},
        monthlyConsumes: {monthlyConsume.id: monthlyConsume},
        dailyConsumes: {daily.id: daily},
        command: UpdateDailyCommand(
          applyDate: DateTime(2025, 9, 15),
          modEndDate: DateTime(2025, 9, 30),
          entries: [
            Entry(
              idx: 1,
              amount: 18000.0,
              category: 'Revised',
              type: EntryType.daily,
            ),
          ],
          newDailyId: 'day-202509-002',
          newMiniDocId: '202509-002',
          previousDailyId: daily.id,
        ),
      );

      final previous = result.dailyConsumes[daily.id]!;
      expect(previous.isActive, isFalse);
      expect(previous.endedAt, equals(DateTime(2025, 9, 14)));

      final updatedSubPlan = result.totalPlan.subPlans['202509']!;
      final updatedMini = updatedSubPlan.miniPlans['202509-001']!;
      expect(updatedMini.dailyConsumeId, equals('day-202509-002'));
      expect(updatedMini.startDate, equals(DateTime(2025, 9, 15)));
    });
  });
}

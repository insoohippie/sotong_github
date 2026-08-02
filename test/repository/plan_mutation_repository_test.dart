import 'package:flutter_test/flutter_test.dart';
import 'package:sotong/model/commands/update_daily_command.dart';
import 'package:sotong/model/plan/mini_plan.dart';
import 'package:sotong/model/plan/plan_metrics.dart';
import 'package:sotong/model/plan/sub_plan.dart';
import 'package:sotong/model/plan/total_plan.dart';
import 'package:sotong/model/refData/daily_consume.dart';
import 'package:sotong/model/refData/entry.dart';
import 'package:sotong/model/refData/monthly_consume.dart';
import 'package:sotong/model/refData/monthly_income.dart';
import 'package:sotong/repository/plan_mutation_repository.dart';

Entry _entry({
  required int idx,
  required double amount,
  required String category,
  required EntryType type,
}) {
  return Entry(
    idx: idx,
    order: idx,
    amount: amount,
    categoryKey: category,
    category: category,
    emoji: '💰',
    type: type,
  );
}

MiniPlan _buildMini({
  required String docId,
  required DateTime month,
  required DateTime start,
  required DateTime end,
  required String dailyId,
  String? prevDocId,
  String? nextDocId,
}) {
  return MiniPlan(
    docId: docId,
    yearMonth: DateTime(month.year, month.month),
    startDate: start,
    endDate: end,
    monthlyIncomeId: 'inc-001',
    monthlyConsumeId: 'con-001',
    dailyConsumeId: dailyId,
    prevDocId: prevDocId,
    nextDocId: nextDocId,
  );
}

SubPlan _buildSubPlan(List<MiniPlan> minis) {
  final head = minis.first;
  return SubPlan(
    yearMonth: DateTime(head.yearMonth.year, head.yearMonth.month),
    headDocId: head.docId,
    miniPlans: {for (final mini in minis) mini.docId: mini},
    miniResult: MiniPlanResult(
      headDocId: head.docId,
      miniMetrics: const [],
      miniPlanHead: head,
    ),
  );
}

TotalPlan _buildTotalPlan({
  required Map<String, SubPlan> subPlans,
}) {
  final metrics = PlanMetrics.fromRange(
    startDate: DateTime(2025, 9, 1),
    endDate: DateTime(2025, 10, 31),
    monthlyIncomeAmount: 0,
    monthlyConsumeAmount: 0,
    dailyConsumeAmount: 0,
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
      subResult: SubPlanResult(
        subMetrics: const [],
        subPlanList: subPlans.values.toList(),
      ),
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
          _entry(idx: 0, amount: 1500000.0, category: 'Salary', type: EntryType.fixed),
        ],
      );
      final monthlyConsume = MonthlyConsume.newForMonths(
        id: 'con-001',
        yearMonthList: [DateTime(2025, 9), DateTime(2025, 10)],
        entries: [
          _entry(idx: 0, amount: 500000.0, category: 'Rent', type: EntryType.fixed),
        ],
      );
      final baseDaily = DailyConsume.newRange(
        id: 'day-202509-001',
        startDate: DateTime(2025, 9, 1),
        endDate: DateTime(2025, 10, 31),
        entries: [
          _entry(idx: 0, amount: 20000.0, category: 'Baseline', type: EntryType.daily),
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
          '202509': _buildSubPlan([septemberMini]),
          '202510': _buildSubPlan([octoberMini]),
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
            _entry(idx: 1, amount: 25000.0, category: 'Updated Daily', type: EntryType.daily),
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
          _entry(idx: 0, amount: 1500000.0, category: 'Salary', type: EntryType.fixed),
        ],
      );
      final monthlyConsume = MonthlyConsume.newForMonths(
        id: 'con-001',
        yearMonthList: [DateTime(2025, 9)],
        entries: [
          _entry(idx: 0, amount: 500000.0, category: 'Rent', type: EntryType.fixed),
        ],
      );
      final daily = DailyConsume.newRange(
        id: 'day-202509-001',
        startDate: DateTime(2025, 9, 15),
        endDate: DateTime(2025, 9, 30),
        entries: [
          _entry(idx: 0, amount: 20000.0, category: 'Baseline', type: EntryType.daily),
        ],
      );

      final mini = _buildMini(
        docId: '202509-001',
        month: DateTime(2025, 9),
        start: DateTime(2025, 9, 15),
        end: DateTime(2025, 9, 30),
        dailyId: daily.id,
      );
      final totalPlan =
          _buildTotalPlan(subPlans: {'202509': _buildSubPlan([mini])});

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
            _entry(idx: 1, amount: 18000.0, category: 'Revised', type: EntryType.daily),
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

    test('truncating a multi-mini month drops trailing minis without breaking the chain', () {
      // 재현 조건: 종료일(modEndDate)이 미니 2개로 쪼개진 달의 중간에 떨어져,
      // 뒤쪽 미니가 통째로 잘려나가는 경우.
      // 수정 전에는 copyWith(nextDocId: null)이 무시되어 잘려나간 미니를 가리키는
      // 포인터가 남았고, orderedMinis()가 'Broken mini plan chain' StateError를 던졌다.
      final monthlyIncome = MonthlyIncome.newForMonths(
        id: 'inc-001',
        yearMonthList: [DateTime(2025, 9), DateTime(2025, 10)],
        entries: [
          _entry(idx: 0, amount: 1500000.0, category: 'Salary', type: EntryType.fixed),
        ],
      );
      final monthlyConsume = MonthlyConsume.newForMonths(
        id: 'con-001',
        yearMonthList: [DateTime(2025, 9), DateTime(2025, 10)],
        entries: [
          _entry(idx: 0, amount: 500000.0, category: 'Rent', type: EntryType.fixed),
        ],
      );
      final baseDaily = DailyConsume.newRange(
        id: 'day-202509-001',
        startDate: DateTime(2025, 9, 1),
        endDate: DateTime(2025, 10, 15),
        entries: [
          _entry(idx: 0, amount: 20000.0, category: 'Baseline', type: EntryType.daily),
        ],
      );
      final octDaily = DailyConsume.newRange(
        id: 'day-202510-001',
        startDate: DateTime(2025, 10, 16),
        endDate: DateTime(2025, 10, 31),
        entries: [
          _entry(idx: 0, amount: 30000.0, category: 'October', type: EntryType.daily),
        ],
      );

      final septemberMini = _buildMini(
        docId: '202509-001',
        month: DateTime(2025, 9),
        start: DateTime(2025, 9, 1),
        end: DateTime(2025, 9, 30),
        dailyId: baseDaily.id,
      );
      // 10월은 과거 플랜 수정으로 미니가 둘로 쪼개진 상태.
      final octoberFirst = _buildMini(
        docId: '202510-001',
        month: DateTime(2025, 10),
        start: DateTime(2025, 10, 1),
        end: DateTime(2025, 10, 15),
        dailyId: baseDaily.id,
        nextDocId: '202510-002',
      );
      final octoberSecond = _buildMini(
        docId: '202510-002',
        month: DateTime(2025, 10),
        start: DateTime(2025, 10, 16),
        end: DateTime(2025, 10, 31),
        dailyId: octDaily.id,
        prevDocId: '202510-001',
      );

      final totalPlan = _buildTotalPlan(
        subPlans: {
          '202509': _buildSubPlan([septemberMini]),
          '202510': _buildSubPlan([octoberFirst, octoberSecond]),
        },
      );

      final repository = PlanMutationRepository();
      // 하루소비한도 변경으로 목표 달성일이 10/10로 앞당겨진 상황.
      final result = repository.applyDaily(
        totalPlan: totalPlan,
        monthlyIncomes: {monthlyIncome.id: monthlyIncome},
        monthlyConsumes: {monthlyConsume.id: monthlyConsume},
        dailyConsumes: {baseDaily.id: baseDaily, octDaily.id: octDaily},
        command: UpdateDailyCommand(
          applyDate: DateTime(2025, 9, 10),
          modEndDate: DateTime(2025, 10, 10),
          entries: [
            _entry(idx: 1, amount: 15000.0, category: 'Tightened', type: EntryType.daily),
          ],
          newDailyId: 'day-202509-002',
          newMiniDocId: '202509-002',
          previousDailyId: baseDaily.id,
        ),
      );

      final updatedOct = result.totalPlan.subPlans['202510']!;
      final orderedMinis = updatedOct.orderedMinis();
      expect(orderedMinis, hasLength(1));
      expect(orderedMinis.single.docId, equals('202510-001'));
      expect(orderedMinis.single.endDate, equals(DateTime(2025, 10, 10)));
      expect(orderedMinis.single.nextDocId, isNull);
      expect(updatedOct.miniPlans.containsKey('202510-002'), isFalse);
      expect(result.totalPlan.modEndDate, equals(DateTime(2025, 10, 10)));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:sotong_local/model/plan/mini_plan.dart';
import 'package:sotong_local/model/plan/sub_plan.dart';
import 'package:sotong_local/model/plan/total_plan.dart';
import 'package:sotong_local/model/refData/daily_consume.dart';
import 'package:sotong_local/model/refData/entry.dart';
import 'package:sotong_local/model/refData/monthly_consume.dart';
import 'package:sotong_local/model/refData/monthly_income.dart';
import 'package:sotong_local/model/refData/ref_data.dart';
import 'package:sotong_local/view_model/plan/plan_edit_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanEditViewModel', () {
    late _PlanEditFixture fixture;
    late PlanEditViewModel viewModel;

    setUp(() {
      fixture = _PlanEditFixture.build();
      viewModel =
          PlanEditViewModel(fixture.plan, initialRefData: fixture.refData);
      viewModel.setOverrideToday(fixture.overrideToday);
    });

    test(
      'updates metrics when edits are applied and restores the original values',
      () {
        final initialMetrics = viewModel.totalPlan.result.totalMetrics;

        viewModel.applyFixedIncomeEdit(
          entries: [
            _entry(idx: 101, amount: 3_300_000),
          ],
        );
        expect(
          viewModel.totalPlan.result.totalMetrics.monthlyIncomeAmount,
          3_300_000,
        );

        viewModel.applyFixedConsumeEdit(
          entries: [
            _entry(idx: 102, amount: 900_000),
          ],
        );
        expect(
          viewModel.totalPlan.result.totalMetrics.monthlyConsumeAmount,
          900_000,
        );

        viewModel.applyDailyConsumeEdit(
          entries: [
            _entry(idx: 103, amount: 45_000, type: EntryType.daily),
          ],
        );
        expect(
          viewModel.totalPlan.result.totalMetrics.dailyConsumeAmount,
          45_000,
        );

        viewModel.applyFixedIncomeEdit(
          entries:
              fixture.baseMonthlyIncomeEntries.map((e) => e.copyWith()).toList(),
        );
        viewModel.applyFixedConsumeEdit(
          entries: fixture.baseMonthlyConsumeEntries
              .map((e) => e.copyWith())
              .toList(),
        );
        viewModel.applyDailyConsumeEdit(
          entries:
              fixture.baseDailyConsumeEntries.map((e) => e.copyWith()).toList(),
        );

        final restored = viewModel.totalPlan.result.totalMetrics;
        expect(restored.monthlyIncomeAmount, initialMetrics.monthlyIncomeAmount);
        expect(
          restored.monthlyConsumeAmount,
          initialMetrics.monthlyConsumeAmount,
        );
        expect(restored.dailyConsumeAmount, initialMetrics.dailyConsumeAmount);
      },
    );

    test('finalizeEdits composes pending commands with earliest apply date', () {
      viewModel.applyFixedIncomeEdit(
        entries: [
          _entry(idx: 201, amount: 3_200_000),
        ],
      );
      viewModel.applyDailyConsumeEdit(
        entries: [
          _entry(idx: 202, amount: 50_000, type: EntryType.daily),
        ],
      );

      final result = viewModel.finalizeEdits();
      expect(result.applyDate, fixture.overrideToday);
      expect(result.monthlyCommands, hasLength(1));
      expect(result.dailyCommands, hasLength(1));

      final incomeCommand = result.monthlyCommands.single;
      expect(incomeCommand.isIncome, isTrue);
      expect(incomeCommand.applyMonth, fixture.monthStart);
      expect(incomeCommand.entries.single.amount, 3_200_000);

      final dailyCommand = result.dailyCommands.single;
      expect(dailyCommand.applyDate, fixture.overrideToday);
      expect(dailyCommand.entries.single.amount, 50_000);
      expect(dailyCommand.modEndDate, fixture.plan.modEndDate);

      final followUp = viewModel.finalizeEdits();
      expect(followUp.monthlyCommands, isEmpty);
      expect(followUp.dailyCommands, isEmpty);
    });

    test('remaining target excludes savings before apply date', () {
      final monthKey = _formatYearMonth(fixture.monthStart);
      final janMini = fixture.plan.subPlans[monthKey]!.orderedMinis().first;
      final janSaving = janMini.toMetrics().monthlyNetSaving;

      final jan1Target = viewModel.debugRemainingTargetFor(
        DateTime(fixture.monthStart.year, fixture.monthStart.month, 1),
      );
      expect(jan1Target, fixture.plan.targetAmount);

      final feb1Target = viewModel.debugRemainingTargetFor(
        DateTime(fixture.monthStart.year, fixture.monthStart.month + 1, 1),
      );
      expect(feb1Target, fixture.plan.targetAmount! - janSaving);
    });

  });
}

class _PlanEditFixture {
  _PlanEditFixture({
    required this.plan,
    required this.refData,
    required this.baseMonthlyIncomeEntries,
    required this.baseMonthlyConsumeEntries,
    required this.baseDailyConsumeEntries,
    required this.monthStart,
    required this.overrideToday,
  });

  final TotalPlan plan;
  final RefData refData;
  final List<Entry> baseMonthlyIncomeEntries;
  final List<Entry> baseMonthlyConsumeEntries;
  final List<Entry> baseDailyConsumeEntries;
  final DateTime monthStart;
  final DateTime overrideToday;

  static _PlanEditFixture build() {
    final planStart = DateTime(2024, 1, 1);
    final monthStart = DateTime(planStart.year, planStart.month, 1);
    final monthEnd = DateTime(planStart.year, planStart.month + 1, 0);
    final monthKey = _formatYearMonth(monthStart);
    final overrideToday = DateTime(2024, 1, 15);

    final monthlyIncomeEntries = [
      _entry(idx: 1, amount: 3_000_000),
    ];
    final monthlyConsumeEntries = [
      _entry(idx: 2, amount: 800_000),
    ];
    final dailyConsumeEntries = [
      _entry(idx: 3, amount: 40_000, type: EntryType.daily),
    ];

    final monthlyIncome = MonthlyIncome.newForMonths(
      id: '${monthKey}-INC-001',
      yearMonthList: [monthStart],
      entries: monthlyIncomeEntries,
    );
    final monthlyConsume = MonthlyConsume.newForMonths(
      id: '${monthKey}-EXP-001',
      yearMonthList: [monthStart],
      entries: monthlyConsumeEntries,
    );
    final dailyConsume = DailyConsume.newRange(
      id: '${monthKey}-DAY-001',
      startDate: monthStart,
      endDate: monthEnd,
      entries: dailyConsumeEntries,
    );

    final mini = MiniPlan(
      docId: '${monthKey}_mini_head',
      yearMonth: monthStart,
      startDate: monthStart,
      endDate: monthEnd,
      monthlyIncomeId: monthlyIncome.id,
      monthlyConsumeId: monthlyConsume.id,
      dailyConsumeId: dailyConsume.id,
      monthlyIncomeAmount:
          _sumEntryAmounts(monthlyIncomeEntries).round(),
      monthlyConsumeAmount:
          _sumEntryAmounts(monthlyConsumeEntries).round(),
      dailyConsumeAmount:
          _sumEntryAmounts(dailyConsumeEntries).round(),
    ).recalculateNetAmounts();

    final subPlan = SubPlan(
      yearMonth: monthStart,
      headDocId: mini.docId,
      miniPlans: {mini.docId: mini},
      miniResult: MiniPlanResult(
        headDocId: mini.docId,
        miniMetrics: [mini.toMetrics()],
        miniPlanHead: mini,
      ),
    );

    final monthlyMetrics = subPlan.monthlySummary();
    final plan = TotalPlan(
      planId: 'plan-edit-test',
      planName: '테스트 플랜',
      targetAmount: 10_000_000,
      currentAmount: 0,
      currentAsset: 0,
      startDate: planStart,
      endDate: monthEnd,
      modEndDate: monthEnd,
      creationDate: planStart,
      autoService: false,
      subPlans: {monthKey: subPlan},
      result: TotalResult(
        totalMetrics: monthlyMetrics,
        subResult: SubPlanResult(
          subMetrics: [monthlyMetrics],
          subPlanList: [subPlan],
        ),
      ),
      extraIncomeTotal: 0,
      snapshotAmount: 0,
      snapshotAt: planStart,
    );

    final refData = RefData(
      planId: plan.planId,
      monthlyIncomes: {monthlyIncome.id: monthlyIncome},
      monthlyConsumes: {monthlyConsume.id: monthlyConsume},
      dailyConsumes: {dailyConsume.id: dailyConsume},
    );

    return _PlanEditFixture(
      plan: plan,
      refData: refData,
      baseMonthlyIncomeEntries:
          monthlyIncomeEntries.map((e) => e.copyWith()).toList(),
      baseMonthlyConsumeEntries:
          monthlyConsumeEntries.map((e) => e.copyWith()).toList(),
      baseDailyConsumeEntries:
          dailyConsumeEntries.map((e) => e.copyWith()).toList(),
      monthStart: monthStart,
      overrideToday: overrideToday,
    );
  }
}

Entry _entry({
  required int idx,
  required double amount,
  EntryType type = EntryType.fixed,
  String? category,
}) {
  return Entry(
    idx: idx,
    amount: amount,
    category: category ?? '분류$idx',
    type: type,
  );
}

double _sumEntryAmounts(Iterable<Entry> entries) =>
    entries.fold<double>(0, (sum, e) => sum + e.amount);

String _formatYearMonth(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}${value.month.toString().padLeft(2, '0')}';

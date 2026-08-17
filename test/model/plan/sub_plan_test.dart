import 'package:flutter_test/flutter_test.dart';
import 'package:sotong/model/plan/mini_plan.dart';
import 'package:sotong/model/plan/sub_plan.dart';

/// 월수입 1,000,000 / 월지출 300,000 / 하루한도 15,000 기준.
/// 하루 페이스 = (1,000,000 − 300,000 − 15,000×그달일수) ÷ 그달일수
MiniPlan _mini({
  required String docId,
  required DateTime month,
  required DateTime start,
  required DateTime end,
  String? prevDocId,
  String? nextDocId,
}) {
  return MiniPlan(
    docId: docId,
    yearMonth: DateTime(month.year, month.month),
    startDate: start,
    endDate: end,
    monthlyIncomeId: 'inc',
    monthlyConsumeId: 'con',
    dailyConsumeId: 'day',
    prevDocId: prevDocId,
    nextDocId: nextDocId,
    monthlyIncomeAmount: 1000000,
    monthlyConsumeAmount: 300000,
    dailyConsumeAmount: 15000,
  ).recalculateNetAmounts();
}

SubPlan _subPlan(List<MiniPlan> minis) {
  final head = minis.first;
  return SubPlan(
    yearMonth: DateTime(head.yearMonth.year, head.yearMonth.month),
    headDocId: head.docId,
    miniPlans: {for (final m in minis) m.docId: m},
    miniResult: MiniPlanResult(
      headDocId: head.docId,
      miniMetrics: const [],
      miniPlanHead: head,
    ),
  );
}

void main() {
  group('SubPlan.monthlySummary 기간은 미니 실제 구간이어야 한다', () {
    test('하루짜리 미니 달: kDays=1, dailyNetSaving = 하루 페이스', () {
      // 2029-08은 31일 → 하루 페이스 = (1,000,000 − 300,000 − 465,000) / 31 ≈ 7,581
      final sub = _subPlan([
        _mini(
          docId: 'm1',
          month: DateTime(2029, 8),
          start: DateTime(2029, 8, 1),
          end: DateTime(2029, 8, 1),
        ),
      ]);
      final summary = sub.monthlySummary();

      expect(summary.startDate, DateTime(2029, 8, 1));
      expect(summary.endDate, DateTime(2029, 8, 1));
      expect(summary.kDays, 1);
      // 수정 전에는 kDays=31로 나뉘어 ≈245가 나왔다.
      expect(summary.dailyNetSaving, closeTo(7581, 1));
    });

    test('2일 시작 달: kDays=30, dailyNetSaving = 하루 페이스', () {
      // 2026-08(31일), 8/2~8/31 = 30일
      final sub = _subPlan([
        _mini(
          docId: 'm1',
          month: DateTime(2026, 8),
          start: DateTime(2026, 8, 2),
          end: DateTime(2026, 8, 31),
        ),
      ]);
      final summary = sub.monthlySummary();

      expect(summary.startDate, DateTime(2026, 8, 2));
      expect(summary.endDate, DateTime(2026, 8, 31));
      expect(summary.kDays, 30);
      expect(summary.dailyNetSaving, closeTo(7581, 1));
    });

    test('꽉 찬 달: 기존과 동일하게 kDays=그달일수', () {
      final sub = _subPlan([
        _mini(
          docId: 'm1',
          month: DateTime(2026, 9),
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
      ]);
      final summary = sub.monthlySummary();

      expect(summary.kDays, 30);
      // 30일 달 하루 페이스 = (1,000,000 − 300,000 − 450,000) / 30 ≈ 8,333
      expect(summary.dailyNetSaving, closeTo(8333, 1));
    });

    test('미니 2개로 쪼개진 달: 첫 미니 시작~마지막 미니 끝', () {
      final sub = _subPlan([
        _mini(
          docId: 'a',
          month: DateTime(2026, 10),
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 15),
          nextDocId: 'b',
        ),
        _mini(
          docId: 'b',
          month: DateTime(2026, 10),
          start: DateTime(2026, 10, 16),
          end: DateTime(2026, 10, 31),
          prevDocId: 'a',
        ),
      ]);
      final summary = sub.monthlySummary();

      expect(summary.startDate, DateTime(2026, 10, 1));
      expect(summary.endDate, DateTime(2026, 10, 31));
      expect(summary.kDays, 31);
    });
  });
}

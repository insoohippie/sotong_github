import 'package:flutter_test/flutter_test.dart';
import 'package:sotong_local/model/refData/daily_consume.dart';
import 'package:sotong_local/model/refData/entry.dart';
import 'package:sotong_local/model/refData/monthly_income.dart';
import 'package:sotong_local/model/refData/ref_data.dart';

void main() {
  group('RefData.addMonthlyIncome', () {
    test('removes overlapping months from previous income while keeping the rest active', () {
      final originalIncome = MonthlyIncome.newForMonths(
        id: 'plan_202508-001',
        yearMonthList: [
          DateTime(2025, 8),
          DateTime(2025, 9),
          DateTime(2025, 10),
        ],
        entries: [
          Entry(
            idx: 0,
            amount: 1500000,
            category: 'Salary',
            type: EntryType.fixed,
          ),
        ],
      );

      final refData = RefData(
        planId: 'plan',
        monthlyIncomes: {
          originalIncome.id: originalIncome,
        },
      );
      refData.setReferenceDate(DateTime(2025, 9, 1));

      final newIncome = refData.addMonthlyIncome(
        applyMonth: DateTime(2025, 9),
        modEndMonth: DateTime(2025, 10),
        entries: [
          Entry(
            idx: 1,
            amount: 1600000.0,
            category: 'Salary',
            type: EntryType.fixed,
          ),
        ],
      );

      expect(newIncome.yearMonthList, equals([DateTime(2025, 9), DateTime(2025, 10)]));
      final truncated = refData.monthlyIncomeMap['plan_202508-001']!;
      expect(truncated.yearMonthList, equals([DateTime(2025, 8)]));
      expect(truncated.isActive, isTrue);
      expect(refData.primaryMonthlyIncomeId, equals(newIncome.id));
    });
  });

  group('RefData.addDailyConsume', () {
    test('truncates overlapping range and soft deletes identical start overlaps', () {
      final baseline = DailyConsume.newRange(
        id: 'plan_202508-001',
        startDate: DateTime(2025, 9, 1),
        endDate: DateTime(2025, 10, 31),
        entries: [
          Entry(
            idx: 0,
            amount: 30000.0,
            category: 'Baseline',
            type: EntryType.daily,
          ),
        ],
      );

      final refData = RefData(
        planId: 'plan',
        dailyConsumes: {
          baseline.id: baseline,
        },
      );
      refData.setReferenceDate(DateTime(2025, 9, 1));

      final first = refData.addDailyConsume(
        applyDate: DateTime(2025, 9, 15),
        modEndDate: DateTime(2025, 10, 31),
        entries: [
          Entry(
            idx: 1,
            amount: 25000.0,
            category: 'Adjusted',
            type: EntryType.daily,
          ),
        ],
      );

      final truncatedBaseline = refData.dailyConsumeMap['plan_202508-001']!;
      expect(truncatedBaseline.endDate, equals(DateTime(2025, 9, 14)));
      expect(truncatedBaseline.isActive, isTrue);

      final second = refData.addDailyConsume(
        applyDate: DateTime(2025, 9, 15),
        modEndDate: DateTime(2025, 10, 31),
        entries: [
          Entry(
            idx: 2,
            amount: 22000.0,
            category: 'Revised',
            type: EntryType.daily,
          ),
        ],
      );

      final firstRecord = refData.dailyConsumeMap[first.id]!;
      expect(firstRecord.isActive, isFalse);
      expect(firstRecord.endedAt, equals(DateTime(2025, 9, 14)));
      expect(second.startDate, equals(DateTime(2025, 9, 15)));
      expect(refData.primaryDailyConsumeId, equals(second.id));
    });
  });
}

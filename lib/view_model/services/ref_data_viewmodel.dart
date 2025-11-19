import '../../model/refData/daily_consume.dart';
import '../../model/refData/entry.dart';
import '../../model/refData/monthly_consume.dart';
import '../../model/refData/monthly_income.dart';
import '../../model/refData/ref_data.dart';

/// Convenience helper around [RefData] for appending new income/consume entries.
class RefDataViewModel {
  RefDataViewModel(this.refData);

  final RefData refData;

  MonthlyIncome appendMonthlyIncome({
    required DateTime applyDate,
    required DateTime modEndDate,
    required List<Entry> entries,
  }) {
    final applyMonth = DateTime(applyDate.year, applyDate.month, 1);
    final modEndMonth = DateTime(modEndDate.year, modEndDate.month, 1);
    return refData.addMonthlyIncome(
      applyMonth: applyMonth,
      modEndMonth: modEndMonth,
      entries: entries,
    );
  }

  MonthlyConsume appendMonthlyConsume({
    required DateTime applyDate,
    required DateTime modEndDate,
    required List<Entry> entries,
  }) {
    final applyMonth = DateTime(applyDate.year, applyDate.month, 1);
    final modEndMonth = DateTime(modEndDate.year, modEndDate.month, 1);
    return refData.addMonthlyConsume(
      applyMonth: applyMonth,
      modEndMonth: modEndMonth,
      entries: entries,
    );
  }

  DailyConsume appendDailyConsume({
    required DateTime applyDate,
    required DateTime modEndDate,
    required List<Entry> entries,
  }) {
    return refData.addDailyConsume(
      applyDate: DateTime(applyDate.year, applyDate.month, applyDate.day),
      modEndDate: DateTime(modEndDate.year, modEndDate.month, modEndDate.day),
      entries: entries,
    );
  }

  Map<String, dynamic> toMap() => refData.toMap();

  List<Entry> get latestMonthlyIncomeEntries =>
      refData.primaryMonthlyIncomeEntries;
  List<Entry> get latestMonthlyConsumeEntries =>
      refData.primaryMonthlyConsumeEntries;
  List<Entry> get latestDailyConsumeEntries =>
      refData.primaryDailyConsumeEntries;

  double get latestMonthlyIncomeSum => refData.primaryMonthlyIncomeSum;
  double get latestMonthlyConsumeSum => refData.primaryMonthlyConsumeSum;
  double get latestDailyConsumeSum => refData.primaryDailyConsumeSum;
}

import 'package:intl/intl.dart';

import '../model/plan/mini_plan.dart';
import '../model/plan/sub_plan.dart';
import '../model/plan/total_plan.dart';
import '../model/refData/daily_consume.dart';
import '../model/refData/monthly_consume.dart';
import '../model/refData/monthly_income.dart';
import '../model/refData/ref_data.dart';

/// Utility that renders the current TotalPlan/SubPlan/MiniPlan linkage in a readable tree.
class PlanDebugPrinter {
  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  static String describe({
    required TotalPlan plan,
    required RefData refData,
  }) {
    final buffer = StringBuffer()
      ..writeln('TotalPlan(${plan.planId.isEmpty ? '-' : plan.planId})')
      ..writeln('  name=${plan.planName ?? '-'} '
          'target=${plan.targetAmount ?? 0} '
          'current=${plan.currentAsset}')
      ..writeln('  start=${_formatDate(plan.startDate)} '
          'end=${_formatDate(plan.endDate)} '
          'modEnd=${_formatDate(plan.modEndDate)}');

    final totalMetrics = plan.result.totalMetrics;
    buffer
      ..writeln(
        '  amount: '
            'monthlyIncomeAmount=${totalMetrics.monthlyIncomeAmount} '
            'monthlyConsumeAmount=${totalMetrics.monthlyConsumeAmount} '
            'dailyConsumeAmount=${totalMetrics.dailyConsumeAmount}',
      )
      ..writeln(
        '  net: '
            'monthlyNetIncome=${totalMetrics.monthlyNetIncome} '
            'monthlyNetConsume=${totalMetrics.monthlyNetConsume} '
            'dailyNetConsume=${totalMetrics.dailyNetConsume}',
      );

    final subEntries = plan.subPlans.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (subEntries.isEmpty) {
      buffer.writeln('  └─ (no sub plans)');
    } else {
      for (var i = 0; i < subEntries.length; i++) {
        final entry = subEntries[i];
        final isLast = i == subEntries.length - 1;
        _appendSubPlan(
          buffer,
          key: entry.key,
          subPlan: entry.value,
          refData: refData,
          indent: '  ',
          isLast: isLast,
        );
      }
    }

    return buffer.toString();
  }

  static void _appendSubPlan(
    StringBuffer buffer, {
    required String key,
    required SubPlan subPlan,
    required RefData refData,
    required String indent,
    required bool isLast,
  }) {
    final branch = isLast ? '└─' : '├─';
    final childIndent = indent + (isLast ? '   ' : '│  ');
    final summaryMetrics = subPlan.monthlySummary();
    buffer.writeln(
      '$indent$branch SubPlan $key '
      '(month=${_dateFmt.format(subPlan.yearMonth)}, head=${subPlan.headDocId})',
    );
    buffer.writeln(
      '$childIndent summary: minis=${subPlan.miniPlans.length} '
          'dailyNet=${summaryMetrics.dailyNetSaving} '
          'fractional=${subPlan.fractionalEndSeconds}',
    );
    buffer.writeln(
      '$childIndent    amount: '
          'monthlyIncomeAmount=${summaryMetrics.monthlyIncomeAmount} '
          'monthlyConsumeAmount=${summaryMetrics.monthlyConsumeAmount} '
          'dailyConsumeAmount=${summaryMetrics.dailyConsumeAmount}',
    );
    buffer.writeln(
      '$childIndent    net: '
          'monthlyNetIncome=${summaryMetrics.monthlyNetIncome} '
          'monthlyNetConsume=${summaryMetrics.monthlyNetConsume} '
          'dailyNetConsume=${summaryMetrics.dailyNetConsume}',
    );

    final miniList = subPlan.orderedMinis();
    if (miniList.isEmpty) {
      buffer.writeln('$childIndent└─ (no mini plans)');
      return;
    }

    for (var i = 0; i < miniList.length; i++) {
      final mini = miniList[i];
      final miniLast = i == miniList.length - 1;
      final miniBranch = miniLast ? '└─' : '├─';
      final nextIndent = childIndent + (miniLast ? '   ' : '│  ');

      buffer.writeln(
        '$childIndent$miniBranch Mini ${mini.docId} '
        '${_dateFmt.format(mini.startDate)}~${_dateFmt.format(mini.endDate)}',
      );

      final income = refData.monthlyIncomeById(mini.monthlyIncomeId);
      final consume = refData.monthlyConsumeById(mini.monthlyConsumeId);
      final daily = refData.dailyConsumeById(mini.dailyConsumeId);

      buffer.writeln(
        '$nextIndent income=${income?.id ?? mini.monthlyIncomeId} '
        'consume=${consume?.id ?? mini.monthlyConsumeId} '
        'daily=${daily?.id ?? mini.dailyConsumeId}',
      );
      buffer.writeln(
        '$nextIndent cached: '
        'monthlyIncome=${mini.monthlyIncomeAmount} '
        'monthlyConsume=${mini.monthlyConsumeAmount} '
        'dailyConsume=${mini.dailyConsumeAmount} '
      );
      buffer.writeln(
        '$nextIndent    net: '
        'monthlyNetIncome=${mini.monthlyNetIncome} '
        'monthlyNetConsume=${mini.monthlyNetConsume} '
        'dailyNetConsume=${mini.dailyNetConsume}',
      );
    }
  }

  static String _formatDate(DateTime? value) =>
      value != null ? _dateFmt.format(value) : '-';
}

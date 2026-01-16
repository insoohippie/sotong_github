import 'package:meta/meta.dart';

import '../refData/entry.dart';

/// Describe a monthly income/consume update spanning multiple months.

@immutable
class UpdateMonthlyCommand {
  UpdateMonthlyCommand({
    required this.applyMonth,
    required this.modEndMonth,
    required this.entries,
    required this.newDocumentId,
    this.previousDocumentId,
    this.isIncome = true,
  }) : assert(!applyMonth.isAfter(modEndMonth),
            'applyMonth must be <= modEndMonth');

  final DateTime applyMonth;
  final DateTime modEndMonth;
  final List<Entry> entries;
  final String newDocumentId;
  final String? previousDocumentId;
  final bool isIncome;

  List<DateTime> affectedMonths() {
    final months = <DateTime>[];
    var cursor = DateTime(applyMonth.year, applyMonth.month);
    final end = DateTime(modEndMonth.year, modEndMonth.month);
    while (!cursor.isAfter(end)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }
}

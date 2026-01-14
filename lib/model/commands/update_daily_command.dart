import 'package:meta/meta.dart';

import '../refData/entry.dart';

/// Describe a daily spend update with an optional prior record to truncate.

@immutable
class UpdateDailyCommand {
  UpdateDailyCommand({
    required this.applyDate,
    required this.modEndDate,
    required this.entries,
    required this.newDailyId,
    required this.newMiniDocId,
    this.previousDailyId,
    this.allowBeforePlanStart = false,
  }) : assert(!applyDate.isAfter(modEndDate),
            'applyDate must be <= modEndDate');

  final DateTime applyDate;
  final DateTime modEndDate;
  final List<Entry> entries;
  final String newDailyId;
  final String newMiniDocId;
  final String? previousDailyId;
  final bool allowBeforePlanStart;

  DateTime get applyMonth => DateTime(applyDate.year, applyDate.month);

  List<DateTime> propagatedMonths() {
    final months = <DateTime>[];
    var cursor = DateTime(applyDate.year, applyDate.month);
    final end = DateTime(modEndDate.year, modEndDate.month);
    while (!cursor.isAfter(end)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }
}

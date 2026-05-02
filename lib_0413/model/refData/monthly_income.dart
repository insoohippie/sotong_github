import 'package:meta/meta.dart';

import 'entry.dart';

/// Monthly recurring income definition applied to one or more months.

@immutable
class MonthlyIncome {
  const MonthlyIncome({
    required this.id,
    required this.yearMonthList,
    required this.entries,
    required this.isActive,
  });

  final String id;
  final List<DateTime> yearMonthList;
  final List<Entry> entries;
  final bool isActive;

  factory MonthlyIncome.newForMonths({
    required String id,
    required List<DateTime> yearMonthList,
    required List<Entry> entries,
  }) {
    final normalizedMonths =
        yearMonthList.map(_normalizeMonth).toSet().toList()..sort();
    if (normalizedMonths.isEmpty) {
      throw ArgumentError('yearMonthList cannot be empty');
    }
    return MonthlyIncome(
      id: id,
      yearMonthList: List<DateTime>.unmodifiable(normalizedMonths),
      entries: List<Entry>.unmodifiable(entries),
      isActive: true,
    );
  }

  MonthlyIncome deactivate() {
    return copyWith(isActive: false);
  }

  MonthlyIncome removeMonths(Iterable<DateTime> months) {
    final removalSet = months.map(_normalizeMonth).toSet();
    final remaining = yearMonthList
        .where((element) => !removalSet.contains(element))
        .toList();
    if (remaining.isEmpty) {
      return copyWith(yearMonthList: remaining, isActive: false);
    }
    return copyWith(yearMonthList: remaining);
  }

  MonthlyIncome addMonths(Iterable<DateTime> months) {
    final next = <DateTime>{...yearMonthList};
    next.addAll(months.map(_normalizeMonth));
    return copyWith(
      yearMonthList: next.toList()..sort(),
      isActive: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entries': entries.map((e) => e.toMap()).toList(growable: false),
      'yearMonthList':
          yearMonthList.map((m) => m.toIso8601String()).toList(growable: false),
      'isActive': isActive,
    };
  }

  factory MonthlyIncome.fromMap(String id, Map<String, dynamic> map) {
    return MonthlyIncome(
      id: id,
      yearMonthList: ((map['yearMonthList'] as List<dynamic>? ?? [])
              .cast<String>()
              .map(DateTime.parse))
          .map(_normalizeMonth)
          .toList(growable: false),
      entries: ((map['entries'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>())
          .map(Entry.fromMap)
          .toList(growable: false),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  MonthlyIncome copyWith({
    List<DateTime>? yearMonthList,
    List<Entry>? entries,
    bool? isActive,
  }) {
    final normalizedMonths = yearMonthList?.map(_normalizeMonth).toList();
    return MonthlyIncome(
      id: id,
      yearMonthList:
          normalizedMonths != null ? List.unmodifiable(normalizedMonths) : this.yearMonthList,
      entries: entries != null ? List.unmodifiable(entries) : this.entries,
      isActive: isActive ?? this.isActive,
    );
  }

  static DateTime _normalizeMonth(DateTime value) =>
      DateTime(value.year, value.month);
}

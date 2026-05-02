import 'package:meta/meta.dart';

import 'entry.dart';

/// Represents a piecewise daily spend configuration applied over a date range.

@immutable
class DailyConsume {
  DailyConsume({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.entries,
    required this.isActive,
    this.endedAt,
  }) : assert(!startDate.isAfter(endDate), 'startDate must be <= endDate');

  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final List<Entry> entries;
  final bool isActive;
  final DateTime? endedAt;

  factory DailyConsume.newRange({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
    required List<Entry> entries,
  }) {
    final normalizedStart = _normalize(startDate);
    final normalizedEnd = _normalize(endDate);
    if (normalizedStart.isAfter(normalizedEnd)) {
      throw ArgumentError('startDate must not be after endDate');
    }
    final clonedEntries = List<Entry>.unmodifiable(entries);
    return DailyConsume(
      id: id,
      startDate: normalizedStart,
      endDate: normalizedEnd,
      entries: clonedEntries,
      isActive: true,
      endedAt: null,
    );
  }

  DailyConsume endAt(DateTime date) {
    final normalized = _normalize(date);
    if (normalized.isBefore(startDate)) {
      throw ArgumentError('end date cannot precede startDate');
    }
    if (normalized.isAfter(endDate)) {
      throw ArgumentError('end date cannot exceed current endDate');
    }
    return copyWith(endDate: normalized);
  }

  DailyConsume softDelete(DateTime endedAt) {
    return copyWith(
      isActive: false,
      endedAt: _normalize(endedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'entries': entries.map((e) => e.toMap()).toList(growable: false),
      'isActive': isActive,
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory DailyConsume.fromMap(String id, Map<String, dynamic> map) {
    return DailyConsume(
      id: id,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      entries: ((map['entries'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>())
          .map(Entry.fromMap)
          .toList(growable: false),
      isActive: map['isActive'] as bool? ?? true,
      endedAt: map['endedAt'] != null
          ? DateTime.parse(map['endedAt'] as String)
          : null,
    );
  }

  DailyConsume copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<Entry>? entries,
    bool? isActive,
    DateTime? endedAt,
  }) {
    final next = DailyConsume(
      id: id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      entries: entries ?? this.entries,
      isActive: isActive ?? this.isActive,
      endedAt: endedAt,
    );
    if (next.startDate.isAfter(next.endDate)) {
      throw ArgumentError('startDate must be <= endDate');
    }
    return next;
  }

  static DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool overlaps(DateTime rangeStart, DateTime rangeEnd) {
    final normalizedStart = _normalize(rangeStart);
    final normalizedEnd = _normalize(rangeEnd);
    if (normalizedStart.isAfter(normalizedEnd)) {
      throw ArgumentError('range start cannot be after range end');
    }
    return !(normalizedEnd.isBefore(startDate) ||
        normalizedStart.isAfter(endDate));
  }
}

extension _DateTimeEquality on DateTime {
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

// lib/model/record/monthly_record.dart

import 'day_record.dart';

class MonthlyRecord {
  final String monthKey; // 'yyyy-MM'
  final Map<String, DayRecord> days; // key: 'yyyy-MM-dd'

  const MonthlyRecord({
    required this.monthKey,
    required this.days,
  });

  factory MonthlyRecord.empty(String monthKey) {
    return MonthlyRecord(monthKey: monthKey, days: {});
  }

  factory MonthlyRecord.fromFirestore(
      String monthKey,
      Map<String, dynamic> data,
      ) {
    final raw = data['days'];

    final Map<String, dynamic> rawDays =
    raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};

    final days = <String, DayRecord>{};
    rawDays.forEach((dateKey, value) {
      if (value is Map) {
        days[dateKey] = DayRecord.fromFirestore(
          dateKey,
          Map<String, dynamic>.from(value as Map),
        );
      }
    });

    return MonthlyRecord(
      monthKey: monthKey,
      days: days,
    );
  }

  factory MonthlyRecord.fromJson(Map<String, dynamic> json) {
    final monthKey = json['month'] as String;

    final raw = json['days'];
    final Map<String, dynamic> rawDays =
    raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};

    final days = <String, DayRecord>{};
    rawDays.forEach((dateKey, value) {
      if (value is Map) {
        days[dateKey] = DayRecord.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
      }
    });

    return MonthlyRecord(
      monthKey: monthKey,
      days: days,
    );
  }

  Map<String, dynamic> toJson() {
    final daysJson = <String, dynamic>{};
    days.forEach((key, value) {
      daysJson[key] = value.toJson();
    });

    return {
      'month': monthKey,
      'days': daysJson,
    };
  }

  MonthlyRecord copyWith({
    Map<String, DayRecord>? days,
  }) {
    return MonthlyRecord(
      monthKey: monthKey,
      days: days ?? this.days,
    );
  }
}
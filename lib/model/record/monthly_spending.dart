import 'day_spending.dart';

class MonthlySpending {
  final String monthKey; // 'yyyy-MM'
  final Map<String, DaySpending> days; // key: 'yyyy-MM-dd'

  MonthlySpending({
    required this.monthKey,
    required this.days,
  });

  factory MonthlySpending.empty(String monthKey) {
    return MonthlySpending(monthKey: monthKey, days: {});
  }

  /// Firestore 문서 -> MonthlySpending
  factory MonthlySpending.fromFirestore(
      String monthKey,
      Map<String, dynamic> data,
      ) {
    final raw = data['days'];

    // 🔥 여기: as Map<String, dynamic> 대신 안전하게 변환
    final Map<String, dynamic> rawDays =
    raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};

    final days = <String, DaySpending>{};
    rawDays.forEach((dateKey, value) {
      if (value is Map) {
        days[dateKey] = DaySpending.fromFirestore(
          dateKey,
          Map<String, dynamic>.from(value as Map),
        );
      }
    });

    return MonthlySpending(
      monthKey: monthKey,
      days: days,
    );
  }

  /// Hive(JSON) -> MonthlySpending
  factory MonthlySpending.fromJson(Map<String, dynamic> json) {
    final monthKey = json['month'] as String;

    final raw = json['days'];
    final Map<String, dynamic> rawDays =
    raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};

    final days = <String, DaySpending>{};
    rawDays.forEach((dateKey, value) {
      if (value is Map) {
        days[dateKey] = DaySpending.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
      }
    });

    return MonthlySpending(
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

  MonthlySpending copyWith({
    Map<String, DaySpending>? days,
  }) {
    return MonthlySpending(
      monthKey: monthKey,
      days: days ?? this.days,
    );
  }
}

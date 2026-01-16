// lib/model/record/day_spending.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'spending_entry.dart';

class DaySpending {
  final DateTime date;
  final int? totalAmount;
  final String emotion;
  final String comment;
  final List<SpendingEntry> entries;

  DaySpending({
    required this.date,
    required this.totalAmount,
    required this.emotion,
    required this.comment,
    required this.entries,
  });

  factory DaySpending.fromFirestore(String dateKey, Map<String, dynamic> map) {
    final date = (map['date'] is Timestamp)
        ? (map['date'] as Timestamp).toDate()
        : DateTime.tryParse(dateKey) ?? DateTime.now();

    final rawEntries = (map['entries'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return DaySpending(
      date: date,
      totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
      emotion: map['emotion'] ?? '',
      comment: map['comment'] ?? '',
      entries: rawEntries.map((e) => SpendingEntry.fromMap(e)).toList(),
    );
  }

  factory DaySpending.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return DaySpending(
      date: DateTime.parse(json['date'] as String),
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      emotion: json['emotion'] ?? '',
      comment: json['comment'] ?? '',
      entries: rawEntries.map((e) => SpendingEntry.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'totalAmount': totalAmount,
    'emotion': emotion,
    'comment': comment,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  Map<String, dynamic> toMap() => toJson();

  DaySpending copyWith({
    DateTime? date,
    int? totalAmount,
    String? emotion,
    String? comment,
    List<SpendingEntry>? entries,
  }) {
    return DaySpending(
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      emotion: emotion ?? this.emotion,
      comment: comment ?? this.comment,
      entries: entries ?? this.entries,
    );
  }
}

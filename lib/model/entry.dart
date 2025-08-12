import 'package:cloud_firestore/cloud_firestore.dart';

enum EntryType { fixed, variable, daily, additional }

class Entry {
  // 7/14
  int idx;
  double amount;
  String category;
  String note;
  EntryType type;
  DateTime? dateTime;

  Entry({
    required this.idx,
    required this.amount,
    required this.category,
    this.note = '',
    required this.type,
    this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'idx': idx,
      'amount': amount,
      'category': category,
      'note': note,
      'type': type.name,
      'dateTime': dateTime != null ? Timestamp.fromDate(dateTime!) : null,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      idx: map['idx'] ?? 0,
      amount: map['amount'] ?? 0,
      category: map['category'] ?? '',
      note: map['note'] ?? '',
      type: EntryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EntryType.fixed,
      ),
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as Timestamp).toDate()
          : null,
    );
  }

  Entry copyWith({
    int? idx,
    double? amount,
    String? category,
    String? note,
    EntryType? type,
    DateTime? dateTime,
  }) {
    return Entry(
      idx: idx ?? this.idx,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}

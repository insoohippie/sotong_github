import 'package:cloud_firestore/cloud_firestore.dart';

enum EntryType { fixed, variable, daily, additional }

class Entry {
  int idx;
  double amount;

  /// 불변 ID (planMeta / refCategories 와 연결용)
  String categoryKey;

  /// 표시용 이름 (legacy / UI fallback)
  String category;

  String note;
  EntryType type;
  DateTime? dateTime;

  Entry({
    required this.idx,
    required this.amount,
    required this.categoryKey,
    required this.category,
    this.note = '',
    required this.type,
    this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'idx': idx,
      'amount': amount,
      'categoryKey': categoryKey,
      'category': category,
      'note': note,
      'type': type.name,
      'dateTime': dateTime != null ? Timestamp.fromDate(dateTime!) : null,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    final category = map['category'] ?? '';
    return Entry(
      idx: map['idx'] ?? 0,
      amount: (map['amount'] ?? 0).toDouble(),

      /// 없으면 category(name)로 fallback
      categoryKey: map['categoryKey'] ?? category,

      category: category,
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
    String? categoryKey,
    String? category,
    String? note,
    EntryType? type,
    DateTime? dateTime,
  }) {
    return Entry(
      idx: idx ?? this.idx,
      amount: amount ?? this.amount,
      categoryKey: categoryKey ?? this.categoryKey,
      category: category ?? this.category,
      note: note ?? this.note,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}
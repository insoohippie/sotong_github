import 'package:cloud_firestore/cloud_firestore.dart';

enum EntryType { fixed, variable, daily, additional }

class Entry {
  final int idx;            // legacy용
  final int order;          // 정렬용(0..n-1)
  final double amount;      // daily면 일일 예산
  final String categoryKey; // 불변 key
  final String category;    // display fallback
  final String emoji;       // display
  final String note;
  final EntryType type;
  final DateTime? dateTime;

  const Entry({
    required this.idx,
    required this.order,
    required this.amount,
    required this.categoryKey,
    required this.category,
    required this.emoji,
    this.note = '',
    required this.type,
    this.dateTime,
  });

  Map<String, dynamic> toMap() => {
    'idx': idx,
    'order': order,
    'amount': amount,
    'categoryKey': categoryKey,
    'category': category,
    'emoji': emoji,
    'note': note,
    'type': type.name,
    'dateTime': dateTime != null ? Timestamp.fromDate(dateTime!) : null,
  };

  factory Entry.fromMap(Map<String, dynamic> map) {
    final category = (map['category'] ?? '') as String;

    final rawKey = map['categoryKey'];
    final keyStr = rawKey is String ? rawKey : '';
    final safeKey = keyStr.isNotEmpty
        ? keyStr
        : (category.isNotEmpty ? category : 'unknown_${map['idx'] ?? 0}');

    final rawType = map['type'];
    final typeStr = rawType is String ? rawType : null;

    final rawEmoji = map['emoji'];
    final emojiStr = rawEmoji is String ? rawEmoji.trim() : '';
    final safeEmoji = emojiStr.isNotEmpty ? emojiStr : '💰';

    return Entry(
      idx: map['idx'] ?? 0,
      order: map['order'] ?? (map['idx'] ?? 0),
      amount: (map['amount'] ?? 0).toDouble(),
      categoryKey: safeKey,
      category: category,
      emoji: safeEmoji, // 없으면 '💰'만
      note: (map['note'] ?? '') as String,
      type: EntryType.values.firstWhere(
            (e) => e.name == typeStr,
        orElse: () => EntryType.fixed,
      ),
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as Timestamp).toDate()
          : null,
    );
  }

  Entry copyWith({
    int? idx,
    int? order,
    double? amount,
    String? categoryKey,
    String? category,
    String? emoji,
    String? note,
    EntryType? type,
    DateTime? dateTime,
  }) =>
      Entry(
        idx: idx ?? this.idx,
        order: order ?? this.order,
        amount: amount ?? this.amount,
        categoryKey: categoryKey ?? this.categoryKey,
        category: category ?? this.category,
        emoji: emoji ?? this.emoji,
        note: note ?? this.note,
        type: type ?? this.type,
        dateTime: dateTime ?? this.dateTime,
      );
}

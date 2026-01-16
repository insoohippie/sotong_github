// lib/model/record/spending_entry.dart

class SpendingEntry {
  final String id;
  final String category;
  final double amount;
  final String note;

  SpendingEntry({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
  });

  /// ✅ Firestore/Map 로딩 시 하위호환:
  /// - 예전 데이터에 id가 없으면 자동 생성(결정적 id)
  factory SpendingEntry.fromMap(Map<String, dynamic> map) {
    final category = map['category'] ?? '';
    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final note = map['note'] ?? '';

    // 기존 데이터(무id)도 깨지지 않게
    final rawId = map['id'] as String?;
    final fallbackId = _stableId(category: category, amount: amount, note: note);

    return SpendingEntry(
      id: (rawId == null || rawId.trim().isEmpty) ? fallbackId : rawId,
      category: category,
      amount: amount,
      note: note,
    );
  }

  factory SpendingEntry.fromJson(Map<String, dynamic> json) {
    final category = json['category'] ?? '';
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final note = json['note'] ?? '';

    final rawId = json['id'] as String?;
    final fallbackId = _stableId(category: category, amount: amount, note: note);

    return SpendingEntry(
      id: (rawId == null || rawId.trim().isEmpty) ? fallbackId : rawId,
      category: category,
      amount: amount,
      note: note,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'amount': amount,
    'note': note,
  };

  Map<String, dynamic> toJson() => toMap();

  SpendingEntry copyWith({
    String? id,
    String? category,
    double? amount,
    String? note,
  }) {
    return SpendingEntry(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }


  static String _stableId({
    required String category,
    required double amount,
    required String note,
  }) {
    final key = '$category|${amount.toStringAsFixed(2)}|$note';
    // 간단 해시(외부 패키지 없이)
    int hash = 0;
    for (final code in key.codeUnits) {
      hash = 0x1fffffff & (hash + code);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return 'legacy_$hash';
  }
}

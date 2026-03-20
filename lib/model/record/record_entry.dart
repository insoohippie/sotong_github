// lib/model/record/record_entry.dart

class RecordEntry {
  final String id;

  /// 불변 카테고리 키
  /// - PlanCategory / SnapshotItem / RefCategoryItem 의 categoryKey와 매칭
  /// - 예전 데이터에는 없을 수 있으므로 '' 허용
  final String categoryKey;

  /// 표시용 이름(legacy / UI용)
  final String category;

  final double amount;
  final String note;

  const RecordEntry({
    required this.id,
    required this.categoryKey,
    required this.category,
    required this.amount,
    required this.note,
  });

  factory RecordEntry.fromMap(Map<String, dynamic> map) {
    final category = map['category'] ?? '';
    final categoryKey = map['categoryKey'] ?? '';
    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final note = map['note'] ?? '';

    final rawId = map['id'] as String?;
    final fallbackId = _stableId(
      categoryKey: categoryKey is String ? categoryKey : '',
      category: category is String ? category : '',
      amount: amount,
      note: note is String ? note : '',
    );

    return RecordEntry(
      id: (rawId == null || rawId.trim().isEmpty) ? fallbackId : rawId,
      categoryKey: (categoryKey is String) ? categoryKey : '',
      category: (category is String) ? category : '',
      amount: amount,
      note: (note is String) ? note : '',
    );
  }

  factory RecordEntry.fromJson(Map<String, dynamic> json) {
    return RecordEntry.fromMap(json);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryKey': categoryKey,
    'category': category,
    'amount': amount,
    'note': note,
  };

  Map<String, dynamic> toJson() => toMap();

  RecordEntry copyWith({
    String? id,
    String? categoryKey,
    String? category,
    double? amount,
    String? note,
  }) {
    return RecordEntry(
      id: id ?? this.id,
      categoryKey: categoryKey ?? this.categoryKey,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  static String _stableId({
    required String categoryKey,
    required String category,
    required double amount,
    required String note,
  }) {
    final key = '$categoryKey|$category|${amount.toStringAsFixed(2)}|$note';

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
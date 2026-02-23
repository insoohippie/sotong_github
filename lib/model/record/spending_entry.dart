// lib/model/record/spending_entry.dart

class SpendingEntry {
  final String id;

  /// ✅ 신규: 불변 카테고리 키
  /// - PlanCategory / SnapshotItem 의 categoryKey와 매칭
  /// - 예전 데이터에는 없을 수 있음 => '' 허용 (fallback)
  final String categoryKey;

  /// 표시용 이름(legacy / UI용)
  final String category;

  final double amount;
  final String note;

  SpendingEntry({
    required this.id,
    required this.categoryKey,
    required this.category,
    required this.amount,
    required this.note,
  });

  /// ✅ Firestore/Map 로딩 시 하위호환:
  /// - categoryKey 없으면 '' (legacy)
  /// - id 없으면 자동 생성(결정적 id)
  factory SpendingEntry.fromMap(Map<String, dynamic> map) {
    final category = map['category'] ?? '';
    final categoryKey = map['categoryKey'] ?? ''; // ✅ 신규
    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final note = map['note'] ?? '';

    final rawId = map['id'] as String?;
    final fallbackId = _stableId(
      categoryKey: categoryKey,
      category: category,
      amount: amount,
      note: note,
    );

    return SpendingEntry(
      id: (rawId == null || rawId.trim().isEmpty) ? fallbackId : rawId,
      categoryKey: (categoryKey is String) ? categoryKey : '',
      category: category,
      amount: amount,
      note: note,
    );
  }

  factory SpendingEntry.fromJson(Map<String, dynamic> json) {
    final category = json['category'] ?? '';
    final categoryKey = json['categoryKey'] ?? '';
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final note = json['note'] ?? '';

    final rawId = json['id'] as String?;
    final fallbackId = _stableId(
      categoryKey: categoryKey,
      category: category,
      amount: amount,
      note: note,
    );

    return SpendingEntry(
      id: (rawId == null || rawId.trim().isEmpty) ? fallbackId : rawId,
      categoryKey: (categoryKey is String) ? categoryKey : '',
      category: category,
      amount: amount,
      note: note,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryKey': categoryKey, // ✅ 신규
    'category': category,
    'amount': amount,
    'note': note,
  };

  Map<String, dynamic> toJson() => toMap();

  SpendingEntry copyWith({
    String? id,
    String? categoryKey,
    String? category,
    double? amount,
    String? note,
  }) {
    return SpendingEntry(
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
    // ✅ categoryKey를 우선 포함 (이름이 바뀌어도 id 안정)
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
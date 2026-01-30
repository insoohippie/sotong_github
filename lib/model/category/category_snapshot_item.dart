import 'package:cloud_firestore/cloud_firestore.dart';

class CategorySnapshotItem {
  final String categoryId;   // categoryModel.id 와 동일하게(선택지 C)
  final String name;
  final String emoji;
  final int order;

  /// planCategories에서만 사용 (refCategories에서는 null)
  final int? dailyAmount;

  const CategorySnapshotItem({
    required this.categoryId,
    required this.name,
    required this.emoji,
    required this.order,
    this.dailyAmount,
  });

  factory CategorySnapshotItem.fromMap(Map<String, dynamic> map) {
    return CategorySnapshotItem(
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '💰',
      order: (map['order'] is int) ? map['order'] as int : 0,
      dailyAmount: (map['dailyAmount'] is int) ? map['dailyAmount'] as int : null,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'categoryId': categoryId,
      'name': name,
      'emoji': emoji,
      'order': order,
    };
    // refCategories는 dailyAmount 자체를 안 넣는 게 깔끔(=없음)
    if (dailyAmount != null) data['dailyAmount'] = dailyAmount;
    return data;
  }

  CategorySnapshotItem copyWith({
    String? categoryId,
    String? name,
    String? emoji,
    int? order,
    int? dailyAmount,
    bool clearDailyAmount = false,
  }) {
    return CategorySnapshotItem(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      order: order ?? this.order,
      dailyAmount: clearDailyAmount ? null : (dailyAmount ?? this.dailyAmount),
    );
  }
}

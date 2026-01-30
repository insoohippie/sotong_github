//즉시 반영 doc 모델

import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_meta_item.dart';

class CategoryRefPrefs {
  final List<CategoryMetaItem> refCategories;
  final DateTime? updatedAt;

  const CategoryRefPrefs({
    required this.refCategories,
    this.updatedAt,
  });

  factory CategoryRefPrefs.empty() => const CategoryRefPrefs(refCategories: []);

  factory CategoryRefPrefs.fromFirestore(Map<String, dynamic> map) {
    final items = (map['refCategories'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryMetaItem.fromMap)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return CategoryRefPrefs(
      refCategories: items,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'refCategories': refCategories.map((e) => e.toMap()).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

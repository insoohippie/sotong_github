// ref_category_item.dart
import 'package:meta/meta.dart';

@immutable
class RefCategoryItem {
  /// ✅ 불변 ID (A/B 통합 기준)
  final String categoryKey;

  /// 표시용
  final String name;
  final String emoji;

  /// 화면/저장 정렬
  final int order;

  /// 숨김 처리 옵션 (필요하면 유지)
  final bool hidden;

  const RefCategoryItem({
    required this.categoryKey,
    required this.name,
    required this.emoji,
    required this.order,
    this.hidden = false,
  });

  factory RefCategoryItem.fromMap(Map<String, dynamic> map) {
    return RefCategoryItem(
      categoryKey: (map['categoryKey'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      emoji: (map['emoji'] ?? '💰') as String,
      order: (map['order'] is int) ? map['order'] as int : 0,
      hidden: (map['hidden'] is bool) ? map['hidden'] as bool : false,
    );
  }

  Map<String, dynamic> toMap() => {
    'categoryKey': categoryKey,
    'name': name,
    'emoji': emoji,
    'order': order,
    'hidden': hidden,
  };

  RefCategoryItem copyWith({
    String? categoryKey,
    String? name,
    String? emoji,
    int? order,
    bool? hidden,
  }) {
    return RefCategoryItem(
      categoryKey: categoryKey ?? this.categoryKey,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
    );
  }
}

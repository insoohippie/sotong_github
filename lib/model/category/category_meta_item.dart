//저장용 메타
class CategoryMetaItem {
  final String categoryKey;     // 고정 ID
  final String name;            // displayName
  final String emoji;
  final int order;
  final bool hidden;

  const CategoryMetaItem({
    required this.categoryKey,
    required this.name,
    required this.emoji,
    required this.order,
    this.hidden = false,
  });

  factory CategoryMetaItem.fromMap(Map<String, dynamic> map) {
    return CategoryMetaItem(
      categoryKey: map['categoryKey'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '💰',
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

  CategoryMetaItem copyWith({
    String? categoryKey,
    String? name,
    String? emoji,
    int? order,
    bool? hidden,
  }) {
    return CategoryMetaItem(
      categoryKey: categoryKey ?? this.categoryKey,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
    );
  }
}

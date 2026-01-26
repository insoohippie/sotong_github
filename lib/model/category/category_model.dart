import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryType { plan, reference }

CategoryType categoryTypeFromString(String? v) {
  switch (v) {
    case 'plan':
      return CategoryType.plan;
    case 'reference':
    default:
      return CategoryType.reference;
  }
}

String categoryTypeToString(CategoryType t) {
  return t == CategoryType.plan ? 'plan' : 'reference';
}

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final String? color;

  /// A/B 구분
  final CategoryType type;

  /// plan(A)만 사용. reference(B)는 null 유지
  final int? dailyAmount;

  final bool archived;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.color,
    required this.type,
    required this.dailyAmount,
    required this.archived,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------- Firestore <-> Model ----------

  factory CategoryModel.fromFirestore(Map<String, dynamic> map) {
    final type = categoryTypeFromString(map['type'] as String?);
    final amountRaw = map['dailyAmount'];
    final amount = amountRaw is int ? amountRaw : null;

    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '💰',
      color: map['color'],
      type: type,
      dailyAmount: (type == CategoryType.plan) ? (amount ?? 0) : null,
      archived: map['archived'] ?? false,
      order: map['order'] is int ? map['order'] : 0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      "id": id,
      "name": name,
      "emoji": emoji,
      "color": color,
      "type": categoryTypeToString(type),
      "archived": archived,
      "order": order,
      "createdAt": Timestamp.fromDate(createdAt),
      "updatedAt": Timestamp.fromDate(updatedAt),
    };

    if (type == CategoryType.plan) {
      data["dailyAmount"] = dailyAmount; // plan일 때만 저장
    }

    return data;
  }

  // ---------- Hive(JSON) <-> Model ----------

  factory CategoryModel.fromJson(Map<String, dynamic> map) {
    final type = categoryTypeFromString(map['type'] as String?);
    final amountRaw = map['dailyAmount'];
    final amount = amountRaw is int ? amountRaw : null;

    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '💰',
      color: map['color'],
      type: type,
      dailyAmount: (type == CategoryType.plan) ? (amount ?? 0) : null,
      archived: map['archived'] ?? false,
      order: map['order'] is int ? map['order'] : 0,
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      "id": id,
      "name": name,
      "emoji": emoji,
      "color": color,
      "type": categoryTypeToString(type),
      "archived": archived,
      "order": order,
      "createdAt": createdAt.millisecondsSinceEpoch,
      "updatedAt": updatedAt.millisecondsSinceEpoch,
    };

    if (type == CategoryType.plan) {
      data["dailyAmount"] = dailyAmount; // plan일 때만 저장
    }

    return data;
  }

  /// dailyAmount를 null로 “명시 제거” 가능하게 만든 copyWith
  CategoryModel copyWith({
    String? id,
    String? name,
    String? emoji,
    String? color,
    CategoryType? type,
    bool? archived,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,

    int? dailyAmount,
    bool dailyAmountSet = false, // null도 반영하려면 true
  }) {
    final nextType = type ?? this.type;
    final nextAmount = dailyAmountSet ? dailyAmount : this.dailyAmount;

    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      type: nextType,
      dailyAmount: (nextType == CategoryType.plan) ? (nextAmount ?? 0) : null,
      archived: archived ?? this.archived,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
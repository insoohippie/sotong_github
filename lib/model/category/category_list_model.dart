import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_model.dart';

class CategoryListModel {
  final List<CategoryModel> categories;
  final DateTime updatedAt;
  final int version;

  CategoryListModel({
    required this.categories,
    required this.updatedAt,
    this.version = 1,
  });

  /// ✅ 앱 최초 실행 시 사용할 디폴트 카테고리 초기값
  /// (선택지 C: default/user 구분 의미 없음 → id는 그냥 고정 문자열로 둬도 됨)
  factory CategoryListModel.initial() {
    final now = DateTime.now();

    final defaults = <CategoryModel>[
      CategoryModel(
        id: 'cat_food',
        name: '식비',
        emoji: '🍽️',
        color: null,
        type: CategoryType.reference,
        dailyAmount: null,
        archived: false,
        order: 100,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'cat_cafe',
        name: '카페',
        emoji: '☕',
        color: null,
        type: CategoryType.reference,
        dailyAmount: null,
        archived: false,
        order: 110,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'cat_shopping',
        name: '쇼핑',
        emoji: '🛍️',
        color: null,
        type: CategoryType.reference,
        dailyAmount: null,
        archived: false,
        order: 120,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: 'cat_leisure',
        name: '여가',
        emoji: '🎮',
        color: null,
        type: CategoryType.reference,
        dailyAmount: null,
        archived: false,
        order: 130,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    return CategoryListModel(
      categories: defaults,
      updatedAt: now,
    );
  }

  // ---------- Firestore <-> Model ----------

  factory CategoryListModel.fromFirestore(Map<String, dynamic> map) {
    final list = (map['categories'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => CategoryModel.fromFirestore(e))
        .toList();

    final updatedAt = map['updatedAt'] is Timestamp
        ? (map['updatedAt'] as Timestamp).toDate()
        : DateTime.now();

    return CategoryListModel(
      categories: list,
      updatedAt: updatedAt,
      version: map['version'] is int ? (map['version'] as int) : 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "categories": categories.map((c) => c.toFirestore()).toList(),
      "updatedAt": Timestamp.fromDate(updatedAt),
      "version": version,
    };
  }

  // ---------- Hive(JSON) <-> Model ----------

  factory CategoryListModel.fromJson(Map<String, dynamic> map) {
    final list = (map['categories'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => CategoryModel.fromJson(e))
        .toList();

    final updatedAt = map['updatedAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
        : DateTime.now();

    return CategoryListModel(
      categories: list,
      updatedAt: updatedAt,
      version: map['version'] is int ? (map['version'] as int) : 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "categories": categories.map((c) => c.toJson()).toList(),
      "updatedAt": updatedAt.millisecondsSinceEpoch,
      "version": version,
    };
  }

  CategoryListModel copyWith({
    List<CategoryModel>? categories,
    DateTime? updatedAt,
    int? version,
  }) {
    return CategoryListModel(
      categories: categories ?? this.categories,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  // ---------- 편의 메서드들 ----------

  /// ✅ (기존 함수 유지) 참고 카테고리(reference)로 추가
  /// - 기존 코드 호환을 위해 시그니처 유지
  /// - type은 reference로 고정, dailyAmount는 null
  CategoryListModel addCategory({
    required String id,
    required String name,
    required String emoji,
    String? color,
  }) {
    final now = DateTime.now();

    // reference 그룹 기준 max order
    final refOrders = categories
        .where((c) => !c.archived && c.type == CategoryType.reference)
        .map((c) => c.order)
        .toList();

    final nextOrder = refOrders.isEmpty
        ? 100
        : (refOrders.reduce((a, b) => a > b ? a : b) + 10);

    final newList = List<CategoryModel>.from(categories)
      ..add(
        CategoryModel(
          id: id,
          name: name,
          emoji: emoji,
          color: color,
          type: CategoryType.reference,
          dailyAmount: null,
          archived: false,
          order: nextOrder,
          createdAt: now,
          updatedAt: now,
        ),
      );

    return copyWith(
      categories: newList,
      updatedAt: now,
    );
  }

  /// ✅ (추가) 플랜 카테고리(plan)로 추가하고 싶을 때 사용하는 버전
  /// - 필요할 때만 쓰면 됨 (기존 함수 삭제 X)
  CategoryListModel addPlanCategory({
    required String id,
    required String name,
    required String emoji,
    required int dailyAmount,
    String? color,
  }) {
    final now = DateTime.now();

    final planOrders = categories
        .where((c) => !c.archived && c.type == CategoryType.plan)
        .map((c) => c.order)
        .toList();

    final nextOrder = planOrders.isEmpty
        ? 100
        : (planOrders.reduce((a, b) => a > b ? a : b) + 10);

    final newList = List<CategoryModel>.from(categories)
      ..add(
        CategoryModel(
          id: id,
          name: name,
          emoji: emoji,
          color: color,
          type: CategoryType.plan,
          dailyAmount: dailyAmount,
          archived: false,
          order: nextOrder,
          createdAt: now,
          updatedAt: now,
        ),
      );

    return copyWith(categories: newList, updatedAt: now);
  }

  /// 논리 삭제(archived = true)
  CategoryListModel archiveCategory(String id) {
    final now = DateTime.now();
    final newList = categories
        .map(
          (c) => c.id == id ? c.copyWith(archived: true, updatedAt: now) : c,
    )
        .toList();

    return copyWith(
      categories: newList,
      updatedAt: now,
    );
  }

  /// (기존 함수 유지) 전체 순서 재배치
  /// - 이제 A/B가 있으니, 가급적이면 VM에서 reorderPlan/reorderReference를 따로 쓰는 걸 추천
  /// - 그래도 기존 호환성 때문에 남겨둠
  CategoryListModel reorder(List<String> orderedIds) {
    final now = DateTime.now();
    int orderVal = 100;

    final newList = categories
        .map(
          (c) => orderedIds.contains(c.id)
          ? c.copyWith(order: (orderVal += 10), updatedAt: now)
          : c,
    )
        .toList();

    return copyWith(
      categories: newList,
      updatedAt: now,
    );
  }
}
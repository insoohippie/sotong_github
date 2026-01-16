import 'package:flutter/foundation.dart';

import '../../model/category/category_list_model.dart';
import '../../model/category/category_model.dart';
import '../../repository/category_repository.dart';

/// ✅ 저장/동기화 카테고리 전용 ViewModel
/// - Firestore/Hive와 동기화되는 CategoryListModel을 source of truth로 사용
/// - CategoryType(plan/reference) + plan dailyAmount까지 관리
/// - (선택지 C) default/user 구분 없음. id prefix 규칙 사용 안 함.
class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repo;

  CategoryViewModel(this._repo) {
    _init();
  }

  // ================== Master Category List ==================

  CategoryListModel _categoryList = CategoryListModel.initial();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 전체(archived 포함)
  List<CategoryModel> get allCategories => List.unmodifiable(_categoryList.categories);

  /// 활성(archived 제외) + order 정렬 (type 섞임)
  List<CategoryModel> get activeCategories {
    final list = _categoryList.categories.where((c) => !c.archived).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(list);
  }

  /// ✅ 플랜 카테고리(A)만
  List<CategoryModel> get planCategories {
    final list = _categoryList.categories
        .where((c) => !c.archived && c.type == CategoryType.plan)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(list);
  }

  /// ✅ 참고 카테고리(B)만
  List<CategoryModel> get referenceCategories {
    final list = _categoryList.categories
        .where((c) => !c.archived && c.type == CategoryType.reference)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(list);
  }

  // ================== Init / Reload ==================

  Future<void> _init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categoryList = await _repo.loadCategoryList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadFromDb() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categoryList = await _repo.loadCategoryList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================== Helpers ==================

  int _nextGroupOrder(CategoryType type) {
    final list = _categoryList.categories
        .where((c) => !c.archived && c.type == type)
        .toList();
    if (list.isEmpty) return 100;

    list.sort((a, b) => a.order.compareTo(b.order));
    return list.last.order + 10;
  }

  CategoryModel? _findById(String id) {
    try {
      return _categoryList.categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ================== CRUD (저장되는 카테고리) ==================
  // ※ 기존 코드와 충돌 줄이려고 “새 함수로 추가” 위주로 제공

  /// ✅ 참고 카테고리(B) 추가
  /// - id는 의미 없이 유니크하면 됨 (선택지 C)
  Future<void> addReferenceCategory({
    required String name,
    required String emoji,
    String? color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // 이름 중복 방지(선택)
    final dup = _categoryList.categories.any(
          (c) => !c.archived && c.name == trimmed,
    );
    if (dup) return;

    final now = DateTime.now();
    final id = 'cat_${now.millisecondsSinceEpoch}';

    final newCat = CategoryModel(
      id: id,
      name: trimmed,
      emoji: emoji,
      color: color,
      type: CategoryType.reference,
      dailyAmount: null,
      archived: false,
      order: _nextGroupOrder(CategoryType.reference),
      createdAt: now,
      updatedAt: now,
    );

    final newList = List<CategoryModel>.from(_categoryList.categories)..add(newCat);

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }

  /// ✅ 이름 수정 (A/B 공통)
  Future<void> updateCategoryName({
    required String categoryId,
    required String newName,
  }) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();

    // 이름 중복 방지(선택)
    final dup = _categoryList.categories.any((c) =>
    !c.archived && c.id != categoryId && c.name == trimmed);
    if (dup) return;

    final newList = _categoryList.categories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(name: trimmed, updatedAt: now);
    }).toList();

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }

  /// ✅ 이모지 수정 (A/B 공통)
  Future<void> updateCategoryEmoji({
    required String categoryId,
    required String emoji,
  }) async {
    final now = DateTime.now();

    final newList = _categoryList.categories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(emoji: emoji, updatedAt: now);
    }).toList();

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }

  /// ✅ 논리 삭제(archived)
  Future<void> archiveCategory(String categoryId) async {
    final now = DateTime.now();

    final newList = _categoryList.categories.map((c) {
      if (c.id != categoryId) return c;
      return c.copyWith(archived: true, updatedAt: now);
    }).toList();

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }

  // ================== A/B 이동 규칙 ==================

  /// ✅ 참고(B) → 플랜(A)
  /// - dailyAmount 입력값을 받아서 저장
  /// - type을 plan으로 변경
  Future<void> moveToPlan({
    required String categoryId,
    required int dailyAmount,
  }) async {
    if (dailyAmount < 0) return;

    final target = _findById(categoryId);
    if (target == null) return;

    final now = DateTime.now();
    final nextOrder = _nextGroupOrder(CategoryType.plan);

    final newList = _categoryList.categories.map((c) {
      if (c.id != categoryId) return c;

      return c.copyWith(
        type: CategoryType.plan,
        dailyAmount: dailyAmount,
        dailyAmountSet: true,
        order: nextOrder,
        updatedAt: now,
      );
    }).toList();

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }

  /// ✅ 플랜(A) → 참고(B)
  /// - dailyAmount 제거(null)
  /// - type을 reference로 변경
  Future<void> moveToReference({
    required String categoryId,
  }) async {
    final target = _findById(categoryId);
    if (target == null) return;

    final now = DateTime.now();
    final nextOrder = _nextGroupOrder(CategoryType.reference);

    final newList = _categoryList.categories.map((c) {
      if (c.id != categoryId) return c;

      return c.copyWith(
        type: CategoryType.reference,
        dailyAmount: null,
        dailyAmountSet: true, // ✅ 제거 반영
        order: nextOrder,
        updatedAt: now,
      );
    }).toList();

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }

  /// ✅ 플랜 카테고리(A)의 금액 수정
  Future<void> updatePlanDailyAmount({
    required String categoryId,
    required int dailyAmount,
  }) async {
    if (dailyAmount < 0) return;

    final target = _findById(categoryId);
    if (target == null) return;
    if (target.type != CategoryType.plan) return;

    final now = DateTime.now();

    final newList = _categoryList.categories.map((c) {
      if (c.id != categoryId) return c;

      return c.copyWith(
        dailyAmount: dailyAmount,
        dailyAmountSet: true,
        updatedAt: now,
      );
    }).toList();

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }

  // ================== Group Reorder ==================

  /// ✅ 플랜(A) 내부 reorder: ids 순서대로 100,110...
  Future<void> reorderPlan(List<String> orderedIds) async {
    final now = DateTime.now();
    int orderVal = 90;

    final newList = _categoryList.categories.map((c) {
      if (c.archived) return c;
      if (c.type != CategoryType.plan) return c;
      if (!orderedIds.contains(c.id)) return c;

      orderVal += 10;
      return c.copyWith(order: orderVal, updatedAt: now);
    }).toList();

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }

  /// ✅ 참고(B) 내부 reorder: ids 순서대로 100,110...
  Future<void> reorderReference(List<String> orderedIds) async {
    final now = DateTime.now();
    int orderVal = 90;

    final newList = _categoryList.categories.map((c) {
      if (c.archived) return c;
      if (c.type != CategoryType.reference) return c;
      if (!orderedIds.contains(c.id)) return c;

      orderVal += 10;
      return c.copyWith(order: orderVal, updatedAt: now);
    }).toList();

    _categoryList = _categoryList.copyWith(categories: newList, updatedAt: now);
    notifyListeners();
    await _repo.saveCategoryList(_categoryList);
  }
}

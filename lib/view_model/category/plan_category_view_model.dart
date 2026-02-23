// 이 파일은 플랜 생성 때 입력받는 카테고리에만 사용할 예정
// 기본 4개의 카테고리들이 있고, 추가하고 선택 가능

import 'package:flutter/foundation.dart';

class PlanCategoryViewModel extends ChangeNotifier {
  // =========================
  // ✅ 기본 카테고리(항상 존재해야 함)
  // =========================
  static const List<String> baseIncomeCategories = ['급여', '사업', '배당', '용돈'];
  static const List<String> baseFixedExpenseCategories = ['주거', '통신', '교통', '구독'];
  static const List<String> baseDailyExpenseCategories = ['식비', '카페', '쇼핑', '여가'];

  static const Map<String, String> baseIncomeEmojis = {
    '급여': '💼',
    '사업': '🏢',
    '배당': '📈',
    '용돈': '🎁',
  };

  static const Map<String, String> baseFixedExpenseEmojis = {
    '주거': '🏠',
    '통신': '📱',
    '교통': '🚌',
    '구독': '📺',
  };

  static const Map<String, String> baseDailyExpenseEmojis = {
    '식비': '🍽️',
    '카페': '☕',
    '쇼핑': '🛍️',
    '여가': '🎮',
  };

  // =========================
  // ✅ 커스텀 저장소
  // =========================
  final List<String> _customIncomeCategories = [];
  final List<String> _customFixedExpenseCategories = [];
  final List<String> _customDailyExpenseCategories = [];

  final Map<String, String> _incomeCategoryEmojis = {};
  final Map<String, String> _fixedExpenseCategoryEmojis = {};
  final Map<String, String> _dailyExpenseCategoryEmojis = {};

  // =========================
  // ✅ 정렬(order) 저장소 (메모리 유지)
  // =========================
  final List<String> _incomeOrder = [];
  final List<String> _fixedOrder = [];
  final List<String> _dailyOrder = [];

  // =========================
  // ✅ UI에서 쓰는 getter (order 기반)
  // - base + custom 전체를 항상 포함
  // - order가 비어있으면 base+custom 순서로 초기화
  // - 새로 추가된 항목은 뒤에 붙임 / 삭제된 항목은 제거
  // =========================
  List<String> get incomeCategories => _ensureOrder(
    base: baseIncomeCategories,
    custom: _customIncomeCategories,
    order: _incomeOrder,
  );

  List<String> get fixedExpenseCategories => _ensureOrder(
    base: baseFixedExpenseCategories,
    custom: _customFixedExpenseCategories,
    order: _fixedOrder,
  );

  List<String> get dailyExpenseCategories => _ensureOrder(
    base: baseDailyExpenseCategories,
    custom: _customDailyExpenseCategories,
    order: _dailyOrder,
  );

  /// ✅ 이모지도 기본 + 커스텀 merge (커스텀은 override 역할)
  Map<String, String> get incomeCategoryEmojis => {
    ...baseIncomeEmojis,
    ..._incomeCategoryEmojis,
  };

  Map<String, String> get fixedExpenseCategoryEmojis => {
    ...baseFixedExpenseEmojis,
    ..._fixedExpenseCategoryEmojis,
  };

  Map<String, String> get dailyExpenseCategoryEmojis => {
    ...baseDailyExpenseEmojis,
    ..._dailyExpenseCategoryEmojis,
  };

  // =========================
  // (옵션) 디버그용 getter
  // =========================
  List<String> get customIncomeCategories => List.unmodifiable(_customIncomeCategories);
  List<String> get customFixedExpenseCategories => List.unmodifiable(_customFixedExpenseCategories);
  List<String> get customDailyExpenseCategories => List.unmodifiable(_customDailyExpenseCategories);

  Map<String, String> get customIncomeEmojis => Map.unmodifiable(_incomeCategoryEmojis);
  Map<String, String> get customFixedExpenseEmojis => Map.unmodifiable(_fixedExpenseCategoryEmojis);
  Map<String, String> get customDailyEmojis => Map.unmodifiable(_dailyExpenseCategoryEmojis);

  // =========================
  // ✅ 바텀시트 정렬 저장 (핵심)
  // openCategorySheet의 onReorder(newOrder)와 연결할 함수들
  // =========================
  void setIncomeOrder(List<String> newOrder) => _setOrder(
    order: _incomeOrder,
    base: baseIncomeCategories,
    custom: _customIncomeCategories,
    newOrder: newOrder,
  );

  void setFixedOrder(List<String> newOrder) => _setOrder(
    order: _fixedOrder,
    base: baseFixedExpenseCategories,
    custom: _customFixedExpenseCategories,
    newOrder: newOrder,
  );

  void setDailyOrder(List<String> newOrder) => _setOrder(
    order: _dailyOrder,
    base: baseDailyExpenseCategories,
    custom: _customDailyExpenseCategories,
    newOrder: newOrder,
  );

  // =========================
  // 수입
  // =========================
  void addCustomIncomeCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (_customIncomeCategories.contains(trimmed)) return;

    _customIncomeCategories.add(trimmed);
    // order는 getter에서 자동 보정되지만, UI 즉시 반영을 위해 notify
    notifyListeners();
  }

  void addCustomIncomeCategoryWithEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    if (!_customIncomeCategories.contains(trimmed)) _customIncomeCategories.add(trimmed);
    _incomeCategoryEmojis[trimmed] = emoji.trim().isEmpty ? '💰' : emoji.trim();
    notifyListeners();
  }

  void removeCustomIncomeCategory(String category) {
    final trimmed = category.trim();

    if (baseIncomeCategories.contains(trimmed)) {
      // 기본은 리스트에서 제거 불가: override emoji만 제거
      _incomeCategoryEmojis.remove(trimmed);
      notifyListeners();
      return;
    }

    _customIncomeCategories.remove(trimmed);
    _incomeCategoryEmojis.remove(trimmed);
    notifyListeners();
  }

  // =========================
  // 고정 소비
  // =========================
  void addCustomFixedExpenseCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (_customFixedExpenseCategories.contains(trimmed)) return;

    _customFixedExpenseCategories.add(trimmed);
    notifyListeners();
  }

  void addCustomFixedExpenseCategoryWithEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    if (!_customFixedExpenseCategories.contains(trimmed)) _customFixedExpenseCategories.add(trimmed);
    _fixedExpenseCategoryEmojis[trimmed] = emoji.trim().isEmpty ? '💰' : emoji.trim();
    notifyListeners();
  }

  void removeCustomFixedExpenseCategory(String category) {
    final trimmed = category.trim();

    if (baseFixedExpenseCategories.contains(trimmed)) {
      _fixedExpenseCategoryEmojis.remove(trimmed);
      notifyListeners();
      return;
    }

    _customFixedExpenseCategories.remove(trimmed);
    _fixedExpenseCategoryEmojis.remove(trimmed);
    notifyListeners();
  }

  // =========================
  // 일일 소비
  // =========================
  void addCustomDailyExpenseCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (_customDailyExpenseCategories.contains(trimmed)) return;

    _customDailyExpenseCategories.add(trimmed);
    notifyListeners();
  }

  void addCustomDailyExpenseCategoryWithEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    if (!_customDailyExpenseCategories.contains(trimmed)) _customDailyExpenseCategories.add(trimmed);
    _dailyExpenseCategoryEmojis[trimmed] = emoji.trim().isEmpty ? '💰' : emoji.trim();
    notifyListeners();
  }

  void removeCustomDailyExpenseCategory(String category) {
    final trimmed = category.trim();

    if (baseDailyExpenseCategories.contains(trimmed)) {
      _dailyExpenseCategoryEmojis.remove(trimmed);
      notifyListeners();
      return;
    }

    _customDailyExpenseCategories.remove(trimmed);
    _dailyExpenseCategoryEmojis.remove(trimmed);
    notifyListeners();
  }

  // =========================
  // 내부 헬퍼들
  // =========================
  List<String> _ensureOrder({
    required List<String> base,
    required List<String> custom,
    required List<String> order,
  }) {
    final all = [...base, ...custom];

    // 최초 초기화
    if (order.isEmpty) {
      order.addAll(all);
      return List.unmodifiable(order);
    }

    // 새로 추가된 항목 반영 (뒤에 붙임)
    for (final name in all) {
      if (!order.contains(name)) order.add(name);
    }

    // 삭제된 항목 제거
    order.removeWhere((name) => !all.contains(name));

    return List.unmodifiable(order);
  }

  void _setOrder({
    required List<String> order,
    required List<String> base,
    required List<String> custom,
    required List<String> newOrder,
  }) {
    final all = [...base, ...custom];

    // newOrder에서 유효한 것만 + 중복 제거
    final next = <String>[];
    for (final name in newOrder) {
      if (all.contains(name) && !next.contains(name)) next.add(name);
    }

    // 누락된 항목은 뒤에 붙이기
    for (final name in all) {
      if (!next.contains(name)) next.add(name);
    }

    order
      ..clear()
      ..addAll(next);

    notifyListeners();
  }
}

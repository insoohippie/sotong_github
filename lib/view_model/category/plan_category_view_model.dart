// plan_category_view_model.dart
// 이 파일은 플랜 생성 때 입력받는 카테고리에만 사용할 예정
// 기본 4개의 카테고리들이 있고, 추가하고 선택 가능

import 'package:flutter/foundation.dart';

import '../../services/category_key.dart';

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

  PlanCategoryViewModel() {
    _ensureBaseKeys(); // ✅ 기본 4개 key를 생성/보장
  }

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
  // ✅ (추가) name -> categoryKey 저장소 (핵심)
  // - base + custom 모두 여기에 key를 보관
  // - 플랜 생성 단계에서만 쓰므로 메모리 유지면 충분
  // =========================
  final Map<String, String> _incomeNameToKey = {};
  final Map<String, String> _fixedNameToKey = {};
  final Map<String, String> _dailyNameToKey = {};

  bool _baseKeyInitialized = false;

  void _ensureBaseKeys() {
    if (_baseKeyInitialized) return;
    _baseKeyInitialized = true;

    for (final n in baseIncomeCategories) {
      _incomeNameToKey[n] ??= CategoryKey.newKey();
    }
    for (final n in baseFixedExpenseCategories) {
      _fixedNameToKey[n] ??= CategoryKey.newKey();
    }
    for (final n in baseDailyExpenseCategories) {
      _dailyNameToKey[n] ??= CategoryKey.newKey();
    }
  }

  /// ✅ 외부에서 name으로 key를 얻을 때 쓰는 함수들
  /// - 존재하면 기존 key 반환
  /// - 없으면 새로 생성해서 저장
  String keyOfIncome(String name) {
    _ensureBaseKeys();
    final n = name.trim();
    return _incomeNameToKey[n] ??= CategoryKey.newKey();
  }

  String keyOfFixed(String name) {
    _ensureBaseKeys();
    final n = name.trim();
    return _fixedNameToKey[n] ??= CategoryKey.newKey();
  }

  String keyOfDaily(String name) {
    _ensureBaseKeys();
    final n = name.trim();
    return _dailyNameToKey[n] ??= CategoryKey.newKey();
  }

  // =========================
  // ✅ 정렬(order) 저장소 (메모리 유지)
  // =========================
  final List<String> _incomeOrder = [];
  final List<String> _fixedOrder = [];
  final List<String> _dailyOrder = [];

  // =========================
  // ✅ UI에서 쓰는 getter (order 기반)
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

  /// (옵션) 디버그용 key 맵
  Map<String, String> get incomeNameToKey => Map.unmodifiable(_incomeNameToKey);
  Map<String, String> get fixedNameToKey => Map.unmodifiable(_fixedNameToKey);
  Map<String, String> get dailyNameToKey => Map.unmodifiable(_dailyNameToKey);

  // =========================
  // ✅ 바텀시트 정렬 저장
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

    // ✅ key 보장
    _incomeNameToKey[trimmed] ??= CategoryKey.newKey();

    notifyListeners();
  }

  void addCustomIncomeCategoryWithEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    if (!_customIncomeCategories.contains(trimmed)) _customIncomeCategories.add(trimmed);
    _incomeCategoryEmojis[trimmed] = emoji.trim().isEmpty ? '💰' : emoji.trim();

    // ✅ key 보장
    _incomeNameToKey[trimmed] ??= CategoryKey.newKey();

    notifyListeners();
  }

  void removeCustomIncomeCategory(String category) {
    final trimmed = category.trim();

    if (baseIncomeCategories.contains(trimmed)) {
      // 기본은 리스트에서 제거 불가: override emoji만 제거
      _incomeCategoryEmojis.remove(trimmed);
      // ✅ 기본 key는 유지 (같은 세션에서 안정적으로 사용)
      notifyListeners();
      return;
    }

    _customIncomeCategories.remove(trimmed);
    _incomeCategoryEmojis.remove(trimmed);

    // ✅ key도 정리
    _incomeNameToKey.remove(trimmed);

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

    // ✅ key 보장
    _fixedNameToKey[trimmed] ??= CategoryKey.newKey();

    notifyListeners();
  }

  void addCustomFixedExpenseCategoryWithEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    if (!_customFixedExpenseCategories.contains(trimmed)) {
      _customFixedExpenseCategories.add(trimmed);
    }
    _fixedExpenseCategoryEmojis[trimmed] = emoji.trim().isNotEmpty ? emoji.trim() : '💰';

    // ✅ key 보장
    _fixedNameToKey[trimmed] ??= CategoryKey.newKey();

    notifyListeners();
  }

  void removeCustomFixedExpenseCategory(String category) {
    final trimmed = category.trim();

    if (baseFixedExpenseCategories.contains(trimmed)) {
      _fixedExpenseCategoryEmojis.remove(trimmed);
      // ✅ 기본 key는 유지
      notifyListeners();
      return;
    }

    _customFixedExpenseCategories.remove(trimmed);
    _fixedExpenseCategoryEmojis.remove(trimmed);

    // ✅ key 정리
    _fixedNameToKey.remove(trimmed);

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

    // ✅ key 보장
    _dailyNameToKey[trimmed] ??= CategoryKey.newKey();

    notifyListeners();
  }

  void addCustomDailyExpenseCategoryWithEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    if (!_customDailyExpenseCategories.contains(trimmed)) {
      _customDailyExpenseCategories.add(trimmed);
    }
    _dailyExpenseCategoryEmojis[trimmed] = emoji.trim().isNotEmpty ? emoji.trim() : '💰';

    // ✅ key 보장
    _dailyNameToKey[trimmed] ??= CategoryKey.newKey();

    notifyListeners();
  }

  void removeCustomDailyExpenseCategory(String category) {
    final trimmed = category.trim();

    if (baseDailyExpenseCategories.contains(trimmed)) {
      _dailyExpenseCategoryEmojis.remove(trimmed);
      // ✅ 기본 key 유지
      notifyListeners();
      return;
    }

    _customDailyExpenseCategories.remove(trimmed);
    _dailyExpenseCategoryEmojis.remove(trimmed);

    // ✅ key 정리
    _dailyNameToKey.remove(trimmed);

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
    _ensureBaseKeys(); // ✅ base key는 항상 준비

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
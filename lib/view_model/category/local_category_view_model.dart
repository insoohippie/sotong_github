import 'package:flutter/foundation.dart';

/// 로컬 전용 카테고리 ViewModel
/// - 수입 / 고정지출 카테고리(문자열 리스트 + 이모지)를 로컬 메모리에서만 관리
/// - DB/Hive/Firestore 동기화 없음

class LocalCategoryViewModel extends ChangeNotifier {
  // ================== Local lists ==================

  final List<String> _customIncomeCategories = [];
  final List<String> _customFixedExpenseCategories = [];

  final Map<String, String> _incomeCategoryEmojis = {};
  final Map<String, String> _fixedExpenseCategoryEmojis = {};

  // ----- getters (기존 그대로) -----

  List<String> get customIncomeCategories =>
      List.unmodifiable(_customIncomeCategories);

  List<String> get customFixedExpenseCategories =>
      List.unmodifiable(_customFixedExpenseCategories);

  Map<String, String> get incomeCategoryEmojis =>
      Map.unmodifiable(_incomeCategoryEmojis);

  Map<String, String> get fixedExpenseCategoryEmojis =>
      Map.unmodifiable(_fixedExpenseCategoryEmojis);

  // ===========================================================
  // 🔹 수입 카테고리 (로컬 전용)
  // ===========================================================

  void addCustomIncomeCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (_customIncomeCategories.contains(trimmed)) return;

    _customIncomeCategories.add(trimmed);
    notifyListeners();
  }

  void addCustomIncomeCategoryWithEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    if (!_customIncomeCategories.contains(trimmed)) {
      _customIncomeCategories.add(trimmed);
    }
    _incomeCategoryEmojis[trimmed] = emoji;
    notifyListeners();
  }

  void setIncomeCategoryEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    _incomeCategoryEmojis[trimmed] = emoji;
    notifyListeners();
  }

  void removeCustomIncomeCategory(String category) {
    final trimmed = category.trim();
    _customIncomeCategories.remove(trimmed);
    _incomeCategoryEmojis.remove(trimmed);
    notifyListeners();
  }

  // ===========================================================
  // 🔹 고정 소비 카테고리 (로컬 전용)
  // ===========================================================

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

    if (!_customFixedExpenseCategories.contains(trimmed)) {
      _customFixedExpenseCategories.add(trimmed);
    }
    _fixedExpenseCategoryEmojis[trimmed] = emoji;
    notifyListeners();
  }

  void setFixedExpenseCategoryEmoji(String category, String emoji) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    _fixedExpenseCategoryEmojis[trimmed] = emoji;
    notifyListeners();
  }

  void removeCustomFixedExpenseCategory(String category) {
    final trimmed = category.trim();
    _customFixedExpenseCategories.remove(trimmed);
    _fixedExpenseCategoryEmojis.remove(trimmed);
    notifyListeners();
  }
}

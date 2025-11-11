/// 카테고리 상태를 관리하는 간단한 싱글톤 클래스
class CategoryStateManager {
  static final CategoryStateManager _instance =
      CategoryStateManager._internal();
  factory CategoryStateManager() => _instance;
  CategoryStateManager._internal();

  // 각 카테고리 타입별 활성화 상태 저장
  static List<bool> _incomeEnabledStates = [true, true, true, true];
  static List<bool> _fixedExpenseEnabledStates = [true, true, true, true];
  static List<bool> _dailyExpenseEnabledStates = [true, true, true, true];

  // 사용자 추가 카테고리 저장
  static List<String> _customIncomeCategories = [];
  static List<String> _customFixedExpenseCategories = [];
  static List<String> _customDailyExpenseCategories = [];

  // 카테고리별 이모지 저장
  static Map<String, String> _incomeCategoryEmojis = {};
  static Map<String, String> _fixedExpenseCategoryEmojis = {};
  static Map<String, String> _dailyExpenseCategoryEmojis = {};

  // 수입 카테고리 상태 관리
  static List<bool> get incomeEnabledStates => _incomeEnabledStates;
  static void updateIncomeStates(List<bool> states) =>
      _incomeEnabledStates = states;
  static void setIncomeState(int index, bool enabled) {
    if (index < _incomeEnabledStates.length) {
      _incomeEnabledStates[index] = enabled;
    }
  }

  // 고정소비 카테고리 상태 관리
  static List<bool> get fixedExpenseEnabledStates => _fixedExpenseEnabledStates;
  static void updateFixedExpenseStates(List<bool> states) =>
      _fixedExpenseEnabledStates = states;
  static void setFixedExpenseState(int index, bool enabled) {
    if (index < _fixedExpenseEnabledStates.length) {
      _fixedExpenseEnabledStates[index] = enabled;
    }
  }

  // 일변동소비 카테고리 상태 관리
  static List<bool> get dailyExpenseEnabledStates => _dailyExpenseEnabledStates;
  static void updateDailyExpenseStates(List<bool> states) =>
      _dailyExpenseEnabledStates = states;
  static void setDailyExpenseState(int index, bool enabled) {
    if (index < _dailyExpenseEnabledStates.length) {
      _dailyExpenseEnabledStates[index] = enabled;
    }
  }

  // 사용자 추가 카테고리 관리
  static List<String> get customIncomeCategories => _customIncomeCategories;
  static List<String> get customFixedExpenseCategories =>
      _customFixedExpenseCategories;
  static List<String> get customDailyExpenseCategories =>
      _customDailyExpenseCategories;

  static void addCustomIncomeCategory(String category) {
    if (!_customIncomeCategories.contains(category)) {
      _customIncomeCategories.add(category);
    }
  }

  static void addCustomFixedExpenseCategory(String category) {
    if (!_customFixedExpenseCategories.contains(category)) {
      _customFixedExpenseCategories.add(category);
    }
  }

  static void addCustomDailyExpenseCategory(String category) {
    if (!_customDailyExpenseCategories.contains(category)) {
      _customDailyExpenseCategories.add(category);
    }
  }

  static void removeCustomIncomeCategory(String category) {
    _customIncomeCategories.remove(category);
    _incomeCategoryEmojis.remove(category);
  }

  static void removeCustomFixedExpenseCategory(String category) {
    _customFixedExpenseCategories.remove(category);
    _fixedExpenseCategoryEmojis.remove(category);
  }

  static void removeCustomDailyExpenseCategory(String category) {
    _customDailyExpenseCategories.remove(category);
    _dailyExpenseCategoryEmojis.remove(category);
  }

  // 카테고리별 이모지 관리
  static Map<String, String> get incomeCategoryEmojis => _incomeCategoryEmojis;
  static Map<String, String> get fixedExpenseCategoryEmojis =>
      _fixedExpenseCategoryEmojis;
  static Map<String, String> get dailyExpenseCategoryEmojis =>
      _dailyExpenseCategoryEmojis;

  static void setIncomeCategoryEmoji(String category, String emoji) {
    _incomeCategoryEmojis[category] = emoji;
  }

  static void setFixedExpenseCategoryEmoji(String category, String emoji) {
    _fixedExpenseCategoryEmojis[category] = emoji;
  }

  static void setDailyExpenseCategoryEmoji(String category, String emoji) {
    _dailyExpenseCategoryEmojis[category] = emoji;
  }

  // 활성화된 일변동소비 카테고리 목록 반환 (프리셋 + 사용자 추가)
  static List<String> getActiveDailyExpenseCategories() {
    // 프리셋 카테고리에서 활성화된 것들
    const presetCategories = ['식비', '카페', '쇼핑', '여가'];
    List<String> activeCategories = [];

    for (
      int i = 0;
      i < presetCategories.length && i < _dailyExpenseEnabledStates.length;
      i++
    ) {
      if (_dailyExpenseEnabledStates[i]) {
        activeCategories.add(presetCategories[i]);
      }
    }

    // 사용자 추가 카테고리 추가
    activeCategories.addAll(_customDailyExpenseCategories);

    return activeCategories;
  }
}

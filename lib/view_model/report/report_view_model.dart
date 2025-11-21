import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

class ReportViewModel extends ChangeNotifier {
  // ───────── 기본 상태 값 ─────────
  String budgetPeriod = '주간'; // '일간' | '주간' | '월간'
  int selectedMonth = DateTime.now().month;
  String selectedCategory = '저축'; // '저축' | '수입' | '고정소비' | '변동소비'
  bool isCategoryDropdownOpen = false;

  int currentInsightIndex = 0;

  // ───────── 더미 금액 데이터 (카테고리 합계) ─────────
  final int incomeTotal = 2_800_000;
  final int fixedExpenseTotal = 1_200_000;
  final int variableExpenseTotal = 900_000;
  final int savingTotal = 700_000;

  // ───────── 인사이트 데이터 ─────────
  late final List<Map<String, dynamic>> insights;

  // ───────── 카테고리별 남은 예산 데이터 ─────────
  late final Map<String, List<Map<String, dynamic>>> categoryBudgetData;

  ReportViewModel() {
    // 인사이트 원본
    final originalInsights = [
      {
        'title': '목표금액의 60%를 달성했어요',
        'icon': Icons.flag_circle,
        'color': AppColors.primary,
      },
      {
        'title': '하루 평균 ₩15,800을 사용했어요',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF43A047),
      },
      {
        'title': '일주일 평균 ₩110,000을 사용했어요',
        'icon': Icons.bar_chart,
        'color': AppColors.primary,
      },
      {
        'title': '현재 속도로 가면 5일 뒤 예산을 모두 소진해요',
        'icon': Icons.access_time,
        'color': const Color(0xFFD32F2F),
      },
    ];

    // 무한 스크롤 느낌을 위해 여러 번 반복
    insights = [];
    for (int i = 0; i < 10; i++) {
      insights.addAll(originalInsights);
    }

    // 카테고리별 남은 예산 (일간/주간/월간)
    categoryBudgetData = {
      '일간': [
        {'category': '식비', 'budget': 15000, 'spent': 12000},
        {'category': '교통비', 'budget': 8000, 'spent': 9500},
        {'category': '고정비', 'budget': 10000, 'spent': 8000},
        {'category': '기타', 'budget': 7000, 'spent': 5000},
      ],
      '주간': [
        {'category': '식비', 'budget': 50000, 'spent': 42000},
        {'category': '교통비', 'budget': 25000, 'spent': 28000},
        {'category': '고정비', 'budget': 35000, 'spent': 30000},
        {'category': '기타', 'budget': 20000, 'spent': 15000},
      ],
      '월간': [
        {'category': '식비', 'budget': 200000, 'spent': 180000},
        {'category': '교통비', 'budget': 100000, 'spent': 95000},
        {'category': '고정비', 'budget': 150000, 'spent': 140000},
        {'category': '기타', 'budget': 80000, 'spent': 65000},
      ],
    };
  }

  // ───────── getter ─────────

  List<Map<String, dynamic>> get currentBudgetData =>
      categoryBudgetData[budgetPeriod] ?? [];

  int get amountForSelectedCategory => getAmountForCategory(selectedCategory);

  double get maxYForCurrentBudget {
    final data = currentBudgetData;
    if (data.isEmpty) return 100000;

    double max = 0;
    for (final item in data) {
      final budget = (item['budget'] as num).toDouble();
      final spent = (item['spent'] as num).toDouble();
      final highest = budget > spent ? budget : spent;
      if (highest > max) max = highest;
    }
    return (max * 1.2).ceilToDouble();
  }

  // ───────── 액션 메서드 ─────────

  void setBudgetPeriod(String period) {
    if (budgetPeriod == period) return;
    budgetPeriod = period;
    notifyListeners();
  }

  void changeMonth(int delta) {
    selectedMonth += delta;
    if (selectedMonth < 1) selectedMonth = 12;
    if (selectedMonth > 12) selectedMonth = 1;
    notifyListeners();
  }

  void toggleCategoryDropdown() {
    isCategoryDropdownOpen = !isCategoryDropdownOpen;
    notifyListeners();
  }

  void selectCategory(String category) {
    if (selectedCategory == category) {
      isCategoryDropdownOpen = false;
    } else {
      selectedCategory = category;
      isCategoryDropdownOpen = false;
    }
    notifyListeners();
  }

  void setInsightIndex(int index) {
    currentInsightIndex = index;
    notifyListeners();
  }

  int getAmountForCategory(String category) {
    switch (category) {
      case '저축':
        return savingTotal;
      case '수입':
        return incomeTotal;
      case '고정소비':
        return fixedExpenseTotal;
      case '변동소비':
        return variableExpenseTotal;
      default:
        return 0;
    }
  }
}

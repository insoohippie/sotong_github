// lib/model/record/category_spending_summary.dart
class CategorySpendingSummary {
  final String? categoryId;     // CategoryListModel 쪽 id (없으면 null)
  final String name;           // 카테고리 이름 (SpendingEntry.category)
  final String emoji;          // CategoryListModel에서 온 이모지, 없으면 기본값
  final int totalAmount;       // 그 달 전체 소비 합계

  CategorySpendingSummary({
    required this.categoryId,
    required this.name,
    required this.emoji,
    required this.totalAmount,
  });
}

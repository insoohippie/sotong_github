// category_edit_item.dart
import 'package:meta/meta.dart';

/// 수정 페이지에서 A/B를 한 번에 다루기 위한 공통 아이템.
/// - kind=plan이면 dailyAmount 필수
/// - kind=ref이면 dailyAmount는 null
enum CategoryKind { plan, ref }

@immutable
class CategoryEditItem {
  /// ✅ 불변 ID (A/B 통합 기준)
  final String categoryKey;

  /// 표시용
  final String name;
  final String emoji;

  /// 섹션 내 순서 (plan 섹션 / ref 섹션 각각 0..n-1)
  final int order;

  /// plan/ref 구분
  final CategoryKind kind;

  /// plan에서만 사용: 일일 예산(원)
  final int? dailyAmount;

  const CategoryEditItem({
    required this.categoryKey,
    required this.name,
    required this.emoji,
    required this.order,
    required this.kind,
    this.dailyAmount,
  });

  bool get isPlan => kind == CategoryKind.plan;
  bool get isRef => kind == CategoryKind.ref;

  CategoryEditItem copyWith({
    String? categoryKey,
    String? name,
    String? emoji,
    int? order,
    CategoryKind? kind,
    int? dailyAmount,
    bool clearDailyAmount = false,
  }) {
    return CategoryEditItem(
      categoryKey: categoryKey ?? this.categoryKey,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      order: order ?? this.order,
      kind: kind ?? this.kind,
      dailyAmount: clearDailyAmount ? null : (dailyAmount ?? this.dailyAmount),
    );
  }

  /// 저장 직전 validate용
  String? validate() {
    if (categoryKey.trim().isEmpty) return 'categoryKey가 비어있어요';
    if (name.trim().isEmpty) return '카테고리 이름이 비어있어요';
    if (isPlan) {
      final a = dailyAmount;
      if (a == null) return '플랜 카테고리는 금액이 필요해요';
      if (a < 1) return '플랜 카테고리 금액은 1원 이상이어야 해요';
    }
    return null;
  }
}

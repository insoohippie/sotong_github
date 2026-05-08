// lib/model/report/report_models.dart
import 'package:flutter/foundation.dart';

enum ReportRangeType { weekly, monthly }

@immutable
class ReportRange {
  final DateTime start; // inclusive
  final DateTime end; // inclusive

  const ReportRange({
    required this.start,
    required this.end,
  });

  @override
  String toString() => 'ReportRange(${start.toIso8601String()} ~ ${end.toIso8601String()})';
}

@immutable
class ReportCategoryBudgetRow {
  /// 불변 카테고리 키 (ex: 'cat_xxx', 'etc')
  final String categoryKey;

  /// 표시명
  final String name;

  /// 표시 이모지
  final String emoji;

  /// 계획/예산 금액
  final int planned;

  /// 실제 소비 금액
  final int spent;

  /// 총소비 막대 여부(굵게)
  final bool isTotal;

  const ReportCategoryBudgetRow({
    required this.categoryKey,
    required this.name,
    required this.emoji,
    required this.planned,
    required this.spent,
    this.isTotal = false,
  });
}

@immutable
class ReportCategoryBudgetChart {
  final ReportRange range;
  final List<ReportCategoryBudgetRow> rows;

  const ReportCategoryBudgetChart({
    required this.range,
    required this.rows,
  });
}
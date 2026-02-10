import 'package:flutter/material.dart';

import '../../../../model/category/category_edit_item.dart';
import '../../../../model/category/ref_category_item.dart';
import '../../../../view_model/category/category_edit_view_model.dart';

import 'category_plan_progress_box.dart';
import 'category_edit_lists_widget.dart';

class CategoryListsSection extends StatelessWidget {
  const CategoryListsSection({
    super.key,
    required this.vm,
    this.onTapEditName,
    this.onTapEditAmount,
    this.onMoveRefToPlanRequested, // ✅ Page와 이름 일치
    this.onAddPlan,
    this.onAddRef,
  });

  final CategoryEditViewModel vm;

  final void Function(CategoryEditItem item, bool isPlan)? onTapEditName;
  final void Function(CategoryEditItem item)? onTapEditAmount;
  final void Function(CategoryEditItem item, int targetIndex)? onMoveRefToPlanRequested;

  final VoidCallback? onAddPlan;
  final VoidCallback? onAddRef;

  int _calcDailySum(List<CategoryEditItem> planList) {
    return planList.fold<int>(0, (sum, c) => sum + (c.dailyAmount ?? 0));
  }

  DateTime? _calcReachDate(int dailySum, int targetAmount) {
    if (dailySum <= 0 || targetAmount <= 0) return null;
    final daysToReach = (targetAmount / dailySum).ceil();
    return DateTime.now().add(Duration(days: daysToReach));
  }

  @override
  Widget build(BuildContext context) {
    final planList = vm.draftPlan;

    // ✅ ref 하드코딩 (원하면 여기만 나중에 VM 연결)
    const refList = <RefCategoryItem>[
      RefCategoryItem(categoryKey: 'demo_food', name: '식비', emoji: '🍽️', order: 0),
      RefCategoryItem(categoryKey: 'demo_cafe', name: '카페', emoji: '☕', order: 1),
    ];

    final dailySum = _calcDailySum(planList);
    final reachDate = _calcReachDate(dailySum, vm.targetAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryEditListsWidget(
          planItems: planList,
          refItems: refList,

          // plan callbacks
          onTapEditName: (item, isPlan) => onTapEditName?.call(item, isPlan),
          onTapEditAmount: (item) => onTapEditAmount?.call(item),
          onDeletePlan: (item) => vm.draftDelete(item.categoryKey),
          onReorderPlan: (oldIndex, newIndex) => vm.draftReorderPlan(oldIndex, newIndex),

          // add
          onAddPlan: onAddPlan ?? () {},
          onAddRef: onAddRef ?? () {},

          // ref->plan 요청(지금은 ref 하드코딩이라 실제론 안 쓰는 수준)
          onMoveRefToPlanRequested: (item, targetIndex) {
            onMoveRefToPlanRequested?.call(item, targetIndex);
          },
        ),

        CategoryPlanProgressBox(
          dailyLimitSum: dailySum,
          reachDate: reachDate,
        ),
      ],
    );
  }
}

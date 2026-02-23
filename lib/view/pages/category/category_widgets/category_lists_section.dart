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
    this.onTapEditNamePlan,
    this.onTapEditAmountPlan,
    this.onTapEditNameRef,
    this.onAddPlan,
    this.onAddRef,
  });

  final CategoryEditViewModel vm;

  // plan
  final void Function(CategoryEditItem item)? onTapEditNamePlan;
  final void Function(CategoryEditItem item)? onTapEditAmountPlan;

  // ref
  final void Function(RefCategoryItem item)? onTapEditNameRef;

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
    final refList = vm.draftRef;

    final dailySum = _calcDailySum(planList);
    final reachDate = _calcReachDate(dailySum, vm.targetAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ 맨 위
        CategoryPlanProgressBox(
          dailyLimitSum: dailySum,
          reachDate: reachDate,
        ),

        CategoryEditListsWidget(
          planItems: planList,
          refItems: refList,

          // plan actions
          onTapEditNamePlan: (item) => onTapEditNamePlan?.call(item),
          onTapEditAmountPlan: (item) => onTapEditAmountPlan?.call(item),
          onDeletePlan: (item) => vm.draftDeletePlan(item.categoryKey),
          onReorderPlanByKeys: (keys) => vm.draftReorderPlanByKeys(keys),
          onAddPlan: onAddPlan ?? () {},

          // ref actions
          onTapEditNameRef: (item) => onTapEditNameRef?.call(item),
          onDeleteRef: (item) => vm.draftRemoveRefByKey(item.categoryKey),
          onReorderRefByKeys: (keys) => vm.draftReorderRefByKeys(keys),
          onAddRef: onAddRef ?? () {},
        ),
      ],
    );
  }
}

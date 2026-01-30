import 'package:flutter/material.dart';

import '../../../../model/category/category_snapshot_item.dart';
import '../../../../view_model/category/category_edit_view_model.dart'; // ✅ 변경
import 'category_plan_progress_box.dart';
import 'category_edit_lists_widget.dart';

class CategoryListsSection extends StatelessWidget {
  final CategoryEditViewModel vm; // ✅ 변경

  final void Function(CategorySnapshotItem item, bool isPlan)? onTapEditName;
  final void Function(CategorySnapshotItem item)? onTapEditAmount;

  final void Function(CategorySnapshotItem item, int targetIndex)?
  onMoveRefToPlanRequested;

  final VoidCallback? onAddPlan;
  final VoidCallback? onAddRef;

  const CategoryListsSection({
    super.key,
    required this.vm,
    this.onTapEditName,
    this.onTapEditAmount,
    this.onMoveRefToPlanRequested,
    this.onAddPlan,
    this.onAddRef,
  });

  int _calcDailySum(List<CategorySnapshotItem> planList) {
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
        CategoryEditListsWidget(
          planItems: planList,
          refItems: refList,
          onTapEditName: (item, isPlan) {
            if (onTapEditName != null) {
              onTapEditName!(item, isPlan);
              return;
            }
          },
          onTapEditAmount: (item) {
            if (onTapEditAmount != null) {
              onTapEditAmount!(item);
            }
          },
          onDelete: (item, wasPlan) {
            vm.draftDelete(item.categoryId);
          },
          onReorderPlan: (oldIndex, newIndex) {
            vm.draftReorderPlan(oldIndex, newIndex);
          },
          onReorderRef: (oldIndex, newIndex) {
            vm.draftReorderRef(oldIndex, newIndex);
          },
          onMoveRefToPlanRequested: (item, targetIndex) {
            if (onMoveRefToPlanRequested != null) {
              onMoveRefToPlanRequested!(item, targetIndex);
              return;
            }
            vm.draftMoveRefToPlan(
              categoryId: item.categoryId,
              newIndex: targetIndex,
              dailyAmount: 0,
            );
          },
          onMovePlanToRef: (item, targetIndex) {
            vm.draftMovePlanToRef(
              categoryId: item.categoryId,
              newIndex: targetIndex,
            );
          },
          onAddPlan: onAddPlan ?? () {},
          onAddRef: onAddRef ?? () {},
        ),
        CategoryPlanProgressBox(
          dailyLimitSum: dailySum,
          reachDate: reachDate,
        ),
      ],
    );
  }
}

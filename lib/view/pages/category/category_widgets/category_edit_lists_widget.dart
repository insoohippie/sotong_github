import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import '../../../../component/buttons/small_rounded_button.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_text_styles.dart';

import '../../../../model/category/category_edit_item.dart';
import '../../../../model/category/ref_category_item.dart';

class CategoryEditListsWidget extends StatelessWidget {
  const CategoryEditListsWidget({
    super.key,
    required this.planItems,
    required this.refItems,

    // plan
    required this.onTapEditNamePlan,
    required this.onTapEditAmountPlan,
    required this.onDeletePlan,
    required this.onReorderPlanByKeys,
    required this.onAddPlan,

    // ref
    required this.onTapEditNameRef,
    required this.onDeleteRef,
    required this.onReorderRefByKeys,
    required this.onAddRef,
  });

  final List<CategoryEditItem> planItems;
  final List<RefCategoryItem> refItems;

  // plan callbacks
  final void Function(CategoryEditItem item) onTapEditNamePlan;
  final void Function(CategoryEditItem item) onTapEditAmountPlan;
  final void Function(CategoryEditItem item) onDeletePlan;
  final void Function(List<String> newOrderKeys) onReorderPlanByKeys;
  final VoidCallback onAddPlan;

  // ref callbacks
  final void Function(RefCategoryItem item) onTapEditNameRef;
  final void Function(RefCategoryItem item) onDeleteRef;
  final void Function(List<String> newOrderKeys) onReorderRefByKeys;
  final VoidCallback onAddRef;

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    )}원';
  }

  /// ✅ index 기반(old/new)을 "key 배열"로 변환해서 VM에 전달
  List<String> _reorderKeys({
    required List<String> keys,
    required int oldIndex,
    required int newIndex,
  }) {
    final list = List<String>.from(keys);
    if (oldIndex < 0 || oldIndex >= list.length) return list;
    if (newIndex < 0 || newIndex > list.length) return list;

    if (oldIndex < newIndex) newIndex -= 1;
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    return list;
  }

  // =========================
  // Tiles
  // =========================
  Widget _planTile(BuildContext context, CategoryEditItem item, int index) {
    return Dismissible(
      key: ValueKey('plan-dismiss-${item.categoryKey}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDeletePlan(item),
      child: Container(
        key: ValueKey('plan-tile-${item.categoryKey}'), // ✅ Reorderable 안정 key
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ReorderableDragStartListener(
            index: index,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_handle, color: AppColors.subText),
                const SizedBox(width: 8),
                Text(item.emoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTapEditNamePlan(item),
                  child: Text(item.name, style: AppTextStyles.paragraph),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => onTapEditAmountPlan(item),
                child: Text(
                  _formatAmount(item.dailyAmount ?? 0),
                  style: AppTextStyles.paragraph.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _refTile(BuildContext context, RefCategoryItem item, int index) {
    return Dismissible(
      key: ValueKey('ref-dismiss-${item.categoryKey}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDeleteRef(item),
      child: Container(
        key: ValueKey('ref-tile-${item.categoryKey}'), // ✅ Reorderable 안정 key
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ReorderableDragStartListener(
            index: index,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_handle, color: AppColors.subText),
                const SizedBox(width: 8),
                Text(item.emoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          title: GestureDetector(
            onTap: () => onTapEditNameRef(item),
            child: Text(item.name, style: AppTextStyles.paragraph),
          ),
        ),
      ),
    );
  }

  // =========================
  // Sections
  // =========================
  Widget _buildPlanSection(BuildContext context) {
    final items = planItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '플랜 카테고리',
                style: AppTextStyles.subtext.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '일일 소비 예산이 있는 카테고리입니다. (레포트 축에 사용)',
                style: AppTextStyles.subtext.copyWith(
                  color: AppColors.subText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Text(
              '카테고리가 없습니다. 아래에서 추가해보세요.',
              style: AppTextStyles.subtext.copyWith(color: AppColors.subText),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false, // ✅ 핸들 드래그만
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              final keys = items.map((e) => e.categoryKey).toList();
              final newKeys = _reorderKeys(keys: keys, oldIndex: oldIndex, newIndex: newIndex);
              onReorderPlanByKeys(newKeys);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return _planTile(context, item, index);
            },
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: SmallRoundedButton(
              text: '추가',
              backgroundColor: AppColors.greyBackground,
              textColor: AppColors.text,
              onPressed: onAddPlan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefSection(BuildContext context) {
    final items = refItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '참고 카테고리',
                style: AppTextStyles.subtext.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '자주 쓰는 카테고리를 모아둘 수 있습니다.',
                style: AppTextStyles.subtext.copyWith(
                  color: AppColors.subText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Text(
              '참고 카테고리가 없습니다.',
              style: AppTextStyles.subtext.copyWith(color: AppColors.subText),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              final keys = items.map((e) => e.categoryKey).toList();
              final newKeys = _reorderKeys(keys: keys, oldIndex: oldIndex, newIndex: newIndex);
              onReorderRefByKeys(newKeys);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return _refTile(context, item, index);
            },
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: SmallRoundedButton(
              text: '추가',
              backgroundColor: AppColors.greyBackground,
              textColor: AppColors.text,
              onPressed: onAddRef,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPlanSection(context),
        const Divider(height: 1, thickness: 1),
        _buildRefSection(context),
      ],
    );
  }
}

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_text_styles.dart';

import '../../../../model/category/category_edit_item.dart';
import '../../../../model/category/ref_category_item.dart';

class _DragPayload {
  final CategoryEditItem item;
  const _DragPayload({required this.item});
}

class CategoryEditListsWidget extends StatefulWidget {
  const CategoryEditListsWidget({
    super.key,
    required this.planItems,
    required this.refItems,

    required this.onTapEditName,
    required this.onTapEditAmount,
    required this.onDeletePlan,
    required this.onReorderPlan,

    required this.onAddPlan,
    required this.onAddRef,

    // ref->plan “요청”만(지금 ref 하드코딩이라 실사용 거의 없음)
    required this.onMoveRefToPlanRequested,
  });

  final List<CategoryEditItem> planItems;
  final List<RefCategoryItem> refItems;

  final void Function(CategoryEditItem item, bool isPlan) onTapEditName;
  final void Function(CategoryEditItem item) onTapEditAmount;

  final void Function(CategoryEditItem item) onDeletePlan;
  final void Function(int oldIndex, int newIndex) onReorderPlan;

  final VoidCallback onAddPlan;
  final VoidCallback onAddRef;

  final void Function(CategoryEditItem item, int targetIndex) onMoveRefToPlanRequested;

  @override
  State<CategoryEditListsWidget> createState() => _CategoryEditListsWidgetState();
}

class _CategoryEditListsWidgetState extends State<CategoryEditListsWidget> {
  bool _isDragging = false;

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    )}원';
  }

  Widget _itemDropZone({
    required int targetIndex,
    required void Function(_DragPayload data) onAccept,
  }) {
    return DragTarget<_DragPayload>(
      onWillAccept: (data) => data != null,
      onAccept: onAccept,
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        final shouldShow = highlighted || _isDragging;
        return Container(
          height: highlighted ? 12 : (shouldShow ? 6 : 4),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.primary
                : (shouldShow ? Colors.grey.withOpacity(0.25) : Colors.transparent),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  Widget _planTile({required CategoryEditItem item}) {
    final amount = item.dailyAmount ?? 0;

    return Dismissible(
      key: ValueKey('plan-${item.categoryKey}'),
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
      onDismissed: (_) => widget.onDeletePlan(item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: LongPressDraggable<_DragPayload>(
            data: _DragPayload(item: item),
            onDragStarted: () => setState(() => _isDragging = true),
            onDragEnd: (_) => setState(() => _isDragging = false),
            feedback: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: 0.9,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 48,
                  child: _dragFeedbackTile(item: item),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.drag_handle, color: AppColors.subText),
                  const SizedBox(width: 8),
                  Text(item.emoji, style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
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
                  onTap: () => widget.onTapEditName(item, true),
                  child: Text(item.name, style: AppTextStyles.paragraph),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => widget.onTapEditAmount(item),
                child: Text(
                  _formatAmount(amount),
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

  Widget _dragFeedbackTile({required CategoryEditItem item}) {
    final amount = item.dailyAmount ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: AppColors.subText),
            const SizedBox(width: 8),
            Text(item.emoji, style: const TextStyle(fontSize: 20)),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(item.name, style: AppTextStyles.paragraph)),
            Text(
              _formatAmount(amount),
              style: AppTextStyles.paragraph.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSection() {
    final items = widget.planItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
              '플랜 카테고리가 없습니다.',
              style: AppTextStyles.subtext.copyWith(color: AppColors.subText),
            ),
          )
        else ...[
          for (int i = 0; i < items.length; i++) ...[
            _itemDropZone(
              targetIndex: i,
              onAccept: (data) {
                final oldIndex =
                items.indexWhere((e) => e.categoryKey == data.item.categoryKey);
                if (oldIndex == -1 || oldIndex == i) return;
                widget.onReorderPlan(oldIndex, i);
              },
            ),
            _planTile(item: items[i]),
          ],
          _itemDropZone(
            targetIndex: items.length,
            onAccept: (data) {
              final oldIndex =
              items.indexWhere((e) => e.categoryKey == data.item.categoryKey);
              if (oldIndex == -1 || oldIndex == items.length) return;
              widget.onReorderPlan(oldIndex, items.length);
            },
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: OutlinedButton.icon(
              onPressed: widget.onAddPlan,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                '추가',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefSectionHardcoded() {
    final demo = widget.refItems;

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
                '자주 쓰는 카테고리를 모아둘 수 있습니다. (현재는 준비중)',
                style: AppTextStyles.subtext.copyWith(
                  color: AppColors.subText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        for (final r in demo)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Text(r.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(r.name, style: AppTextStyles.paragraph),
              trailing: Text(
                '준비중',
                style: AppTextStyles.subtext.copyWith(color: AppColors.subText),
              ),
              // 나중에 ref -> plan 이동 기능 생기면 여기서 요청 가능
              onTap: () {
                // 예: 특정 targetIndex로 옮기고 싶으면 0/끝 등으로 호출
                // 지금은 “준비중”이므로 실제로는 안 쓰는 흐름
              },
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                '추가 (준비중)',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
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
        _buildPlanSection(),
        const Divider(height: 1, thickness: 1),
        _buildRefSectionHardcoded(),
      ],
    );
  }
}

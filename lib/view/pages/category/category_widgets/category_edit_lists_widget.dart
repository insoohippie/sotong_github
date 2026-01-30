import 'package:flutter/material.dart';

import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_text_styles.dart';
import '../../../../model/category/category_snapshot_item.dart';

/// 드래그 payload
class _DragPayload {
  final CategorySnapshotItem item;
  final bool fromPlan;
  const _DragPayload({required this.item, required this.fromPlan});
}

class CategoryEditListsWidget extends StatefulWidget {
  const CategoryEditListsWidget({
    super.key,
    required this.planItems,
    required this.refItems,

    // ----- actions (부모에서 vm 호출 or 모달 띄우기) -----
    required this.onTapEditName,
    required this.onTapEditAmount, // plan only
    required this.onDelete,

    /// ✅ 섹션 내 reorder
    required this.onReorderPlan,
    required this.onReorderRef,

    /// ✅ 섹션 간 이동
    /// - Ref -> Plan : amount 입력이 필요하므로, 부모가 amount 모달 띄운 뒤 확정 시 실제 이동 적용
    required this.onMoveRefToPlanRequested,

    /// - Plan -> Ref : 바로 이동 가능(금액 제거)
    required this.onMovePlanToRef,

    /// ✅ add 버튼(필요하면 사용)
    required this.onAddPlan,
    required this.onAddRef,

    // 드롭존 UI
    this.showDropZones = true,
  });

  final List<CategorySnapshotItem> planItems;
  final List<CategorySnapshotItem> refItems;

  final void Function(CategorySnapshotItem item, bool isPlan) onTapEditName;
  final void Function(CategorySnapshotItem item) onTapEditAmount;
  final void Function(CategorySnapshotItem item, bool wasPlan) onDelete;

  final void Function(int oldIndex, int newIndex) onReorderPlan;
  final void Function(int oldIndex, int newIndex) onReorderRef;

  /// Ref -> Plan 이동은 “요청”만 보냄 (부모가 금액 모달 처리)
  final void Function(CategorySnapshotItem item, int targetIndex)
  onMoveRefToPlanRequested;

  /// Plan -> Ref 이동은 즉시 실행
  final void Function(CategorySnapshotItem item, int targetIndex)
  onMovePlanToRef;

  final VoidCallback onAddPlan;
  final VoidCallback onAddRef;

  final bool showDropZones;

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

  // =========================
  // Drop zone (between items)
  // =========================
  Widget _itemDropZone({
    required bool isPlanSection,
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

  // =========================
  // Drop zone (top/bottom)
  // =========================
  Widget _sectionDropZone({
    required bool toPlan,
    required void Function(_DragPayload data) onAccept,
  }) {
    if (!widget.showDropZones) return const SizedBox.shrink();

    return DragTarget<_DragPayload>(
      onWillAccept: (data) {
        if (data == null) return false;
        // toPlan 이면 fromPlan=false만 허용 / toRef 이면 fromPlan=true만 허용
        return toPlan ? !data.fromPlan : data.fromPlan;
      },
      onAccept: onAccept,
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        if (!highlighted) return const SizedBox(height: 8);

        return Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Text(
              toPlan ? '플랜 카테고리로 이동' : '참고 카테고리로 이동',
              style: AppTextStyles.subtext.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // Item tile
  // =========================
  Widget _categoryTile({
    required CategorySnapshotItem item,
    required bool isPlan,
  }) {
    return Dismissible(
      key: ValueKey('${isPlan ? "plan" : "ref"}-${item.categoryId}'),
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
      onDismissed: (_) => widget.onDelete(item, isPlan),
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
            data: _DragPayload(item: item, fromPlan: isPlan),
            onDragStarted: () => setState(() => _isDragging = true),
            onDragEnd: (_) => setState(() => _isDragging = false),
            feedback: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: 0.9,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 48,
                  child: _dragFeedbackTile(item: item, isPlan: isPlan),
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
                  Text(item.emoji ?? '💰', style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_handle, color: AppColors.subText),
                const SizedBox(width: 8),
                Text(item.emoji ?? '💰', style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTapEditName(item, isPlan),
                  child: Text(item.name, style: AppTextStyles.paragraph),
                ),
              ),
              if (isPlan) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => widget.onTapEditAmount(item),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragFeedbackTile({
    required CategorySnapshotItem item,
    required bool isPlan,
  }) {
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
            Text(item.emoji ?? '💰', style: const TextStyle(fontSize: 20)),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(item.name, style: AppTextStyles.paragraph)),
            if (isPlan)
              Text(
                _formatAmount(item.dailyAmount ?? 0),
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

  // =========================
  // Section builder
  // =========================
  Widget _buildSection({
    required String title,
    required String desc,
    required bool isPlan,
    required List<CategorySnapshotItem> items,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.subtext.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: AppTextStyles.subtext.copyWith(
                  color: AppColors.subText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // section drop zone (top)
        _sectionDropZone(
          toPlan: isPlan,
          onAccept: (data) {
            if (isPlan) {
              // ref -> plan (요청)
              widget.onMoveRefToPlanRequested(data.item, 0);
            } else {
              // plan -> ref (즉시)
              widget.onMovePlanToRef(data.item, 0);
            }
          },
        ),

        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Text(
              '카테고리가 없습니다. 아래에서 추가하거나 드래그로 옮겨보세요.',
              style: AppTextStyles.subtext.copyWith(color: AppColors.subText),
            ),
          )
        else ...[
          // items with between drop zones
          for (int i = 0; i < items.length; i++) ...[
            _itemDropZone(
              isPlanSection: isPlan,
              targetIndex: i,
              onAccept: (data) {
                final fromPlan = data.fromPlan;
                final sameSection = (fromPlan == isPlan);

                if (sameSection) {
                  // reorder inside section
                  final oldIndex = items.indexWhere((e) => e.categoryId == data.item.categoryId);
                  if (oldIndex == -1 || oldIndex == i) return;
                  if (isPlan) {
                    widget.onReorderPlan(oldIndex, i);
                  } else {
                    widget.onReorderRef(oldIndex, i);
                  }
                } else {
                  // move across
                  if (isPlan) {
                    // ref -> plan (request)
                    widget.onMoveRefToPlanRequested(data.item, i);
                  } else {
                    // plan -> ref (immediate)
                    widget.onMovePlanToRef(data.item, i);
                  }
                }
              },
            ),
            _categoryTile(item: items[i], isPlan: isPlan),
          ],

          // bottom drop zone
          _itemDropZone(
            isPlanSection: isPlan,
            targetIndex: items.length,
            onAccept: (data) {
              final fromPlan = data.fromPlan;
              final sameSection = (fromPlan == isPlan);

              if (sameSection) {
                final oldIndex = items.indexWhere((e) => e.categoryId == data.item.categoryId);
                if (oldIndex == -1 || oldIndex == items.length) return;
                if (isPlan) {
                  widget.onReorderPlan(oldIndex, items.length);
                } else {
                  widget.onReorderRef(oldIndex, items.length);
                }
              } else {
                if (isPlan) {
                  widget.onMoveRefToPlanRequested(data.item, items.length);
                } else {
                  widget.onMovePlanToRef(data.item, items.length);
                }
              }
            },
          ),
        ],

        // section drop zone (bottom)
        _sectionDropZone(
          toPlan: isPlan,
          onAccept: (data) {
            if (isPlan) {
              widget.onMoveRefToPlanRequested(data.item, items.length);
            } else {
              widget.onMovePlanToRef(data.item, items.length);
            }
          },
        ),

        // add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                '추가',
                style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
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
        _buildSection(
          title: '플랜 카테고리',
          desc: '일일 소비 예산이 있는 카테고리입니다. (레포트 축에 사용)',
          isPlan: true,
          items: widget.planItems,
          onAdd: widget.onAddPlan,
        ),
        const Divider(height: 1, thickness: 1),
        _buildSection(
          title: '참고 카테고리',
          desc: '자주 쓰는 카테고리를 모아둘 수 있습니다.',
          isPlan: false,
          items: widget.refItems,
          onAdd: widget.onAddRef,
        ),
      ],
    );
  }
}

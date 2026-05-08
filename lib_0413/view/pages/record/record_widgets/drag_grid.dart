import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

class DragGrid<T> extends StatelessWidget {
  const DragGrid({
    super.key,
    required this.itemList,
    required this.itemBuilder,
    required this.sliverGridDelegate,
    required this.itemKey,

    this.padding,
    this.onReorder,

    // ✅ 추가: 정렬 가능 여부 / 드래그 즉시 시작 여부
    this.reorderEnabled = true,
    this.dragImmediately = false,

    // 기존 옵션 유지
    this.enableLongPress = true,
    this.longPressDelay = const Duration(milliseconds: 250),
    this.reorderableKey,
  });

  final List<T> itemList;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate sliverGridDelegate;
  final EdgeInsets? padding;
  final void Function(List<T> newList)? onReorder;

  // 기존
  final bool enableLongPress;
  final Duration longPressDelay;
  final Key? reorderableKey;

  final Key Function(T item) itemKey;

  // ✅ 추가
  final bool reorderEnabled;
  final bool dragImmediately;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (int i = 0; i < itemList.length; i++)
        KeyedSubtree(
          key: itemKey(itemList[i]),
          child: itemBuilder(context, itemList[i], i),
        ),
    ];

    // ✅ 편집모드(true)면: 즉시 드래그(dragImmediately=true) → enableLongPress=false
    // ✅ 편집모드(false)면: 사실상 드래그 잠금(초장기 delay + onReorder 무시)
    final effectiveEnableLongPress = reorderEnabled ? !dragImmediately : true;
    final effectiveDelay =
    reorderEnabled ? (dragImmediately ? Duration.zero : longPressDelay) : const Duration(days: 365);

    Widget grid = ReorderableBuilder(
      key: reorderableKey,
      enableLongPress: effectiveEnableLongPress,
      longPressDelay: effectiveDelay,
      dragChildBoxDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [],
      ),
      onReorder: (ReorderedListFunction f) {
        // ✅ 잠금 상태면 reorder 자체를 무시
        if (!reorderEnabled) return;

        final reordered = f(List<T>.from(itemList));
        onReorder?.call(List<T>.from(reordered));
      },
      builder: (reorderedChildren) {
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: sliverGridDelegate,
          children: reorderedChildren,
        );
      },
      children: children,
    );

    if (padding != null) {
      grid = Padding(padding: padding!, child: grid);
    }
    return grid;
  }
}
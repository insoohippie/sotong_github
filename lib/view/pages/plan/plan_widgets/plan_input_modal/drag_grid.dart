import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

/// 드래그 시 다른 아이템이 자석처럼 밀려나는 리오더 애니메이션이 적용된 그리드.
/// [itemList] 순서가 바뀌면 [onReorder]로 새 리스트를 전달하고, 부모에서 setState로 반영해야 함.
/// [reorderableKey]: 순서 변경 시 바꿔서 넘기면 ReorderableBuilder가 새로 생성되어, 모든 칩이 다시 드래그 가능해짐.
class DragGrid<T> extends StatelessWidget {
  const DragGrid({
    super.key,
    required this.itemList,
    required this.itemBuilder,
    required this.sliverGridDelegate,
    this.padding,
    this.onReorder,
    this.enableLongPress = true,
    this.longPressDelay = const Duration(milliseconds: 400),
    this.reorderableKey,
  });

  final List<T> itemList;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate sliverGridDelegate;
  final EdgeInsets? padding;
  final void Function(List<T> newList)? onReorder;
  final bool enableLongPress;
  final Duration longPressDelay;

  /// 순서가 바뀔 때마다 다른 키를 넘기면(예: ValueKey(itemList.join(','))) 모든 칩이 계속 드래그 가능.
  final Key? reorderableKey;

  @override
  Widget build(BuildContext context) {
    final children = itemList.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return KeyedSubtree(
        key: ValueKey(item),
        child: itemBuilder(context, item, index),
      );
    }).toList();

    Widget grid = ReorderableBuilder(
      key: reorderableKey,
      enableLongPress: enableLongPress,
      longPressDelay: longPressDelay,
      dragChildBoxDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [], // 드래그 시 그림자 제거
      ),
      onReorder: (ReorderedListFunction f) {
        final newList = f(itemList) as List<T>;
        onReorder?.call(newList);
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

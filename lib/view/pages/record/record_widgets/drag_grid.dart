import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

class DragGrid<T> extends StatelessWidget {
  const DragGrid({
    super.key,
    required this.itemList,
    required this.itemBuilder,
    required this.sliverGridDelegate,
    required this.itemKey, // ✅ 추가
    this.padding,
    this.onReorder,
    this.enableLongPress = true,
    this.longPressDelay = const Duration(milliseconds: 250),
    this.reorderableKey,
  });

  final List<T> itemList;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate sliverGridDelegate;
  final EdgeInsets? padding;
  final void Function(List<T> newList)? onReorder;

  final bool enableLongPress;
  final Duration longPressDelay;
  final Key? reorderableKey;

  final Key Function(T item) itemKey; // ✅ 추가

  @override
  Widget build(BuildContext context) {
    final children = [
      for (int i = 0; i < itemList.length; i++)
        KeyedSubtree(
          key: itemKey(itemList[i]), // ✅ index 말고 item 고유키
          child: itemBuilder(context, itemList[i], i),
        ),
    ];

    Widget grid = ReorderableBuilder(
      key: reorderableKey,
      enableLongPress: enableLongPress,
      longPressDelay: longPressDelay,
      dragChildBoxDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [],
      ),
      onReorder: (ReorderedListFunction f) {
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

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../../component/theme/app_colors.dart';
import '../../../../model/category/category_edit_item.dart';
import '../../../../model/category/ref_category_item.dart';

class PlanCategoryEditTile extends StatelessWidget {
  const PlanCategoryEditTile({
    super.key,
    required this.item,
    required this.index,
    required this.formatAmount,
    required this.onDelete,
    required this.onTapEditName,
    required this.onTapEditAmount,
  });

  final CategoryEditItem item;
  final int index;
  final String Function(int amount) formatAmount;
  final VoidCallback onDelete;
  final VoidCallback onTapEditName;
  final VoidCallback onTapEditAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileBg = isDark ? theme.colorScheme.surface : Colors.white;
    final tileBorder = isDark ? theme.dividerColor : Colors.grey.shade200;
    final dragColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      key: key,
      child: Dismissible(
        key: ValueKey('plan-dismiss-${item.categoryKey}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tileBorder),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: ReorderableDragStartListener(
                index: index,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_handle, color: dragColor),
                    const SizedBox(width: 8),
                    Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onTapEditName,
                      child: Text(
                        item.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onTapEditAmount,
                    child: Text(
                      item.dailyAmount == null ? '-원' : formatAmount(item.dailyAmount!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RefCategoryEditTile extends StatelessWidget {
  const RefCategoryEditTile({
    super.key,
    required this.item,
    required this.index,
    required this.onDelete,
    required this.onTapEditName,
  });

  final RefCategoryItem item;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTapEditName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileBg = isDark ? theme.colorScheme.surface : Colors.white;
    final tileBorder = isDark ? theme.dividerColor : Colors.grey.shade200;
    final dragColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      key: key,
      child: Dismissible(
        key: ValueKey('ref-dismiss-${item.categoryKey}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tileBorder),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: ReorderableDragStartListener(
                index: index,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_handle, color: dragColor),
                    const SizedBox(width: 8),
                    Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onTapEditName,
                      child: Text(
                        item.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
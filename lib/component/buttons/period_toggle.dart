import 'package:flutter/material.dart';

class TwoOptionToggle extends StatelessWidget {
  const TwoOptionToggle({
    super.key,
    required this.labels, // 두 옵션
    required this.selected, // 현재 선택된 값
    required this.onChanged,
    this.width = 120,
    this.height = 34,
  }) : assert(labels.length == 2);

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;
  final double width;
  final double height;

  Alignment _alignmentForIndex(int index) {
    return index == 0 ? Alignment.centerLeft : Alignment.centerRight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackBg = isDark ? theme.colorScheme.surface : Colors.grey.shade100;
    final trackBorder = isDark ? theme.dividerColor : Colors.grey.shade300;
    final selectedBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.white;
    final selectedText = theme.colorScheme.onSurface;
    final unselectedText = theme.colorScheme.onSurfaceVariant;
    final selectedIndex = labels.indexOf(selected).clamp(0, 1);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trackBorder, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: _alignmentForIndex(selectedIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Container(
                width: (width - 6) / 2,
                decoration: BoxDecoration(
                  color: selectedBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(2, (index) {
              final label = labels[index];
              final isSelected = selected == label;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isSelected) return;
                    onChanged(label);
                  },
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? selectedText : unselectedText,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

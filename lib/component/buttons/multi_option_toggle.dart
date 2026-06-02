import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultiOptionToggle extends StatelessWidget {
  const MultiOptionToggle({
    super.key,
    required this.labels, // 2~N 옵션
    required this.selected, // 현재 선택된 값
    required this.onChanged,
    this.width = 320,
    this.height = 34,
    this.padding = const EdgeInsets.all(3),
    this.fontSize = 12,

    /// 선택된 옵션 배경(흰색 칩)의 너비 비율. 1.0 = 한 칸 전체, 0.85 = 칸의 85% (좌우 여백 생김)
    this.indicatorWidthRatio = 1.0,
  }) : assert(labels.length >= 2),
       assert(indicatorWidthRatio > 0 && indicatorWidthRatio <= 1.0);

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  final double width;
  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final double indicatorWidthRatio;

  Alignment _alignmentForIndex(int index, int count) {
    if (count <= 1) return Alignment.center;
    // -1.0 ~ 1.0 사이에 균등 분배
    final t = index / (count - 1); // 0..1
    final x = -1.0 + (2.0 * t); // -1..1
    return Alignment(x, 0);
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

    final count = labels.length;
    final idxRaw = labels.indexOf(selected);
    final selectedIndex = (idxRaw < 0) ? 0 : idxRaw;

    final innerWidth = width - padding.horizontal;
    final slotWidth = innerWidth / count;
    final indicatorWidth = slotWidth * indicatorWidthRatio.clamp(0.01, 1.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: trackBorder, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: _alignmentForIndex(selectedIndex, count),
            child: Padding(
              padding: padding,
              child: Container(
                width: indicatorWidth,
                height: height - padding.vertical,
                decoration: BoxDecoration(
                  color: selectedBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.10),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: List.generate(count, (i) {
              final label = labels[i];
              final isSelected = label == selected;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isSelected) return;
                    HapticFeedback.selectionClick();
                    onChanged(label);
                  },
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
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

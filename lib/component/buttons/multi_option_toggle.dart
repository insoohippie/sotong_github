import 'package:flutter/material.dart';

class MultiOptionToggle extends StatelessWidget {
  const MultiOptionToggle({
    super.key,
    required this.labels,       // 2~N 옵션
    required this.selected,     // 현재 선택된 값
    required this.onChanged,
    this.width = 320,
    this.height = 34,
    this.padding = const EdgeInsets.all(3),
  }) : assert(labels.length >= 2);

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  final double width;
  final double height;
  final EdgeInsets padding;

  Alignment _alignmentForIndex(int index, int count) {
    if (count <= 1) return Alignment.center;
    // -1.0 ~ 1.0 사이에 균등 분배
    final t = index / (count - 1);          // 0..1
    final x = -1.0 + (2.0 * t);            // -1..1
    return Alignment(x, 0);
  }

  @override
  Widget build(BuildContext context) {
    final count = labels.length;
    final idxRaw = labels.indexOf(selected);
    final selectedIndex = (idxRaw < 0) ? 0 : idxRaw;

    final innerWidth = width - padding.horizontal;
    final indicatorWidth = innerWidth / count;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[300]!, width: 1),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
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
                    onChanged(label);
                  },
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black87 : Colors.grey[600],
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

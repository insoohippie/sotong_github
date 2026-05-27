import 'package:flutter/material.dart';

class SelectableEmojiSelector extends StatelessWidget {
  final String label;
  final Widget emojiWidget;
  final bool selected;
  final VoidCallback onTap;

  final double size;
  final double radius;

  const SelectableEmojiSelector({
    super.key,
    required this.label,
    required this.emojiWidget,
    required this.selected,
    required this.onTap,
    this.size = 80.0,
    this.radius = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final circleColor = selected
        ? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEDEDED))
        : (isDark ? const Color(0xFF242424) : const Color(0xFFF3F4F6));
    final labelColor = selected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: circleColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: selected ? 1.2 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Center(child: emojiWidget),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

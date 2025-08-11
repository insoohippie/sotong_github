import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart'; // 텍스트 스타일 있다면

class SelectableEmojiSelector extends StatelessWidget {
  final String label;
  final Widget emojiWidget;
  final bool selected;
  final VoidCallback onTap;

  final double size;
  final double radius;

  const SelectableEmojiSelector({
    Key? key,
    required this.label,
    required this.emojiWidget,
    required this.selected,
    required this.onTap,
    this.size = 80.0,
    this.radius = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
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
              color: selected ? Colors.black : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

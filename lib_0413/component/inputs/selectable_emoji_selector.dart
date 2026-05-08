import 'package:flutter/material.dart';

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
              color: selected ? Colors.white : Colors.white10,
              // color: selected ? Colors.white10 : Colors.white,
              // color: selected ? Colors.white : Colors.white,
              borderRadius: BorderRadius.circular(radius),
              // border: ,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
              color: selected ? Colors.black : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

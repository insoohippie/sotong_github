import 'package:flutter/material.dart';

class TypingIndicatorWidget extends StatelessWidget {
  const TypingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _TypingDot(),
                SizedBox(width: 4),
                _TypingDot(),
                SizedBox(width: 4),
                _TypingDot(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF9CA3AF),
        shape: BoxShape.circle,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MonthSelectorRow extends StatelessWidget {
  const MonthSelectorRow({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPrev,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.chevron_left, size: 20, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${month}월',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onNext,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.chevron_right, size: 20, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

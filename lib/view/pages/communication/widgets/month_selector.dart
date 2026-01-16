import 'package:flutter/material.dart';

class MonthSelector extends StatelessWidget {
  final int month;
  final ValueChanged<int> onChanged;

  const MonthSelector({
    super.key,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(Icons.chevron_left, () {
          final m = month == 1 ? 12 : month - 1;
          onChanged(m);
        }),
        const SizedBox(width: 10),
        Text(
          '$month월',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        _arrow(Icons.chevron_right, () {
          final m = month == 12 ? 1 : month + 1;
          onChanged(m);
        }),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: Colors.grey[800]),
      ),
    );
  }
}

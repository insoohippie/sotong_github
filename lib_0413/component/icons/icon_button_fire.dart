import 'package:flutter/material.dart';

class FireIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;

  const FireIconButton({super.key, required this.onTap, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: isActive ? Colors.orange : Colors.grey[300],
        radius: 24,
        child: const Icon(Icons.local_fire_department, color: Colors.white),
      ),
    );
  }
}

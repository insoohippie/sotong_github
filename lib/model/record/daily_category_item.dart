import 'package:flutter/material.dart';

class DailyCategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  final bool enabled;

  const DailyCategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    this.enabled = true,
  });

  DailyCategoryItem copyWith({
    String? name,
    IconData? icon,
    Color? color,
    bool? enabled,
  }) {
    return DailyCategoryItem(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      enabled: enabled ?? this.enabled,
    );
  }
}

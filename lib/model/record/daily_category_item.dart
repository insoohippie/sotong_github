import 'package:flutter/foundation.dart';

@immutable
class DailyCategoryItem {
  final String name;
  final String emoji;   // 간단히 이모지 문자열로 표현
  final bool enabled;

  const DailyCategoryItem({
    required this.name,
    required this.emoji,
    this.enabled = true,
  });

  DailyCategoryItem copyWith({
    String? name,
    String? emoji,
    bool? enabled,
  }) {
    return DailyCategoryItem(
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      enabled: enabled ?? this.enabled,
    );
  }
}

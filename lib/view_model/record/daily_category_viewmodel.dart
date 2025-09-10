import 'package:flutter/material.dart';
import '../../model/record/daily_category_item.dart';

class DailyCategoryViewModel extends ChangeNotifier {
  DailyCategoryViewModel({List<DailyCategoryItem>? initial}) {
    if (initial != null && initial.isNotEmpty) {
      _items = List<DailyCategoryItem>.from(initial);
    } else {
      // 기본 프리셋
      _items = const [
        DailyCategoryItem(name: '식비', emoji: '🍽️'),
        DailyCategoryItem(name: '교통', emoji: '🚌'),
        DailyCategoryItem(name: '카페', emoji: '☕️'),
        DailyCategoryItem(name: '취미', emoji: '🎮'),
      ];
    }
  }

  late List<DailyCategoryItem> _items;

  List<DailyCategoryItem> get items => List.unmodifiable(_items);
  List<DailyCategoryItem> get enabledItems =>
      _items.where((e) => e.enabled).toList(growable: false);

  /// 이름으로 카테고리 찾기 (없으면 null)
  DailyCategoryItem? findByName(String name) {
    try {
      return _items.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 추가 (동명이면 덮어쓰기)
  void addCategory(String name, String emoji) {
    final n = name.trim();
    if (n.isEmpty) return;

    final idx = _items.indexWhere((e) => e.name == n);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(emoji: emoji, enabled: true);
    } else {
      _items.add(DailyCategoryItem(name: n, emoji: emoji, enabled: true));
    }
    notifyListeners();
  }

  /// 활성/비활성 토글
  void setEnabled(int index, bool enabled) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = _items[index].copyWith(enabled: enabled);
    notifyListeners();
  }

  /// 삭제
  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  /// 이름/이모지 수정
  void updateAt(int index, {String? name, String? emoji}) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = _items[index].copyWith(name: name, emoji: emoji);
    notifyListeners();
  }
}

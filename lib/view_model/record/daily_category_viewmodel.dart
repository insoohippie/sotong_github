import 'package:flutter/material.dart';
import '../../model/record/daily_category_item.dart';

class DailyCategoryViewModel extends ChangeNotifier {
  DailyCategoryViewModel({List<DailyCategoryItem>? initial}) {
    if (initial != null && initial.isNotEmpty) {
      _items = List<DailyCategoryItem>.from(initial);
    } else {
      // 기본 프리셋
      _items = <DailyCategoryItem>[
        const DailyCategoryItem(name: '식비', icon: Icons.restaurant_rounded, color: Color(0xFFFFE082)),
        const DailyCategoryItem(name: '교통', icon: Icons.directions_bus_rounded, color: Color(0xFFB39DDB)),
        const DailyCategoryItem(name: '카페', icon: Icons.local_cafe_rounded, color: Color(0xFFA5D6A7)),
        const DailyCategoryItem(name: '취미', icon: Icons.sports_esports_rounded, color: Color(0xFF90CAF9)),
      ];
    }
  }

  // 정규화(이름 비교 일관화)
  String _norm(String s) => s.trim();

  late List<DailyCategoryItem> _items;

  List<DailyCategoryItem> get items => List.unmodifiable(_items);
  List<DailyCategoryItem> get enabledItems =>
      _items.where((e) => e.enabled).toList(growable: false);

  /// 이름으로 찾기(정규화 후 완전 일치)
  DailyCategoryItem? findByName(String name) {
    final key = _norm(name);
    try {
      return _items.firstWhere((c) => _norm(c.name) == key);
    } catch (_) {
      return null;
    }
  }

  /// 추가(동명 존재 시 덮어쓰기 + enabled=true)
  void addCategory(String name, IconData icon, Color color) {
    debugPrint('[DailyCategoryVM] addCategory("$name")  items.hash=${_items.hashCode}');
    final n = _norm(name);
    if (n.isEmpty) return;

    final idx = _items.indexWhere((e) => _norm(e.name) == n);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(icon: icon, color: color, enabled: true);
    } else {
      _items.add(DailyCategoryItem(name: n, icon: icon, color: color, enabled: true));
    }
    notifyListeners();
    debugPrint('[DailyCategoryVM] notifyListeners() called  total=${_items.length}');
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

  /// 수정(부분 업데이트)
  void updateAt(int index, {String? name, IconData? icon, Color? color}) {
    if (index < 0 || index >= _items.length) return;
    final nextName = (name != null) ? _norm(name) : null;
    _items[index] = _items[index].copyWith(name: nextName, icon: icon, color: color);
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../../model/category/category_edit_item.dart';
import '../../model/category/ref_category_item.dart';
import '../../model/refData/daily_consume.dart';
import '../../model/refData/entry.dart';
import '../../repository/ref_data_repository.dart';
import '../../repository/ref_category_repository.dart';

class SpendingCategoryViewModel extends ChangeNotifier {
  SpendingCategoryViewModel(
      this._refDataRepo,
      this._refCatRepo,
      );

  final RefDataRepository _refDataRepo;
  final RefCategoryRepository _refCatRepo;

  // ✅ users/{uid}/refCategories/{docId}
  final String _docId = 'recordSpending';

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<CategoryEditItem> _planItems = const [];
  List<CategoryEditItem> get planItems {
    final list = List<CategoryEditItem>.from(_planItems);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<RefCategoryItem> _refItems = const [];
  List<RefCategoryItem> get refItems {
    final list = List<RefCategoryItem>.from(_refItems);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  // -------------------------
  // helpers
  // -------------------------
  static DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fallbackEmojiByName(String name, {String fallback = '💰'}) {
    switch (name) {
      case '급여':
        return '💼';
      case '식비':
        return '🍽️';
      case '카페':
        return '☕';
      case '쇼핑':
        return '🛍️';
      case '여가':
        return '🎮';
      case '주거':
        return '🏠';
      case '통신':
        return '📱';
      case '교통':
        return '🚌';
      case '구독':
        return '📺';
      default:
        return fallback;
    }
  }

  DailyConsume? _findDailyConsumeForDate(
      Iterable<DailyConsume> all,
      DateTime date,
      ) {
    final d = _normalizeDay(date);

    // 1) 정확히 포함되는 daily 찾기
    final candidates = all.where((daily) {
      final s = _normalizeDay(daily.startDate);
      final e = _normalizeDay(daily.endDate);
      return !s.isAfter(d) && !e.isBefore(d);
    }).toList();

    if (candidates.isEmpty) return null;

    // 2) 여러 개면 "가장 최근에 시작한 것" 우선
    candidates.sort((a, b) => b.startDate.compareTo(a.startDate));
    return candidates.first;
  }

  /// ✅ cat_ prefix + ms + counter 로 "동일 ms" 충돌만 방지
  int _keyCounter = 0;
  String _newCategoryKey() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    _keyCounter = (_keyCounter + 1) % 1000000;
    return 'cat_${ms}_$_keyCounter';
  }

  // -------------------------
  // init (RecordSpendingPage에서 1회 호출)
  // -------------------------
  Future<void> initForDate(DateTime date) async {
    _selectedDate = _normalizeDay(date);

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_loadPlanInternal(), _loadRefInternal()]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // -------------------------
  // load plan (읽기 전용)
  // -------------------------
  Future<void> _loadPlanInternal() async {
    try {
      final ref = await _refDataRepo.loadAll();

      final daily = _findDailyConsumeForDate(
        ref.dailyConsumeMap.values,
        _selectedDate,
      );

      if (daily == null) {
        _planItems = const [];
        return;
      }

      final items = <CategoryEditItem>[];
      for (final e in daily.entries) {
        if (e.type != EntryType.daily) continue;

        final key = e.categoryKey.trim().isNotEmpty
            ? e.categoryKey.trim()
            : (e.category.trim().isNotEmpty ? e.category.trim() : 'unknown_${e.idx}');

        final name = e.category.trim().isNotEmpty ? e.category.trim() : key;
        final emoji = e.emoji.trim().isNotEmpty ? e.emoji : _fallbackEmojiByName(name);

        items.add(
          CategoryEditItem(
            categoryKey: key,
            name: name,
            emoji: emoji,
            order: e.order,
            kind: CategoryKind.plan,
            dailyAmount: e.amount.round(),
          ),
        );
      }

      items.sort((a, b) => a.order.compareTo(b.order));
      _planItems = [
        for (int i = 0; i < items.length; i++) items[i].copyWith(order: i),
      ];
    } catch (e) {
      _error = e.toString();
      _planItems = const [];
    }
  }

  // -------------------------
  // load ref (users/{uid}/refCategories/recordSpending)
  // -------------------------
  Future<void> _loadRefInternal() async {
    try {
      _refItems = await _refCatRepo.fetchRefCategories(docId: _docId);

      // ✅ 처음 1회: 기본 4개 자동 생성 (고유키)
      if (_refItems.isEmpty) {
        _refItems = _defaultRefSeedUniqueKeys();
        await _persistRef();
      }
    } catch (e) {
      _error = e.toString();
      _refItems = const [];
    }
  }

  List<RefCategoryItem> _defaultRefSeedUniqueKeys() {
    // ✅ seed도 고유키(cat_...)로 생성
    final list = <RefCategoryItem>[
      RefCategoryItem(categoryKey: _newCategoryKey(), name: '선물', emoji: '🎁', order: 0),
      RefCategoryItem(categoryKey: _newCategoryKey(), name: '반려동물', emoji: '🐕', order: 1),
      RefCategoryItem(categoryKey: _newCategoryKey(), name: '건강', emoji: '💊', order: 2),
      RefCategoryItem(categoryKey: _newCategoryKey(), name: '기타', emoji: '🧾', order: 3),
    ];
    return list;
  }

  Future<void> _persistRef() async {
    await _refCatRepo.saveRefCategories(docId: _docId, items: _refItems);
  }

  // =================================================
  // Ref CRUD (Sheet에서 호출)
  // =================================================

  /// ✅ sheet는 key 만들지 않음 → VM이 생성하여 반환
  Future<RefCategoryItem?> addRef({
    required String name,
    required String emoji,
  }) async {
    final n = name.trim();
    if (n.isEmpty) return null;

    final dupInPlan = _planItems.any((e) => e.name == n);
    final dupInRef = _refItems.any((e) => e.name == n);
    if (dupInPlan || dupInRef) return null;

    final key = _newCategoryKey(); // ✅ cat_ 고유키
    final item = RefCategoryItem(
      categoryKey: key,
      name: n,
      emoji: emoji.trim().isNotEmpty ? emoji.trim() : _fallbackEmojiByName(n),
      order: _refItems.length,
    );

    _refItems = [..._refItems, item];
    notifyListeners();

    await _persistRef();
    return item;
  }

  Future<void> removeRefByKey(String categoryKey) async {
    _refItems = _refItems.where((e) => e.categoryKey != categoryKey).toList();
    _refItems = [
      for (int i = 0; i < _refItems.length; i++) _refItems[i].copyWith(order: i),
    ];
    notifyListeners();
    await _persistRef();
  }

  Future<void> reorderRefByKeys(List<String> newOrderKeys) async {
    final map = {for (final e in _refItems) e.categoryKey: e};
    final reordered = <RefCategoryItem>[];

    for (final k in newOrderKeys) {
      final it = map[k];
      if (it != null) reordered.add(it);
    }
    for (final e in _refItems) {
      if (!newOrderKeys.contains(e.categoryKey)) reordered.add(e);
    }

    _refItems = [
      for (int i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i),
    ];
    notifyListeners();
    await _persistRef();
  }
}
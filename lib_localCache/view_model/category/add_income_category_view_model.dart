import 'package:flutter/foundation.dart';

import '../../model/category/ref_category_item.dart';
import '../../repository/ref_category_repository.dart';

class AddIncomeCategoryViewModel extends ChangeNotifier {
  AddIncomeCategoryViewModel(this._refCatRepo);

  final RefCategoryRepository _refCatRepo;

  /// users/{uid}/refCategories/{docId}
  final String _docId = 'recordAddIncome';

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<RefCategoryItem> _refItems = const [];
  List<RefCategoryItem> get refItems {
    final list = List<RefCategoryItem>.from(_refItems);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  static DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fallbackEmojiByName(String name, {String fallback = '💰'}) {
    switch (name) {
      case '용돈':
        return '🎁';
      case '환급':
        return '↩️';
      case '장학금':
        return '🎓';
      case '부수입':
        return '💸';
      case '급여':
        return '💼';
      case '이자':
        return '🏦';
      case '지원금':
        return '🪙';
      case '배당':
        return '📈';
      case '판매':
        return '🛍️';
      default:
        return fallback;
    }
  }

  int _keyCounter = 0;
  String _newCategoryKey() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    _keyCounter = (_keyCounter + 1) % 1000000;
    return 'cat_${ms}_$_keyCounter';
  }

  /// 날짜 의존 로직은 거의 없지만, 기존 소비쪽과 호출 패턴 맞추려고 유지
  Future<void> initForDate(DateTime date) async {
    _selectedDate = _normalizeDay(date);

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadRefInternal();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRefInternal() async {
    try {
      _refItems = await _refCatRepo.fetchRefCategories(docId: _docId);

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
    return <RefCategoryItem>[
      RefCategoryItem(
        categoryKey: _newCategoryKey(),
        name: '용돈',
        emoji: '🎁',
        order: 0,
      ),
      RefCategoryItem(
        categoryKey: _newCategoryKey(),
        name: '환급',
        emoji: '↩️',
        order: 1,
      ),
      RefCategoryItem(
        categoryKey: _newCategoryKey(),
        name: '장학금',
        emoji: '🎓',
        order: 2,
      ),
      RefCategoryItem(
        categoryKey: _newCategoryKey(),
        name: '부수입',
        emoji: '💸',
        order: 3,
      ),
    ];
  }

  Future<void> _persistRef() async {
    await _refCatRepo.saveRefCategories(docId: _docId, items: _refItems);
  }

  Future<RefCategoryItem?> addRef({
    required String name,
    required String emoji,
  }) async {
    final n = name.trim();
    if (n.isEmpty) return null;

    final dupInRef = _refItems.any((e) => e.name == n);
    if (dupInRef) return null;

    final key = _newCategoryKey();
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
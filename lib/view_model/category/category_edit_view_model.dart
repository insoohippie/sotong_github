import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../model/category/category_edit_item.dart';
import '../../model/refData/ref_data.dart';
import '../../model/refData/daily_consume.dart';
import '../../model/refData/entry.dart';

import '../../repository/plan_repository.dart';
import '../../repository/ref_data_repository.dart';
import '../../model/plan/total_plan.dart';

class CategoryEditViewModel extends ChangeNotifier {
  CategoryEditViewModel(
      this._planRepo,
      this._refRepo,
      );

  final PlanRepository _planRepo;
  final RefDataRepository _refRepo;

  // -----------------
  // State
  // -----------------
  DateTime _selectedDate = _normalizeDay(DateTime.now());
  DateTime get selectedDate => _selectedDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  // ✅ UI에서 progress box 계산에 쓰는데, 지금은 하드코딩
  // (원하면 나중에 TotalPlan에서 targetAmount 가져오게 변경)
  int get targetAmount => 1000000;

  // -----------------
  // Draft
  // -----------------
  List<CategoryEditItem> _draftPlan = [];
  List<CategoryEditItem> get draftPlan {
    final list = List<CategoryEditItem>.from(_draftPlan);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  // ✅ ref는 지금 기능 미구현: 빈 리스트만 제공
  List<CategoryEditItem> get draftRef => const <CategoryEditItem>[];

  // -----------------
  // Dirty
  // -----------------
  bool _dirty = false;
  bool get hasUnsavedChanges => _dirty;

  void _markDirty() {
    if (_dirty) return;
    _dirty = true;
    notifyListeners();
  }

  void _clearDirty() {
    if (!_dirty) return;
    _dirty = false;
    notifyListeners();
  }

  // -----------------
  // Helpers
  // -----------------
  static DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatYearMonth(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}';

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

  void _normalizeOrdersPlanOnly() {
    for (int i = 0; i < _draftPlan.length; i++) {
      _draftPlan[i] = _draftPlan[i].copyWith(order: i);
    }
  }

  // ===========================================================
  // 1) Load
  // ===========================================================
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = _normalizeDay(date);
    notifyListeners();
    await loadForSelectedDate();
  }

  Future<void> loadForSelectedDate() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final plan = await _planRepo.getLatestPlanForCurrentUser();
      if (plan == null) {
        _draftPlan = [];
        _dirty = false;
        return;
      }

      final ref = await _refRepo.loadAll();

      // ✅ 규칙:
      // plan.subPlans[YYYYMM].head.dailyConsumeId 를 찾아서
      // refData.dailyConsumeMap[dailyConsumeId]의 entries -> CategoryEditItem 변환
      final ym = _formatYearMonth(_selectedDate);

      final sub = plan.subPlans[ym];
      final dailyId = sub?.head.dailyConsumeId;

      if (dailyId == null) {
        _draftPlan = [];
        _dirty = false;
        return;
      }

      final daily = ref.dailyConsumeMap[dailyId];
      if (daily == null) {
        _draftPlan = [];
        _dirty = false;
        return;
      }

      final items = <CategoryEditItem>[];
      final entries = daily.entries;

      for (final e in entries) {
        // daily 예산 엔트리만 대상으로 가정
        if (e.type != EntryType.daily) continue;

        final key = e.categoryKey.trim().isNotEmpty
            ? e.categoryKey.trim()
            : (e.category.trim().isNotEmpty ? e.category.trim() : 'unknown_${e.idx}');

        final name = e.category.trim().isNotEmpty ? e.category.trim() : key;
        final emoji = (e.emoji.trim().isNotEmpty) ? e.emoji : _fallbackEmojiByName(name);

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
      // order가 비정상인 경우 대비
      for (int i = 0; i < items.length; i++) {
        items[i] = items[i].copyWith(order: i);
      }

      _draftPlan = items;
      _dirty = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================
  // 2) Draft Editing APIs (Plan only)
  // ===========================================================
  void draftAddCategory({
    required bool isPlan,
    required String categoryId,
    required String name,
    required String emoji,
    int? dailyAmount,
  }) {
    // ✅ 지금은 plan만 쓰는 걸 전제 (ref는 미구현)
    if (!isPlan) return;

    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final exists = _draftPlan.any((e) => e.categoryKey == categoryId || e.name == trimmed);
    if (exists) return;

    final resolvedEmoji = (emoji.trim().isEmpty || emoji == '💰')
        ? _fallbackEmojiByName(trimmed, fallback: '💰')
        : emoji;

    _draftPlan.add(
      CategoryEditItem(
        categoryKey: categoryId,
        name: trimmed,
        emoji: resolvedEmoji,
        order: _draftPlan.length,
        kind: CategoryKind.plan,
        dailyAmount: max(1, dailyAmount ?? 1),
      ),
    );

    _normalizeOrdersPlanOnly();
    _markDirty();
  }

  void draftUpdateMeta({
    required String categoryId,
    String? name,
    String? emoji,
  }) {
    String? trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) trimmedName = null;

    if (trimmedName != null) {
      final dup = _draftPlan.any((e) => e.categoryKey != categoryId && e.name == trimmedName);
      if (dup) return;
    }

    for (int i = 0; i < _draftPlan.length; i++) {
      final it = _draftPlan[i];
      if (it.categoryKey == categoryId) {
        _draftPlan[i] = it.copyWith(
          name: trimmedName ?? it.name,
          emoji: emoji ?? it.emoji,
        );
        _markDirty();
        return;
      }
    }
  }

  void draftUpdateDailyAmount({
    required String categoryId,
    required int dailyAmount,
  }) {
    if (dailyAmount < 1) return;

    for (int i = 0; i < _draftPlan.length; i++) {
      final it = _draftPlan[i];
      if (it.categoryKey == categoryId) {
        _draftPlan[i] = it.copyWith(dailyAmount: dailyAmount);
        _markDirty();
        return;
      }
    }
  }

  void draftDelete(String categoryId) {
    final before = _draftPlan.length;
    _draftPlan.removeWhere((e) => e.categoryKey == categoryId);
    _normalizeOrdersPlanOnly();
    if (_draftPlan.length != before) _markDirty();
  }

  void draftReorderPlan(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _draftPlan.length) return;
    if (newIndex < 0 || newIndex > _draftPlan.length) return;
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _draftPlan.removeAt(oldIndex);
    _draftPlan.insert(newIndex, item);
    _normalizeOrdersPlanOnly();
    _markDirty();
  }

  // ✅ ref 관련(미구현) — UI 컴파일용 no-op
  void draftReorderRef(int oldIndex, int newIndex) {}
  void draftMoveRefToPlan({required String categoryId, required int newIndex, required int dailyAmount}) {}
  void draftMovePlanToRef({required String categoryId, required int newIndex}) {}

  // ===========================================================
  // 3) Save (Plan category only)
  // ===========================================================
  Future<bool> saveDraftForSelectedDate() async {
    if (_isSaving) return false;
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final plan = await _planRepo.getLatestPlanForCurrentUser();
      if (plan == null) {
        _error = '저장할 플랜이 없습니다.';
        return false;
      }

      final ref = await _refRepo.loadAll();
      final ym = _formatYearMonth(_selectedDate);

      final sub = plan.subPlans[ym];
      final dailyId = sub?.head.dailyConsumeId;

      if (dailyId == null) {
        _error = '해당 월(YYYYMM=$ym)의 dailyConsumeId를 찾지 못했습니다.';
        return false;
      }

      final prevDaily = ref.dailyConsumeMap[dailyId];
      if (prevDaily == null) {
        _error = 'refData.dailyConsumeMap에서 dailyConsumeId=$dailyId 를 찾지 못했습니다.';
        return false;
      }

      // draftPlan -> entries
      final newEntries = <Entry>[];
      for (int i = 0; i < _draftPlan.length; i++) {
        final c = _draftPlan[i];

        newEntries.add(
          Entry(
            idx: i,
            order: i,
            amount: (c.dailyAmount ?? 1).toDouble(),
            categoryKey: c.categoryKey,
            category: c.name,
            emoji: c.emoji,
            note: '',
            type: EntryType.daily,
            dateTime: null,
          ),
        );
      }

      // ✅ DailyConsume가 copyWith(entries: ...) 지원한다고 가정
      // (네 모델에 맞게 이름만 맞추면 됨)
      final updated = prevDaily.copyWith(entries: newEntries);

      await _refRepo.saveDailyConsume(updated);

      _clearDirty();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../model/category/category_edit_item.dart';
import '../../model/category/ref_category_item.dart';
import '../../model/commands/update_daily_command.dart';
import '../../model/plan/total_plan.dart';
import '../../model/refData/daily_consume.dart';
import '../../model/refData/entry.dart';
import '../../model/refData/ref_data.dart';
import '../../model/saving_calculation_result.dart';

import '../../repository/plan_repository.dart';
import '../../repository/plan_mutation_repository.dart';
import '../../repository/ref_category_repository.dart';
import '../../repository/ref_data_repository.dart';

import '../services/plan_preview_service.dart';

class CategoryEditViewModel extends ChangeNotifier {
  CategoryEditViewModel(
      this._planRepo,
      this._refRepo,
      this._refCatRepo,
      this._planMutRepo,
      );

  final PlanRepository _planRepo;
  final RefDataRepository _refRepo;
  final RefCategoryRepository _refCatRepo;
  final PlanMutationRepository _planMutRepo;

  final String _refDocId = 'recordSpending';

  final PlanPreviewService _previewService = const PlanPreviewService();

  // -----------------
  // State
  // -----------------
  DateTime _selectedDate = _normalizeDay(DateTime.now());
  DateTime get selectedDate => _selectedDate;

  bool _initialized = false;

  TotalPlan? _latestPlan;
  RefData? _refData;

  int get targetAmount => _latestPlan?.targetAmount ?? 0;
  String get planName => _latestPlan?.planName ?? '';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  // -----------------
  // Draft (편집 대상)
  // -----------------
  List<CategoryEditItem> _draftPlan = [];
  List<CategoryEditItem> get draftPlan {
    final list = List<CategoryEditItem>.from(_draftPlan);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<RefCategoryItem> _draftRef = [];
  List<RefCategoryItem> get draftRef {
    final list = List<RefCategoryItem>.from(_draftRef);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<String> _draftPlanOrderKeys = const [];
  List<String> get draftPlanOrderKeys => _draftPlanOrderKeys;

  // -----------------
  // Base Snapshot
  // -----------------
  List<CategoryEditItem> _basePlan = [];
  List<RefCategoryItem> _baseRef = [];

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

  // ===========================================================
  // Helpers
  // ===========================================================
  static DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DailyConsume? _findDailyConsumeForDate(
      Iterable<DailyConsume> all,
      DateTime date,
      ) {
    final d = _normalizeDay(date);

    final candidates = all.where((daily) {
      final s = _normalizeDay(daily.startDate);
      final e = _normalizeDay(daily.endDate);
      return !s.isAfter(d) && !e.isBefore(d);
    }).toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.startDate.compareTo(a.startDate));
    return candidates.first;
  }

  String _normalizeName(String s) {
    return s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

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
    _draftPlan = [
      for (int i = 0; i < _draftPlan.length; i++)
        _draftPlan[i].copyWith(order: i),
    ];
    _draftPlanOrderKeys =
        _draftPlan.map((e) => e.categoryKey).toList(growable: false);
  }

  void _normalizeOrdersRefOnly() {
    _draftRef = [
      for (int i = 0; i < _draftRef.length; i++)
        _draftRef[i].copyWith(order: i),
    ];
  }

  void _snapshotBase() {
    _basePlan = _draftPlan.map((e) => e.copyWith()).toList(growable: false);
    _baseRef = _draftRef.map((e) => e.copyWith()).toList(growable: false);
  }

  void discardDraft() {
    _draftPlan = _basePlan.map((e) => e.copyWith()).toList();
    _draftRef = _baseRef.map((e) => e.copyWith()).toList();
    _normalizeOrdersPlanOnly();
    _normalizeOrdersRefOnly();
    _dirty = false;
    notifyListeners();
  }

  // ===========================================================
  // Preview 계산
  // - 기존 플랜은 그대로 두고,
  // - 플랜 카테고리(draftPlan)의 일일 소비 합계만 바꿨을 때
  //   목표 도달 예정일을 계산한다.
  // ===========================================================
  double get draftDailySpendingLimit {
    return _draftPlan.fold<double>(
      0.0,
          (sum, item) => sum + (item.dailyAmount ?? 0).toDouble(),
    );
  }

  SavingCalculationResult? get draftPreviewResult {
    final plan = _latestPlan;
    final ref = _refData;

    if (plan == null || ref == null) return null;
    if (draftDailySpendingLimit <= 0) return null;

    return _previewService.calculatePreview(
      PlanPreviewInput(
        plan: plan,
        refData: ref,
        applyDate: _normalizeDay(DateTime.now()),

        // 기존 플랜 기본값 그대로 사용
        targetAmount: (plan.targetAmount ?? 0).toDouble(),
        currentAsset: plan.currentAsset.toDouble(),

        // 기존 수입 / 고정 소비 그대로 사용
        monthlyIncome: ref.primaryMonthlyIncomeSum,
        monthlyFixedCost: ref.primaryMonthlyConsumeSum,

        // 카테고리 수정 페이지에서 바뀐 플랜 카테고리 합계만 반영
        dailySpendingLimit: draftDailySpendingLimit,
      ),
    );
  }

  DateTime? get projectedGoalDate {
    return draftPreviewResult?.goalDateTime;
  }

  int? get daysToGoal {
    final result = draftPreviewResult;
    if (result == null) return null;
    if (result.daysToGoal <= 0) return null;
    return result.daysToGoal.ceil();
  }

  // ===========================================================
  // Init / Date
  // ===========================================================
  Future<void> initOnce() async {
    if (_initialized) return;
    _initialized = true;

    _selectedDate = _normalizeDay(DateTime.now());
    await loadForSelectedDate();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = _normalizeDay(date);
    notifyListeners();
    await loadForSelectedDate();
  }

  // ===========================================================
  // Load
  // ===========================================================
  Future<void> loadForSelectedDate() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadPlanDraftInternal(),
        _loadRefDraftInternal(),
      ]);

      _snapshotBase();
      _dirty = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPlanDraftInternal() async {
    final plan = await _planRepo.getLatestPlanForCurrentUser();
    _latestPlan = plan;

    if (plan == null) {
      _draftPlan = [];
      _draftPlanOrderKeys = const [];
      _refData = null;
      return;
    }

    final ref = await _refRepo.loadAll();
    _refData = ref;

    final daily = _findDailyConsumeForDate(
      ref.dailyConsumeMap.values,
      _selectedDate,
    );

    if (daily == null) {
      _draftPlan = [];
      _draftPlanOrderKeys = const [];
      return;
    }

    final items = <CategoryEditItem>[];

    for (final e in daily.entries) {
      if (e.type != EntryType.daily) continue;

      final key = e.categoryKey.trim().isNotEmpty
          ? e.categoryKey.trim()
          : (e.category.trim().isNotEmpty
          ? e.category.trim()
          : 'unknown_${e.idx}');

      final name = e.category.trim().isNotEmpty ? e.category.trim() : key;
      final emoji =
      e.emoji.trim().isNotEmpty ? e.emoji : _fallbackEmojiByName(name);

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

    _draftPlan = [
      for (int i = 0; i < items.length; i++)
        items[i].copyWith(order: i),
    ];

    _draftPlanOrderKeys =
        _draftPlan.map((e) => e.categoryKey).toList(growable: false);
  }

  Future<void> _loadRefDraftInternal() async {
    final items = await _refCatRepo.fetchRefCategories(docId: _refDocId);
    _draftRef = List<RefCategoryItem>.from(items)
      ..sort((a, b) => a.order.compareTo(b.order));
    _normalizeOrdersRefOnly();
  }

  // ===========================================================
  // Draft Editing APIs
  // ===========================================================
  void draftAddCategory({
    required bool isPlan,
    required String categoryKey,
    required String name,
    required String emoji,
    int? dailyAmount,
  }) {
    if (!isPlan) return;

    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final norm = _normalizeName(trimmed);
    final exists = _draftPlan.any(
          (e) => e.categoryKey == categoryKey || _normalizeName(e.name) == norm,
    );

    if (exists) return;

    final resolvedEmoji = (emoji.trim().isEmpty || emoji == '💰')
        ? _fallbackEmojiByName(trimmed, fallback: '💰')
        : emoji;

    _draftPlan = [
      ..._draftPlan,
      CategoryEditItem(
        categoryKey: categoryKey,
        name: trimmed,
        emoji: resolvedEmoji,
        order: _draftPlan.length,
        kind: CategoryKind.plan,
        dailyAmount: max(1, dailyAmount ?? 1),
      ),
    ];

    _normalizeOrdersPlanOnly();
    _markDirty();
  }

  void draftUpdateMeta({
    required String categoryKey,
    String? name,
    String? emoji,
  }) {
    String? trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) trimmedName = null;

    if (trimmedName != null) {
      final norm = _normalizeName(trimmedName);
      final dup = _draftPlan.any(
            (e) => e.categoryKey != categoryKey && _normalizeName(e.name) == norm,
      );
      if (dup) return;
    }

    for (int i = 0; i < _draftPlan.length; i++) {
      final it = _draftPlan[i];

      if (it.categoryKey == categoryKey) {
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
    required String categoryKey,
    required int dailyAmount,
  }) {
    if (dailyAmount < 1) return;

    for (int i = 0; i < _draftPlan.length; i++) {
      final it = _draftPlan[i];

      if (it.categoryKey == categoryKey) {
        _draftPlan[i] = it.copyWith(dailyAmount: dailyAmount);
        _markDirty();
        return;
      }
    }
  }

  void draftDeletePlan(String categoryKey) {
    final before = _draftPlan.length;
    _draftPlan = _draftPlan.where((e) => e.categoryKey != categoryKey).toList();
    _normalizeOrdersPlanOnly();

    if (_draftPlan.length != before) _markDirty();
  }

  void draftReorderPlanByKeys(List<String> newOrderKeys) {
    final map = {for (final e in _draftPlan) e.categoryKey: e};
    final reordered = <CategoryEditItem>[];

    for (final k in newOrderKeys) {
      final it = map[k];
      if (it != null) reordered.add(it);
    }

    for (final e in _draftPlan) {
      if (!newOrderKeys.contains(e.categoryKey)) reordered.add(e);
    }

    _draftPlan = [
      for (int i = 0; i < reordered.length; i++)
        reordered[i].copyWith(order: i),
    ];

    _draftPlanOrderKeys = List<String>.from(newOrderKeys);
    _markDirty();
  }

  bool _existsRefName(String name, {String? exceptKey}) {
    final norm = _normalizeName(name);
    return _draftRef.any(
          (e) => e.categoryKey != exceptKey && _normalizeName(e.name) == norm,
    );
  }

  RefCategoryItem? draftAddRef({
    required String name,
    required String emoji,
  }) {
    final n = name.trim();

    if (n.isEmpty) return null;
    if (_existsRefName(n)) return null;

    final key = 'ref_${DateTime.now().millisecondsSinceEpoch}';
    final resolvedEmoji =
    emoji.trim().isNotEmpty ? emoji.trim() : _fallbackEmojiByName(n);

    final item = RefCategoryItem(
      categoryKey: key,
      name: n,
      emoji: resolvedEmoji,
      order: _draftRef.length,
      hidden: false,
    );

    _draftRef = [..._draftRef, item];
    _normalizeOrdersRefOnly();
    _markDirty();

    return item;
  }

  void draftRemoveRefByKey(String categoryKey) {
    final before = _draftRef.length;
    _draftRef = _draftRef.where((e) => e.categoryKey != categoryKey).toList();
    _normalizeOrdersRefOnly();

    if (_draftRef.length != before) _markDirty();
  }

  void draftUpdateRefMeta({
    required String categoryKey,
    String? name,
    String? emoji,
    bool? hidden,
  }) {
    String? trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) trimmedName = null;

    if (trimmedName != null) {
      if (_existsRefName(trimmedName, exceptKey: categoryKey)) return;
    }

    for (int i = 0; i < _draftRef.length; i++) {
      final it = _draftRef[i];

      if (it.categoryKey == categoryKey) {
        _draftRef[i] = it.copyWith(
          name: trimmedName ?? it.name,
          emoji: emoji ?? it.emoji,
          hidden: hidden ?? it.hidden,
        );
        _markDirty();
        return;
      }
    }
  }

  void draftReorderRefByKeys(List<String> newOrderKeys) {
    final map = {for (final e in _draftRef) e.categoryKey: e};
    final reordered = <RefCategoryItem>[];

    for (final k in newOrderKeys) {
      final it = map[k];
      if (it != null) reordered.add(it);
    }

    for (final e in _draftRef) {
      if (!newOrderKeys.contains(e.categoryKey)) reordered.add(e);
    }

    _draftRef = [
      for (int i = 0; i < reordered.length; i++)
        reordered[i].copyWith(order: i),
    ];

    _markDirty();
  }

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
      final applyDate = _normalizeDay(_selectedDate);

      final activeDaily = _findDailyConsumeForDate(
        ref.dailyConsumeMap.values,
        applyDate,
      );

      if (activeDaily == null) {
        _error = '선택 날짜의 dailyConsume을 찾지 못했습니다.';
        return false;
      }

      final previousDailyId = activeDaily.id;

      // 1) draftPlan -> Entry[] 변환
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

      // 2) command 기반 daily mutation 수행
      final modEndDate = _normalizeDay(
        plan.modEndDate ?? plan.endDate ?? applyDate,
      );

      final safeModEnd =
      applyDate.isAfter(modEndDate) ? applyDate : modEndDate;

      final newDailyId = _nextDailyId(
        applyDate: applyDate,
        existingIds: ref.dailyConsumeMap.keys,
      );

      final newMiniDocId = _nextMiniDocId(
        plan: plan,
        applyDate: applyDate,
      );

      final cmd = UpdateDailyCommand(
        applyDate: applyDate,
        modEndDate: safeModEnd,
        entries: List<Entry>.unmodifiable(newEntries),
        newDailyId: newDailyId,
        newMiniDocId: newMiniDocId,
        previousDailyId: previousDailyId,
      );

      final mutation = _planMutRepo.applyDaily(
        totalPlan: plan,
        monthlyIncomes: ref.monthlyIncomeMap,
        monthlyConsumes: ref.monthlyConsumeMap,
        dailyConsumes: ref.dailyConsumeMap,
        command: cmd,
      );

      final updatedPlan = mutation.totalPlan;
      final updatedDailyMap = mutation.dailyConsumes;

      // 3) mutation 결과 daily 문서 저장
      final toUpsertIds = <String>{previousDailyId, newDailyId};

      for (final id in toUpsertIds) {
        final daily = updatedDailyMap[id];

        if (daily != null) {
          await _refRepo.saveDailyConsume(daily);
        }
      }

      // 4) 플랜 저장
      await _planRepo.replacePlan(updatedPlan);

      // 5) 참고 카테고리 저장
      final refToSave = List<RefCategoryItem>.from(_draftRef)
        ..sort((a, b) => a.order.compareTo(b.order));

      final normalizedRef = [
        for (int i = 0; i < refToSave.length; i++)
          refToSave[i].copyWith(order: i),
      ];

      await _refCatRepo.saveRefCategories(
        docId: _refDocId,
        items: normalizedRef,
        markDirty: true,
      );

      _draftRef = normalizedRef;

      _normalizeOrdersPlanOnly();
      _normalizeOrdersRefOnly();

      _latestPlan = updatedPlan;
      _refData = ref;

      _snapshotBase();
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

  // ===========================================================
  // ID Generators
  // ===========================================================
  String _nextDailyId({
    required DateTime applyDate,
    required Iterable<String> existingIds,
  }) {
    final base =
        '${applyDate.year.toString().padLeft(4, '0')}'
        '${applyDate.month.toString().padLeft(2, '0')}';

    var maxSeq = 0;

    for (final id in existingIds) {
      if (!id.startsWith(base)) continue;

      final parts = id.split('-');
      if (parts.length != 2) continue;

      final seq = int.tryParse(parts[1]) ?? 0;
      if (seq > maxSeq) maxSeq = seq;
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(3, '0');
    return '$base-$nextSeq';
  }

  String _nextMiniDocId({
    required TotalPlan plan,
    required DateTime applyDate,
  }) {
    final base =
        '${applyDate.year.toString().padLeft(4, '0')}'
        '${applyDate.month.toString().padLeft(2, '0')}';

    final subPlan = plan.subPlans[base];

    var maxSeq = 0;

    if (subPlan != null) {
      for (final id in subPlan.miniPlans.keys) {
        final parts = id.split('-');
        if (parts.length != 2) continue;

        final seq = int.tryParse(parts[1]);

        if (seq != null && seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(3, '0');
    return '$base-$nextSeq';
  }
}
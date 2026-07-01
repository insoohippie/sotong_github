import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../model/category/category_edit_item.dart';
import '../../model/category/ref_category_item.dart';
import '../../model/commands/update_daily_command.dart';
import '../../model/plan/total_plan.dart';
import '../../model/refData/entry.dart';
import '../../model/refData/ref_data.dart';
import '../../model/saving_calculation_result.dart';

import '../../repository/auth_repository.dart';
import '../../repository/plan_cache_repository.dart';
import '../../repository/plan_mutation_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/ref_category_repository.dart';
import '../../repository/ref_data_repository.dart';

import '../../services/category_key.dart';
import '../../services/plan_saved_event_bus.dart';

import '../services/plan_preview_service.dart';

class CategoryEditViewModel extends ChangeNotifier {
  CategoryEditViewModel(
      this._authRepo,
      this._planRepo,
      this._refRepo,
      this._refCatRepo,
      this._planMutRepo,
      this._planCacheRepo,
      this._planSavedBus,
      );

  final AuthRepository _authRepo;
  final PlanRepository _planRepo;
  final RefDataRepository _refRepo;
  final RefCategoryRepository _refCatRepo;
  final PlanMutationRepository _planMutRepo;
  final PlanCacheRepository _planCacheRepo;
  final PlanSavedEventBus _planSavedBus;

  final String _refDocId = 'recordSpending';

  final PlanPreviewService _previewService = const PlanPreviewService();

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

  String? _noticeMessage;
  String? get noticeMessage => _noticeMessage;

  void consumeNoticeMessage() {
    _noticeMessage = null;
  }

  void _showNotice(String message) {
    _noticeMessage = message;
    notifyListeners();
  }

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

  List<CategoryEditItem> _basePlan = [];
  List<RefCategoryItem> _baseRef = [];

  bool _dirty = false;
  bool get hasUnsavedChanges => _dirty;

  static DateTime _normalizeDay(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

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



  String _normalizeName(String s) {
    return s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String? validateNewCategoryName({
    required bool isPlan,
    required String name,
  }) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return '카테고리 이름을 입력해주세요.';
    }

    final norm = _normalizeName(trimmed);

    if (isPlan) {
      final exists = _draftPlan.any(
            (e) => _normalizeName(e.name) == norm,
      );

      if (exists) {
        return '같은 이름의 플랜 카테고리가 이미 있어요.';
      }

      return null;
    }

    final exists = _draftRef.any(
          (e) => _normalizeName(e.name) == norm,
    );

    if (exists) {
      return '같은 이름의 참고 카테고리가 이미 있어요.';
    }

    return null;
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

  Future<void> _cacheUpdatedPlanSnapshot({
    required TotalPlan plan,
    required RefData refData,
  }) async {
    final uid = _authRepo.cachedUid ?? _authRepo.currentUserId;
    if (uid == null) return;

    await _planCacheRepo.saveSnapshot(
      uid: uid,
      snapshot: PlanCacheSnapshot(
        plan: plan,
        refData: refData,
        needsInitialUpload: false,
      ),
    );
  }

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
        targetAmount: (plan.targetAmount ?? 0).toDouble(),
        currentAsset: plan.currentAsset.toDouble(),
        monthlyIncome: ref.primaryMonthlyIncomeSum,
        monthlyFixedCost: ref.primaryMonthlyConsumeSum,
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

  Future<void> initOnce() async {
    if (_initialized) return;
    _initialized = true;

    _selectedDate = _normalizeDay(DateTime.now());
    await loadForSelectedDate();
  }

  /// ✅ 페이지 재진입/플랜 수정 후 복귀 시 강제 새로고침용.
  /// CategoryEditViewModel은 전역 Provider라 이전 draft가 남을 수 있으므로
  /// CategoryEditPage.initState()에서는 이 메서드를 호출하는 게 안전함.
  Future<void> refreshForToday() async {
    _selectedDate = _normalizeDay(DateTime.now());
    await loadForSelectedDate();
  }

  Future<void> refreshForSelectedDate() async {
    await loadForSelectedDate();
  }

  Future<void> setSelectedDate(DateTime date) async {
    final normalized = _normalizeDay(date);
    _selectedDate = normalized;
    notifyListeners();
    await loadForSelectedDate();
  }

  Future<void> loadForSelectedDate() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ 플랜 draft와 ref category를 둘 다 최신화
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
    final uid = _authRepo.cachedUid ?? _authRepo.currentUserId;

    final cachedSnapshot = uid == null ? null : _planCacheRepo.loadSnapshot(uid);

    // ✅ 카테고리 수정창도 캐시 우선으로 로드
    final plan = cachedSnapshot?.plan ??
        await _planRepo.getLatestPlanForCurrentUser();

    _latestPlan = plan;

    if (plan == null) {
      _draftPlan = [];
      _draftPlanOrderKeys = const [];
      _refData = null;
      return;
    }

    final ref = cachedSnapshot?.refData ?? await _refRepo.loadAll();

    ref.planId = plan.planId;

    // ✅ 기준 통일:
    // RefData 내부 primaryDailyConsumeId를 selectedDate 기준으로 다시 계산한다.
    // ref_data.dart에서 같은 날짜여도 refresh 되게 수정했으므로,
    // 여기서 매번 호출해도 최신 primary가 잡힘.
    ref.setReferenceDate(_selectedDate);

    _refData = ref;

    // ✅ 이제 카테고리 수정창도 플랜 에딧창과 같은 기준 사용
    final entries = ref.primaryDailyConsumeEntries;

    if (entries.isEmpty) {
      _draftPlan = [];
      _draftPlanOrderKeys = const [];

      debugPrint(
        '[CategoryEdit] primaryDailyConsumeEntries empty '
            'selectedDate=$_selectedDate '
            'primaryDailyConsumeId=${ref.primaryDailyConsumeId} '
            'dailyCount=${ref.dailyConsumeMap.length}',
      );

      return;
    }

    debugPrint(
      '[CategoryEdit] loaded primary daily '
          'selectedDate=$_selectedDate '
          'primaryDailyConsumeId=${ref.primaryDailyConsumeId} '
          'entries=${entries.map((e) => '${e.category}:${e.amount}').join(', ')}',
    );

    final items = <CategoryEditItem>[];

    for (final e in entries) {
      if (e.type != EntryType.daily) continue;

      final resolvedKey = CategoryKey.isValid(e.categoryKey)
          ? e.categoryKey.trim()
          : CategoryKey.newKey();

      final name = e.category.trim().isNotEmpty
          ? e.category.trim()
          : resolvedKey;

      final emoji = e.emoji.trim().isNotEmpty
          ? e.emoji.trim()
          : _fallbackEmojiByName(name);

      items.add(
        CategoryEditItem(
          categoryKey: resolvedKey,
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

  void draftAddCategory({
    required bool isPlan,
    required String categoryKey,
    required String name,
    required String emoji,
    int? dailyAmount,
  }) {
    if (!isPlan) return;

    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      _showNotice('카테고리 이름을 입력해주세요.');
      return;
    }

    final resolvedKey = CategoryKey.isValid(categoryKey)
        ? categoryKey.trim()
        : CategoryKey.newKey();

    final norm = _normalizeName(trimmed);

    final exists = _draftPlan.any(
          (e) =>
      e.categoryKey == resolvedKey ||
          _normalizeName(e.name) == norm,
    );

    if (exists) {
      _showNotice('같은 이름의 플랜 카테고리가 이미 있어요.');
      return;
    }

    final resolvedEmoji = emoji.trim().isNotEmpty
        ? emoji.trim()
        : _fallbackEmojiByName(trimmed);

    _draftPlan = [
      ..._draftPlan,
      CategoryEditItem(
        categoryKey: resolvedKey,
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

    if (trimmedName != null && trimmedName.isEmpty) {
      trimmedName = null;
    }

    if (trimmedName != null) {
      final norm = _normalizeName(trimmedName);

      final dup = _draftPlan.any(
            (e) =>
        e.categoryKey != categoryKey &&
            _normalizeName(e.name) == norm,
      );

      if (dup) {
        _showNotice('같은 이름의 플랜 카테고리가 이미 있어요.');
        return;
      }
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

    _draftPlan = _draftPlan
        .where((e) => e.categoryKey != categoryKey)
        .toList();

    _normalizeOrdersPlanOnly();

    if (_draftPlan.length != before) {
      _markDirty();
    }
  }

  void draftReorderPlanByKeys(List<String> newOrderKeys) {
    final map = {
      for (final e in _draftPlan) e.categoryKey: e,
    };

    final reordered = <CategoryEditItem>[];

    for (final k in newOrderKeys) {
      final it = map[k];
      if (it != null) reordered.add(it);
    }

    for (final e in _draftPlan) {
      if (!newOrderKeys.contains(e.categoryKey)) {
        reordered.add(e);
      }
    }

    _draftPlan = [
      for (int i = 0; i < reordered.length; i++)
        reordered[i].copyWith(order: i),
    ];

    _draftPlanOrderKeys =
        _draftPlan.map((e) => e.categoryKey).toList(growable: false);

    _markDirty();
  }

  bool _existsRefName(String name, {String? exceptKey}) {
    final norm = _normalizeName(name);

    return _draftRef.any(
          (e) =>
      e.categoryKey != exceptKey &&
          _normalizeName(e.name) == norm,
    );
  }

  RefCategoryItem? draftAddRef({
    required String name,
    required String emoji,
  }) {
    final n = name.trim();

    if (n.isEmpty) {
      _showNotice('카테고리 이름을 입력해주세요.');
      return null;
    }

    if (_existsRefName(n)) {
      _showNotice('같은 이름의 참고 카테고리가 이미 있어요.');
      return null;
    }

    final key = CategoryKey.newKey();

    final resolvedEmoji = emoji.trim().isNotEmpty
        ? emoji.trim()
        : _fallbackEmojiByName(n);

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

    _draftRef = _draftRef
        .where((e) => e.categoryKey != categoryKey)
        .toList();

    _normalizeOrdersRefOnly();

    if (_draftRef.length != before) {
      _markDirty();
    }
  }

  void draftUpdateRefMeta({
    required String categoryKey,
    String? name,
    String? emoji,
    bool? hidden,
  }) {
    String? trimmedName = name?.trim();

    if (trimmedName != null && trimmedName.isEmpty) {
      trimmedName = null;
    }

    if (trimmedName != null) {
      if (_existsRefName(trimmedName, exceptKey: categoryKey)) {
        _showNotice('같은 이름의 참고 카테고리가 이미 있어요.');
        return;
      }
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
    final map = {
      for (final e in _draftRef) e.categoryKey: e,
    };

    final reordered = <RefCategoryItem>[];

    for (final k in newOrderKeys) {
      final it = map[k];
      if (it != null) reordered.add(it);
    }

    for (final e in _draftRef) {
      if (!newOrderKeys.contains(e.categoryKey)) {
        reordered.add(e);
      }
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
      final uid = _authRepo.cachedUid ?? _authRepo.currentUserId;
      final cachedSnapshot = uid == null ? null : _planCacheRepo.loadSnapshot(uid);

      final plan = cachedSnapshot?.plan ??
          await _planRepo.getLatestPlanForCurrentUser();

      if (plan == null) {
        _error = '저장할 플랜이 없습니다.';
        return false;
      }

      final ref = cachedSnapshot?.refData ?? await _refRepo.loadAll();
      ref.planId = plan.planId;

      final applyDate = _normalizeDay(_selectedDate);

// ✅ 저장 기준도 primary 기준으로 통일
      ref.setReferenceDate(applyDate);

      final activeDailyId = ref.primaryDailyConsumeId;
      final activeDaily = activeDailyId == null
          ? null
          : ref.dailyConsumeMap[activeDailyId];

      if (activeDaily == null) {
        _error = '선택 날짜의 dailyConsume을 찾지 못했습니다.';
        return false;
      }

      final previousDailyId = activeDaily.id;

      final newEntries = <Entry>[];
      final normalizedDraftPlan = <CategoryEditItem>[];

      for (int i = 0; i < _draftPlan.length; i++) {
        final c = _draftPlan[i];

        final resolvedKey = CategoryKey.isValid(c.categoryKey)
            ? c.categoryKey.trim()
            : CategoryKey.newKey();

        final normalizedItem = c.copyWith(
          categoryKey: resolvedKey,
          order: i,
        );

        normalizedDraftPlan.add(normalizedItem);

        newEntries.add(
          Entry(
            idx: i,
            order: i,
            amount: (normalizedItem.dailyAmount ?? 1).toDouble(),
            categoryKey: normalizedItem.categoryKey,
            category: normalizedItem.name,
            emoji: normalizedItem.emoji,
            note: '',
            type: EntryType.daily,
            dateTime: null,
          ),
        );
      }

      if (newEntries.isEmpty) {
        _error = '플랜 카테고리를 1개 이상 입력해주세요.';
        return false;
      }

      final modEndDate = _normalizeDay(
        plan.modEndDate ?? plan.endDate ?? applyDate,
      );

      final safeModEnd = applyDate.isAfter(modEndDate)
          ? applyDate
          : modEndDate;

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

      final updatedRefData = RefData(
        planId: plan.planId,
        monthlyIncomes: ref.monthlyIncomeMap,
        monthlyConsumes: ref.monthlyConsumeMap,
        dailyConsumes: mutation.dailyConsumes,
      );

      updatedRefData.setReferenceDate(applyDate);

      final toUpsertIds = <String>{
        previousDailyId,
        newDailyId,
      };

      for (final id in toUpsertIds) {
        final daily = updatedRefData.dailyConsumeMap[id];

        if (daily != null) {
          await _refRepo.saveDailyConsume(daily);
        }
      }

      await _planRepo.replacePlan(updatedPlan);

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

      await _cacheUpdatedPlanSnapshot(
        plan: updatedPlan,
        refData: updatedRefData,
      );

      _planSavedBus.notify();

      _draftPlan = normalizedDraftPlan;
      _draftRef = normalizedRef;

      _normalizeOrdersPlanOnly();
      _normalizeOrdersRefOnly();

      _latestPlan = updatedPlan;
      _refData = updatedRefData;

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

      if (seq > maxSeq) {
        maxSeq = seq;
      }
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
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../model/category/category_meta_item.dart';
import '../../model/category/category_plan_meta_doc.dart';
import '../../model/category/category_ref_prefs.dart';
import '../../model/category/category_snapshot_item.dart';

import '../../model/refData/ref_data.dart';
import '../../model/refData/entry.dart';
import '../../model/refData/daily_consume.dart';

import '../../model/commands/update_daily_command.dart';
import '../../model/plan/plan_snapshot.dart';
import '../../model/plan/total_plan.dart';

import '../../repository/category_prefs_repository.dart';
import '../../repository/ref_data_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/plan_mutation_repository.dart';
import '../../services/plan_mutation_service.dart';

class CategoryEditViewModel extends ChangeNotifier {
  CategoryEditViewModel(
      this._prefsRepo,
      this._refRepo,
      this._planRepo,
      ) : _mutationService = PlanMutationService(PlanMutationRepository());

  final CategoryPrefsRepository _prefsRepo;
  final RefDataRepository _refRepo;
  final PlanRepository _planRepo;
  final PlanMutationService _mutationService;

  // -----------------
  // 상태
  // -----------------
  DateTime _selectedDate = _normalizeDay(DateTime.now());
  DateTime get selectedDate => _selectedDate;

  DateTime _applyDate = _normalizeDay(DateTime.now());
  DateTime _endDate = DateTime(2100, 12, 31);

  List<CategorySnapshotItem> _draftPlan = [];
  List<CategorySnapshotItem> _draftRef = [];

  List<CategorySnapshotItem> get draftPlan {
    final list = List<CategorySnapshotItem>.from(_draftPlan);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<CategorySnapshotItem> get draftRef {
    final list = List<CategorySnapshotItem>.from(_draftRef);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  CategoryRefPrefs? _refPrefs;

  TotalPlan? _cachedPlan;
  RefData? _cachedRef;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  int get targetAmount => _cachedPlan?.targetAmount ?? 0;

  int get draftPlanDailySum =>
      _draftPlan.fold(0, (p, e) => p + (e.dailyAmount ?? 0));

  // -----------------
  // Dirty (저장되지 않은 변경)
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

  String _fallbackEmojiByName(String name, {String fallback = '💰'}) {
    switch (name) {
      case '급여':
        return '💼';
      case '사업':
        return '🏢';
      case '배당':
        return '📈';
      case '용돈':
        return '🎁';
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

  void _normalizeOrders() {
    for (int i = 0; i < _draftPlan.length; i++) {
      _draftPlan[i] = _draftPlan[i].copyWith(order: i);
    }
    for (int i = 0; i < _draftRef.length; i++) {
      _draftRef[i] = _draftRef[i].copyWith(order: i);
    }
  }

  void _reorder(List<CategorySnapshotItem> list, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex > list.length) return;
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
  }

  DailyConsume? _pickDailyConsumeForDate({
    required DateTime date,
    required Iterable<DailyConsume> dailyConsumes,
  }) {
    final day = _normalizeDay(date);
    final candidates = dailyConsumes
        .where((d) => d.isActive)
        .where((d) =>
    !day.isBefore(_normalizeDay(d.startDate)) &&
        !day.isAfter(_normalizeDay(d.endDate)))
        .toList();

    if (candidates.isEmpty) return null;

    // 덮어쓰기 느낌: 가장 최근 시작이 우선
    candidates.sort((a, b) => b.startDate.compareTo(a.startDate));
    return candidates.first;
  }

  String _formatYearMonth(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}';

  String _nextMiniDocId(TotalPlan plan, DateTime applyDate) {
    final key = _formatYearMonth(applyDate);
    final subPlan = plan.subPlans[key];
    var maxSeq = 0;

    if (subPlan != null) {
      for (final id in subPlan.miniPlans.keys) {
        final parts = id.split('-');
        if (parts.length != 2) continue;
        final seq = int.tryParse(parts[1]) ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      }
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(3, '0');
    return '$key-$nextSeq';
  }

  // ===========================================================
  // 1) Load (금액까지 합성)
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
      _applyDate = _selectedDate;

      final plan = await _planRepo.getLatestPlanForCurrentUser();
      _cachedPlan = plan;

      final ref = await _refRepo.loadAll();
      _cachedRef = ref;

      final planMetaDoc = await _prefsRepo.getPlanMetaForDate(_selectedDate);
      final planMeta = planMetaDoc?.planMeta ?? <CategoryMetaItem>[];

      final refPrefs = await _prefsRepo.loadRefPrefs();
      _refPrefs = refPrefs;

      // daily amount source
      final daily = _pickDailyConsumeForDate(
        date: _selectedDate,
        dailyConsumes: ref.dailyConsumeMap.values,
      );
      final dailyEntries = daily?.entries ?? const <Entry>[];

      final amountByKey = <String, int>{};
      final nameByKey = <String, String>{};

      for (final e in dailyEntries) {
        final key =
        (e.categoryKey.trim().isNotEmpty) ? e.categoryKey.trim() : e.category.trim();
        amountByKey[key] = e.amount.round();
        nameByKey[key] = e.category;
      }

      // plan draft = meta 우선 + amount merge
      final builtPlan = <CategorySnapshotItem>[];

      for (final m in planMeta) {
        final key = m.categoryKey;
        builtPlan.add(
          CategorySnapshotItem(
            categoryId: key,
            name: m.name,
            emoji: m.emoji,
            order: m.order,
            dailyAmount: amountByKey[key] ?? 0,
          ),
        );
      }

      final existingKeys = builtPlan.map((e) => e.categoryId).toSet();
      int tailOrder = builtPlan.isEmpty
          ? 0
          : (builtPlan.map((e) => e.order).reduce(max) + 1);

      for (final key in amountByKey.keys) {
        if (existingKeys.contains(key)) continue;
        final name = nameByKey[key] ?? key;
        builtPlan.add(
          CategorySnapshotItem(
            categoryId: key,
            name: name,
            emoji: _fallbackEmojiByName(name),
            order: tailOrder++,
            dailyAmount: amountByKey[key] ?? 0,
          ),
        );
      }

      builtPlan.sort((a, b) => a.order.compareTo(b.order));
      _draftPlan = builtPlan;

      // ref draft (전역 pref 기반)
      _draftRef = refPrefs.refCategories
          .map(
            (m) => CategorySnapshotItem(
          categoryId: m.categoryKey,
          name: m.name,
          emoji: m.emoji,
          order: m.order,
          dailyAmount: null,
        ),
      )
          .toList();

      // endDate 결정: planMeta 있으면 그 end, 아니면 plan end
      if (planMetaDoc != null) {
        _endDate = planMetaDoc.endDate;
      } else {
        final endSource = plan?.modEndDate ?? plan?.endDate;
        _endDate = endSource != null ? _normalizeDay(endSource) : DateTime(2100, 12, 31);
      }

      _normalizeOrders();

      // ✅ 새로 로드되면 draft는 "저장된 상태"이므로 dirty 해제
      _dirty = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================
  // 2) Draft Editing APIs (기존 UI 호환)
  // ===========================================================

  void draftAddCategory({
    required bool isPlan,
    required String categoryId,
    required String name,
    required String emoji,
    int? dailyAmount,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final resolvedEmoji = (emoji.trim().isEmpty || emoji == '💰')
        ? _fallbackEmojiByName(trimmed, fallback: '💰')
        : emoji;

    final exists = _draftPlan.any((e) => e.name == trimmed) ||
        _draftRef.any((e) => e.name == trimmed);
    if (exists) return;

    if (isPlan) {
      _draftPlan.add(
        CategorySnapshotItem(
          categoryId: categoryId,
          name: trimmed,
          emoji: resolvedEmoji,
          order: _draftPlan.length,
          dailyAmount: dailyAmount ?? 0,
        ),
      );
    } else {
      _draftRef.add(
        CategorySnapshotItem(
          categoryId: categoryId,
          name: trimmed,
          emoji: resolvedEmoji,
          order: _draftRef.length,
          dailyAmount: null,
        ),
      );
    }

    _normalizeOrders();
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
      final dup = _draftPlan.any((e) => e.categoryId != categoryId && e.name == trimmedName) ||
          _draftRef.any((e) => e.categoryId != categoryId && e.name == trimmedName);
      if (dup) return;
    }

    bool changed = false;

    for (int i = 0; i < _draftPlan.length; i++) {
      final e = _draftPlan[i];
      if (e.categoryId == categoryId) {
        _draftPlan[i] = e.copyWith(
          name: trimmedName ?? e.name,
          emoji: emoji ?? e.emoji,
        );
        changed = true;
        break;
      }
    }

    if (!changed) {
      for (int i = 0; i < _draftRef.length; i++) {
        final e = _draftRef[i];
        if (e.categoryId == categoryId) {
          _draftRef[i] = e.copyWith(
            name: trimmedName ?? e.name,
            emoji: emoji ?? e.emoji,
          );
          break;
        }
      }
    }

    _markDirty();
  }

  void draftUpdateDailyAmount({
    required String categoryId,
    required int dailyAmount,
  }) {
    if (dailyAmount < 0) return;

    for (int i = 0; i < _draftPlan.length; i++) {
      final e = _draftPlan[i];
      if (e.categoryId == categoryId) {
        _draftPlan[i] = e.copyWith(dailyAmount: dailyAmount);
        _markDirty();
        return;
      }
    }
  }

  void draftDelete(String categoryId) {
    final before = _draftPlan.length + _draftRef.length;
    _draftPlan.removeWhere((e) => e.categoryId == categoryId);
    _draftRef.removeWhere((e) => e.categoryId == categoryId);
    _normalizeOrders();

    final after = _draftPlan.length + _draftRef.length;
    if (after != before) _markDirty();
  }

  void draftMoveRefToPlan({
    required String categoryId,
    required int newIndex,
    required int dailyAmount,
  }) {
    final fromIdx = _draftRef.indexWhere((e) => e.categoryId == categoryId);
    if (fromIdx == -1) return;
    if (dailyAmount < 0) return;

    final item = _draftRef.removeAt(fromIdx);
    final moved = item.copyWith(
      order: 0,
      dailyAmount: dailyAmount,
      clearDailyAmount: false,
    );

    final idx = newIndex.clamp(0, _draftPlan.length);
    _draftPlan.insert(idx, moved);

    _normalizeOrders();
    _markDirty();
  }

  void draftMovePlanToRef({
    required String categoryId,
    required int newIndex,
  }) {
    final fromIdx = _draftPlan.indexWhere((e) => e.categoryId == categoryId);
    if (fromIdx == -1) return;

    final item = _draftPlan.removeAt(fromIdx);
    final moved = item.copyWith(
      order: 0,
      clearDailyAmount: true,
    );

    final idx = newIndex.clamp(0, _draftRef.length);
    _draftRef.insert(idx, moved);

    _normalizeOrders();
    _markDirty();
  }

  void draftReorderPlan(int oldIndex, int newIndex) {
    _reorder(_draftPlan, oldIndex, newIndex);
    _normalizeOrders();
    _markDirty();
  }

  void draftReorderRef(int oldIndex, int newIndex) {
    _reorder(_draftRef, oldIndex, newIndex);
    _normalizeOrders();
    _markDirty();
  }

  // ===========================================================
  // 3) Save: PlanMutation + RefData 저장 + prefs 저장
  // ===========================================================

  Future<bool> saveDraftForSelectedDate() async {
    if (_isSaving) return false;
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // 최신 plan/ref
      final plan = await _planRepo.getLatestPlanForCurrentUser();
      if (plan == null) {
        _error = '저장할 플랜이 없습니다.';
        return false;
      }
      _cachedPlan = plan;

      final refData = await _refRepo.loadAll();
      _cachedRef = refData;

      final endSource = plan.modEndDate ?? plan.endDate ?? _applyDate;
      final endDate = _normalizeDay(endSource);

      // 1) draftPlan -> Entry
      final entries = <Entry>[];
      for (int i = 0; i < _draftPlan.length; i++) {
        final c = _draftPlan[i];
        entries.add(
          Entry(
            idx: i,
            amount: (c.dailyAmount ?? 0).toDouble(),
            categoryKey: c.categoryId,
            category: c.name,
            note: '',
            type: EntryType.daily,
          ),
        );
      }

      // 2) prevDailyId 결정(현재 날짜 커버하는 active daily)
      final prevDaily = _pickDailyConsumeForDate(
        date: _applyDate,
        dailyConsumes: refData.dailyConsumeMap.values,
      );
      final previousDailyId = prevDaily?.id;

      // 3) UpdateDailyCommand 만들고 mutation 적용
      final newDailyId =
          '${_formatYearMonth(_applyDate)}-${DateTime.now().millisecondsSinceEpoch}';
      final newMiniDocId = _nextMiniDocId(plan, _applyDate);

      final cmd = UpdateDailyCommand(
        applyDate: _applyDate,
        modEndDate: endDate,
        entries: entries,
        newDailyId: newDailyId,
        newMiniDocId: newMiniDocId,
        previousDailyId: previousDailyId,
        allowBeforePlanStart: false,
      );

      final snapshot = PlanSnapshot(
        totalPlan: plan,
        monthlyIncomes: Map.from(refData.monthlyIncomeMap),
        monthlyConsumes: Map.from(refData.monthlyConsumeMap),
        dailyConsumes: Map.from(refData.dailyConsumeMap),
      );

      final result = _mutationService.applyCommands(
        monthlyCommands: const [],
        dailyCommands: [cmd],
        snapshot: snapshot,
      );

      // 4) plan 저장
      await _planRepo.replacePlan(result.totalPlan);

      // 5) dailyConsumes 저장(최소: new + prev(있으면))
      final newDaily = result.dailyConsumes[newDailyId];
      if (newDaily == null) {
        throw StateError('Mutation result missing newDailyId=$newDailyId');
      }
      await _refRepo.saveDailyConsume(newDaily);

      if (previousDailyId != null) {
        final prevUpdated = result.dailyConsumes[previousDailyId];
        if (prevUpdated != null) {
          await _refRepo.saveDailyConsume(prevUpdated);
        }
      }

      // 6) prefs 저장(덮어쓰기 정책)
      final planMeta = _draftPlan
          .map(
            (e) => CategoryMetaItem(
          categoryKey: e.categoryId,
          name: e.name,
          emoji: e.emoji,
          order: e.order,
          hidden: false,
        ),
      )
          .toList();

      final planDoc = CategoryPlanMetaDoc(
        id: 'temp',
        applyDate: _applyDate,
        endDate: endDate,
        planMeta: planMeta,
        isActive: true,
      );
      await _prefsRepo.savePlanMetaOverwrite(draft: planDoc);

      final refMeta = _draftRef
          .map(
            (e) => CategoryMetaItem(
          categoryKey: e.categoryId,
          name: e.name,
          emoji: e.emoji,
          order: e.order,
          hidden: false,
        ),
      )
          .toList();
      await _prefsRepo.saveRefPrefs(CategoryRefPrefs(refCategories: refMeta));

      // 캐시
      _cachedPlan = result.totalPlan;
      _cachedRef = RefData(
        planId: result.totalPlan.planId,
        monthlyIncomes: result.monthlyIncomes,
        monthlyConsumes: result.monthlyConsumes,
        dailyConsumes: result.dailyConsumes,
      );

      // ✅ 저장 성공 → dirty 해제
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

  // -----------------------------------------------------------
  // 소비입력/편의 getter들
  // -----------------------------------------------------------
  List<String> get allCategoryNames {
    final set = <String>{};
    for (final e in _draftPlan) set.add(e.name);
    for (final e in _draftRef) set.add(e.name);
    return set.toList();
  }

  List<String> get refCategoryNames =>
      _draftRef.map((e) => e.name).toList(growable: false);

  List<String> get planCategoryNames =>
      _draftPlan.map((e) => e.name).toList(growable: false);

  Map<String, String> get categoryEmojiMap {
    final map = <String, String>{};
    for (final e in _draftPlan) map[e.name] = e.emoji;
    for (final e in _draftRef) map[e.name] = e.emoji;
    return map;
  }

  // ===========================================================
  // 4) PlanChat(입력 모달)에서 쓰는 ref 편의 API
  // ===========================================================

  /// 소비입력: ref 카테고리 이름으로 삭제
  void draftDeleteRefByName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final targets = _draftRef.where((e) => e.name == trimmed).toList();
    if (targets.isEmpty) return;

    for (final item in targets) {
      draftDelete(item.categoryId);
    }
  }

  /// 소비입력: ref 카테고리 이름으로 추가
  void draftAddRefCategoryByName({
    required String name,
    required String emoji,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final exists =
        _draftPlan.any((e) => e.name == trimmed) || _draftRef.any((e) => e.name == trimmed);
    if (exists) return;

    final resolvedEmoji = (emoji.trim().isEmpty || emoji == '💰')
        ? _fallbackEmojiByName(trimmed, fallback: '💰')
        : emoji;

    final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';

    _draftRef.add(
      CategorySnapshotItem(
        categoryId: newId,
        name: trimmed,
        emoji: resolvedEmoji,
        order: _draftRef.length,
        dailyAmount: null,
      ),
    );

    _normalizeOrders();
    _markDirty();
  }

  /// 소비입력: 이름 순서로 ref 재정렬
  void draftReorderRefByNames(List<String> orderedNames) {
    final map = {for (final e in _draftRef) e.name: e};
    final rebuilt = <CategorySnapshotItem>[];

    for (final name in orderedNames) {
      final item = map[name];
      if (item != null) rebuilt.add(item);
    }
    for (final e in _draftRef) {
      if (!orderedNames.contains(e.name)) rebuilt.add(e);
    }

    _draftRef = rebuilt;
    _normalizeOrders();
    _markDirty();
  }
}

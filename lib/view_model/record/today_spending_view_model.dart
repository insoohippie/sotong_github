import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../model/record/day_record.dart';
import '../../model/record/record_entry.dart';
import '../../model/plan/mini_plan.dart';
import '../../model/plan/plan_metrics.dart';
import '../../model/plan/sub_plan.dart';
import '../../repository/record_repository.dart';
import '../../repository/plan_repository.dart';
import '../../services/record_event_bus.dart';

class TodaySpendingViewModel extends ChangeNotifier {
  final RecordRepository _recordRepo;
  final PlanRepository _planRepo;
  final RecordEventBus _eventBus;

  TodaySpendingViewModel(this._recordRepo, this._planRepo, this._eventBus);

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime? _date;
  DateTime? get date => _date;

  DayRecord? _savedDay;
  DayRecord? _draftDay;
  DayRecord? get day => _draftDay;

  List<RecordEntry> get entries => _draftDay?.spendingEntries ?? const [];

  int get totalAmount {
    if (_draftDay == null) return 0;
    final sum = _draftDay!.spendingEntries
        .fold<double>(0, (s, e) => s + e.amount)
        .round();
    return sum;
  }

  int _dailyLimit = 0;
  int get dailyLimit => _dailyLimit;

  double _plannedDailyNet = 0;
  double get plannedDailyNet => _plannedDailyNet;

  double _plannedPerSecond = 0;
  double get plannedPerSecond => _plannedPerSecond;

  int get diffAmount => totalAmount - _dailyLimit;

  int get diffTimeMinutes {
    final diff = diffAmount.abs();
    if (diff <= 0 || _plannedPerSecond <= 0) return 0;
    return (diff / _plannedPerSecond / 60).round();
  }

  String get emotion => _draftDay?.emotion ?? '';
  String get comment => _draftDay?.comment ?? '';

  bool get hasUnsavedChanges => _hasDraftChanged(_savedDay, _draftDay);
  bool get hasEntryChanges {
    if (_savedDay == null || _draftDay == null) return false;
    if (_savedDay!.totalSpendingAmount != _draftDay!.totalSpendingAmount) {
      return true;
    }
    return !_sameEntries(
      _savedDay!.spendingEntries,
      _draftDay!.spendingEntries,
    );
  }

  Future<void> load(DateTime date) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _date = date;

      final month = await _recordRepo.loadMonthlyRecordByDate(date);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final loadedDay = month.days[dateKey];

      _savedDay = _cloneDay(loadedDay ?? DayRecord.empty(date));
      _draftDay = _cloneDay(_savedDay!);
      final budget = await _readDailyPlanBudgetForDate(date);
      _dailyLimit = budget.dailyLimit;
      _plannedDailyNet = budget.plannedDailyNet;
      _plannedPerSecond = budget.perSecondSaving;
      _recalcTotal();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<_DailyPlanBudget> _readDailyPlanBudgetForDate(DateTime date) async {
    try {
      final plan = (await _planRepo.getLatestPlanForCurrentUser())
          ?.recalculateTotals();
      if (plan == null) return const _DailyPlanBudget.empty();
      final normalized = _normalizeDay(date);
      final key = DateFormat('yyyyMM').format(normalized);
      final subPlan = plan.subPlans[key];
      if (subPlan == null) return const _DailyPlanBudget.empty();
      final mini = _miniForDate(subPlan, normalized);
      if (mini != null) {
        return _DailyPlanBudget.fromMini(mini);
      }
      return _DailyPlanBudget.fromMetrics(subPlan.monthlySummary());
    } catch (_) {
      return const _DailyPlanBudget.empty();
    }
  }

  MiniPlan? _miniForDate(SubPlan subPlan, DateTime date) {
    final normalized = _normalizeDay(date);
    for (final mini in subPlan.orderedMinis()) {
      final start = _normalizeDay(mini.startDate);
      final end = _normalizeDay(mini.endDate);
      if (!normalized.isBefore(start) && !normalized.isAfter(end)) {
        return mini;
      }
    }
    return null;
  }

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> addEntry({
    required String categoryKey,
    required String category,
    required double amount,
    required String note,
  }) async {
    if (_draftDay == null) return;

    final newEntry = RecordEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      categoryKey: categoryKey,
      category: category,
      amount: amount,
      note: note,
    );

    final newEntries = [..._draftDay!.spendingEntries, newEntry];

    _draftDay = _draftDay!.copyWith(
      spendingEntries: newEntries,
      totalSpendingAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();
  }

  Future<void> updateEntry({
    required String entryId,
    required String categoryKey,
    required String category,
    required double amount,
    required String note,
  }) async {
    if (_draftDay == null) return;

    final newEntries = _draftDay!.spendingEntries.map((e) {
      if (e.id != entryId) return e;
      return e.copyWith(
        categoryKey: categoryKey,
        category: category,
        amount: amount,
        note: note,
      );
    }).toList();

    _draftDay = _draftDay!.copyWith(
      spendingEntries: newEntries,
      totalSpendingAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();
  }

  Future<void> deleteEntry(String entryId) async {
    if (_draftDay == null) return;

    final newEntries = _draftDay!.spendingEntries
        .where((e) => e.id != entryId)
        .toList();

    _draftDay = _draftDay!.copyWith(
      spendingEntries: newEntries,
      totalSpendingAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();
  }

  Future<void> updateEmotionAndComment({
    required String emotion,
    required String comment,
  }) async {
    if (_savedDay == null) return;

    _savedDay = _savedDay!.copyWith(emotion: emotion, comment: comment);
    if (_draftDay != null) {
      _draftDay = _draftDay!.copyWith(emotion: emotion, comment: comment);
    }
    notifyListeners();

    await _persistDay('updateEmotion', _savedDay!);
  }

  void updateDiaryDraft({required String emotion, required String comment}) {
    if (_draftDay == null) return;

    _draftDay = _draftDay!.copyWith(emotion: emotion, comment: comment);
    notifyListeners();
  }

  void _recalcTotal() {
    if (_draftDay == null) return;
    final sum = _draftDay!.spendingEntries
        .fold<double>(0, (s, e) => s + e.amount)
        .round();
    _draftDay = _draftDay!.copyWith(totalSpendingAmount: sum);
  }

  Future<void> saveDraft() async {
    if (_draftDay == null) return;

    await _persistDay('saveDraft', _draftDay!);
    _savedDay = _cloneDay(_draftDay!);
    _draftDay = _cloneDay(_savedDay!);
    notifyListeners();
  }

  void discardDraft() {
    if (_savedDay == null) return;
    _draftDay = _cloneDay(_savedDay!);
    notifyListeners();
  }

  Future<void> _persistDay(String action, DayRecord day) async {
    final normalized = _recalculatedDay(day);

    final localMode = _recordRepo.localMode;
    await _recordRepo.upsertSpendingForDate(
      date: normalized.date,
      spendingEntries: normalized.spendingEntries,
      totalSpendingAmount: normalized.totalSpendingAmount,
      emotion: normalized.emotion,
      comment: normalized.comment,
    );

    debugPrint(
      '[TodaySpendingViewModel] $action persisted '
      '(date=${normalized.date}, localMode=$localMode)',
    );
    _eventBus.fire(RecordUpdatedEvent(normalized.date));
  }

  DayRecord _recalculatedDay(DayRecord day) {
    final total = day.spendingEntries
        .fold<double>(0, (sum, entry) => sum + entry.amount)
        .round();
    return day.copyWith(totalSpendingAmount: total);
  }

  DayRecord _cloneDay(DayRecord day) {
    return day.copyWith(
      spendingEntries: List<RecordEntry>.from(day.spendingEntries),
      incomeEntries: List<RecordEntry>.from(day.incomeEntries),
    );
  }

  bool _hasDraftChanged(DayRecord? saved, DayRecord? draft) {
    if (saved == null || draft == null) return false;
    if (saved.totalSpendingAmount != draft.totalSpendingAmount) return true;
    if (saved.emotion != draft.emotion) return true;
    if (saved.comment != draft.comment) return true;
    return !_sameEntries(saved.spendingEntries, draft.spendingEntries);
  }

  bool _sameEntries(List<RecordEntry> a, List<RecordEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.categoryKey != right.categoryKey ||
          left.category != right.category ||
          left.amount != right.amount ||
          left.note != right.note) {
        return false;
      }
    }
    return true;
  }
}

class _DailyPlanBudget {
  const _DailyPlanBudget({
    required this.dailyLimit,
    required this.plannedDailyNet,
    required this.perSecondSaving,
  });

  const _DailyPlanBudget.empty()
    : dailyLimit = 0,
      plannedDailyNet = 0,
      perSecondSaving = 0;

  factory _DailyPlanBudget.fromMini(MiniPlan mini) {
    final metrics = mini.toMetrics();
    return _DailyPlanBudget(
      dailyLimit: mini.dailyConsumeAmount,
      plannedDailyNet: metrics.dailyNetSaving.toDouble(),
      perSecondSaving: metrics.perSecondSaving,
    );
  }

  factory _DailyPlanBudget.fromMetrics(PlanMetrics metrics) {
    return _DailyPlanBudget(
      dailyLimit: metrics.dailyConsumeAmount,
      plannedDailyNet: metrics.dailyNetSaving.toDouble(),
      perSecondSaving: metrics.perSecondSaving,
    );
  }

  final int dailyLimit;
  final double plannedDailyNet;
  final double perSecondSaving;
}

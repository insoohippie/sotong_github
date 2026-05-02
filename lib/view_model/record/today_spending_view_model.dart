import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  DayRecord? _day;
  DayRecord? get day => _day;

  List<RecordEntry> get entries => _day?.spendingEntries ?? const [];

  int get totalAmount {
    if (_day == null) return 0;
    final sum = _day!.spendingEntries
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

  String get emotion => _day?.emotion ?? '';
  String get comment => _day?.comment ?? '';

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

      _day = loadedDay ?? DayRecord.empty(date);
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
    if (_day == null) return;

    final newEntry = RecordEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      categoryKey: categoryKey,
      category: category,
      amount: amount,
      note: note,
    );

    final newEntries = [..._day!.spendingEntries, newEntry];

    _day = _day!.copyWith(
      spendingEntries: newEntries,
      totalSpendingAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();

    await _persist('addEntry');
  }

  Future<void> updateEntry({
    required String entryId,
    required String categoryKey,
    required String category,
    required double amount,
    required String note,
  }) async {
    if (_day == null) return;

    final newEntries = _day!.spendingEntries.map((e) {
      if (e.id != entryId) return e;
      return e.copyWith(
        categoryKey: categoryKey,
        category: category,
        amount: amount,
        note: note,
      );
    }).toList();

    _day = _day!.copyWith(
      spendingEntries: newEntries,
      totalSpendingAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();

    await _persist('updateEntry');
  }

  Future<void> deleteEntry(String entryId) async {
    if (_day == null) return;

    final newEntries = _day!.spendingEntries
        .where((e) => e.id != entryId)
        .toList();

    _day = _day!.copyWith(
      spendingEntries: newEntries,
      totalSpendingAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();

    await _persist('deleteEntry');
  }

  Future<void> updateEmotionAndComment({
    required String emotion,
    required String comment,
  }) async {
    if (_day == null) return;

    _day = _day!.copyWith(emotion: emotion, comment: comment);
    notifyListeners();

    await _persist('updateEmotion');
  }

  void _recalcTotal() {
    if (_day == null) return;
    final sum = _day!.spendingEntries
        .fold<double>(0, (s, e) => s + e.amount)
        .round();
    _day = _day!.copyWith(totalSpendingAmount: sum);
  }

  Future<void> _persist(String action) async {
    if (_day == null) return;

    final localMode = _recordRepo.localMode;
    await _recordRepo.upsertSpendingForDate(
      date: _day!.date,
      spendingEntries: _day!.spendingEntries,
      totalSpendingAmount: _day!.totalSpendingAmount,
      emotion: _day!.emotion,
      comment: _day!.comment,
    );

    debugPrint(
      '[TodaySpendingViewModel] $action persisted '
      '(date=${_day!.date}, localMode=$localMode)',
    );
    _eventBus.fire(RecordUpdatedEvent(_day!.date));
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

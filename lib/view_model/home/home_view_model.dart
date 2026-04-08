import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/plan/total_plan.dart';
import '../../model/record/day_record.dart';
import '../../model/record/monthly_record.dart';
import '../../model/record/record_entry.dart';
import '../../model/saving_calculation_result.dart';
import '../../repository/auth_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/record_repository.dart';
import '../../services/record_event_bus.dart';
import '../services/saving_calculator.dart';
import '../../services/plan_saved_event_bus.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;
  final PlanSavedEventBus _planSavedBus;
  final RecordRepository _recordRepo;
  final RecordEventBus _recordEventBus;

  bool _handlingRecordEvent = false;

  StreamSubscription<void>? _planSavedSub;
  StreamSubscription<RecordUpdatedEvent>? _recordSub;

  HomeViewModel(
      this._authRepo,
      this._planRepo,
      this._planSavedBus,
      this._recordRepo,
      this._recordEventBus,
      ) {
    _planSavedSub = _planSavedBus.stream.listen((_) {
      refresh();
    });

    _recordSub = _recordEventBus.stream.listen((event) async {
      if (_isLoading || _handlingRecordEvent) return;
      _handlingRecordEvent = true;
      try {
        final savedDate = event.date;
        final monthKey = DateFormat('yyyy-MM').format(savedDate);

        _monthlyCache.remove(monthKey);
        await _ensureMonthlyLoaded(savedDate);
        await loadDailySummary(savedDate, ensureMonthlyLoaded: false);
      } finally {
        _handlingRecordEvent = false;
      }
    });
  }

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? _loadedUid;

  bool _initialized = false;

  String _name = '회원';
  String get name => _name;

  TotalPlan? _latestPlan;
  SavingCalculationResult? _calc;
  TotalPlan? get latestPlan => _latestPlan;
  SavingCalculationResult? get calc => _calc;

  bool _isRenaming = false;
  bool get isRenaming => _isRenaming;

  final ValueNotifier<int> secondTick = ValueNotifier<int>(0);
  Timer? _ticker;

  double _currentAsset = 0;
  double _snapshotAmount = 0;
  double _extraIncomeTotal = 0;
  double _savingPerSecond = 0;
  DateTime _snapshotAt = DateTime.now();
  DateTime? _goalDate;

  final Map<String, MonthlyRecord> _monthlyCache = {};
  Map<String, MonthlyRecord> get monthlyCache => _monthlyCache;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  int _todaySpending = 0;
  int get todaySpending => _todaySpending;

  int _todayIncome = 0;
  int get todayIncome => _todayIncome;

  Future<void> _ensureMonthlyLoaded(DateTime date) async {
    final monthKey = DateFormat('yyyy-MM').format(date);
    if (_monthlyCache.containsKey(monthKey)) return;

    try {
      final monthly = await _recordRepo.loadMonthlyRecord(monthKey);
      _monthlyCache[monthKey] = monthly;
    } catch (_) {
      _monthlyCache[monthKey] = MonthlyRecord.empty(monthKey);
    }
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (_loadedUid != currentUid) {
      _loadedUid = currentUid;
      _initialized = false;
      _monthlyCache.clear();
      _todaySpending = 0;
      _todayIncome = 0;
      _selectedDate = DateTime.now();

      _ticker?.cancel();
      try {
        secondTick.value = 0;
      } catch (_) {}
    }

    if (_initialized && !forceRefresh) {
      await loadDailySummary(_selectedDate);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _name = await _authRepo.getUserName();
      _latestPlan = await _planRepo.getLatestPlanForCurrentUser();

      if (_latestPlan != null && _hasMetrics(_latestPlan!)) {
        _calc = SavingPlanCalculator(plan: _latestPlan!).calculate();
      } else {
        _calc = null;
      }

      _savingPerSecond = _calc?.savingPerSecond ?? 0;
      _goalDate = _calc?.goalDateTime;

      if (_currentAsset == 0 &&
          _snapshotAmount == 0 &&
          _extraIncomeTotal == 0 &&
          _latestPlan != null) {
        _currentAsset = (_latestPlan?.currentAmount ?? 0).toDouble();
        _snapshotAt = DateTime.now();
      }

      _startTicker();

      await _ensureMonthlyLoaded(_selectedDate);
      await loadDailySummary(_selectedDate, ensureMonthlyLoaded: false);

      _initialized = true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePlanName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    _isRenaming = true;
    _error = null;
    notifyListeners();

    try {
      await _planRepo.updateLatestPlanName(trimmed);

      if (_latestPlan != null) {
        _latestPlan = _latestPlan!.copyWith(planName: trimmed);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isRenaming = false;
      notifyListeners();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      secondTick.value++;
    });
  }

  Future<void> changeDate(int days) async {
    final nextDate = _selectedDate.add(Duration(days: days));
    await loadDailySummary(nextDate);
  }

  Future<void> setSelectedDate(DateTime date) async {
    await loadDailySummary(date);
  }

  Future<void> loadDailySummary(
      DateTime date, {
        bool ensureMonthlyLoaded = true,
      }) async {
    _selectedDate = date;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _todaySpending = 0;
      _todayIncome = 0;
      notifyListeners();
      return;
    }

    try {
      if (ensureMonthlyLoaded) {
        await _ensureMonthlyLoaded(date);
      }

      final monthKey = DateFormat('yyyy-MM').format(date);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      final monthly = _monthlyCache[monthKey];
      final day = monthly?.days[dateKey];

      _todaySpending = day?.totalSpendingAmount ?? 0;
      _todayIncome = day?.totalIncomeAmount ?? 0;
    } catch (_) {
      _todaySpending = 0;
      _todayIncome = 0;
    }

    notifyListeners();
  }

  Future<void> loadDailySpending(
      DateTime date, {
        bool ensureMonthlyLoaded = true,
      }) async {
    await loadDailySummary(date, ensureMonthlyLoaded: ensureMonthlyLoaded);
  }

  Future<void> updateLocalDaySpending({
    required DateTime date,
    required int totalAmount,
    required String emotion,
    required String comment,
    required List<RecordEntry> entries,
  }) async {
    final monthKey = DateFormat('yyyy-MM').format(date);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final existingMonthly =
        _monthlyCache[monthKey] ?? await _recordRepo.loadMonthlyRecord(monthKey);

    final existingDay = existingMonthly.days[dateKey];

    final newDay = DayRecord(
      date: date,
      totalSpendingAmount: totalAmount,
      totalIncomeAmount: existingDay?.totalIncomeAmount ?? 0,
      emotion: emotion,
      comment: comment,
      spendingEntries: entries,
      incomeEntries: existingDay?.incomeEntries ?? const [],
    );

    final newDays = Map<String, DayRecord>.from(existingMonthly.days);
    newDays[dateKey] = newDay;

    final updatedMonthly = existingMonthly.copyWith(days: newDays);
    _monthlyCache[monthKey] = updatedMonthly;

    await _recordRepo.saveMonthlyRecord(updatedMonthly);

    if (DateFormat('yyyy-MM-dd').format(_selectedDate) == dateKey) {
      _todaySpending = totalAmount;
      _todayIncome = existingDay?.totalIncomeAmount ?? 0;
    }

    notifyListeners();
  }

  Duration? get liveRemaining {
    if (_goalDate == null) return null;
    return _goalDate!.difference(DateTime.now());
  }

  double get liveSavedAmount {
    final elapsedSeconds =
    max(0, DateTime.now().difference(_snapshotAt).inSeconds);
    final autoPart = _savingPerSecond * elapsedSeconds;

    return _currentAsset + _snapshotAmount + _extraIncomeTotal + autoPart;
  }

  String get liveSavedAmountText {
    return '${SavingPlanCalculator.formatAmount(liveSavedAmount)}원';
  }

  String get planTitle => _latestPlan?.planName ?? '플랜 없음';

  String get dailyLimitText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return '${SavingPlanCalculator.formatAmount(metrics.dailyConsumeAmount.toDouble())}원';
  }

  String get todayIncomeText {
    return '${SavingPlanCalculator.formatAmount(_todayIncome.toDouble())}원';
  }

  String get todaySpendingText {
    return '${SavingPlanCalculator.formatAmount(_todaySpending.toDouble())}원';
  }

  String get perSecondSaving => _savingPerSecond.toStringAsFixed(2);
  double get progressRatio => _calc?.savingRatio ?? 0.0;

  bool _hasMetrics(TotalPlan plan) {
    final metrics = plan.result.totalMetrics;
    final hasIncome = metrics.monthlyIncomeAmount > 0;
    final hasTarget = (plan.targetAmount ?? 0) > 0;
    final hasDaily = metrics.dailyConsumeAmount >= 0;
    return hasIncome && hasTarget && hasDaily;
  }

  void addLocalIncome(double amount) {
    _extraIncomeTotal += amount;
    notifyListeners();
  }

  void flushAutoSavingToSnapshot() {
    final elapsedSeconds =
    max(0, DateTime.now().difference(_snapshotAt).inSeconds);

    _snapshotAmount += _savingPerSecond * elapsedSeconds;
    _snapshotAt = DateTime.now();

    notifyListeners();
  }

  Future<void> refresh() => load(forceRefresh: true);

  void clearMemoryMonthlyCache() {
    _monthlyCache.clear();
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _ticker?.cancel();
    secondTick.dispose();
    _planSavedSub?.cancel();
    super.dispose();
  }
}
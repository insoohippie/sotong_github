import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/plan/total_plan.dart';
import '../../model/record/day_spending.dart';
import '../../model/record/monthly_spending.dart';
import '../../model/record/spending_entry.dart';
import '../../model/saving_calculation_result.dart';
import '../../repository/auth_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/record_repository.dart';
import '../../services/spending_event_bus.dart';
import '../services/saving_calculator.dart';
import '../../services/plan_saved_event_bus.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;
  final PlanSavedEventBus _planSavedBus;
  final RecordRepository _recordRepo;
  final SpendingEventBus _spendingBus;

  bool _handlingSpendingEvent = false;

  StreamSubscription<void>? _planSavedSub;
  StreamSubscription<SpendingUpdatedEvent>? _spendingSub;

  HomeViewModel(
      this._authRepo,
      this._planRepo,
      this._planSavedBus,
      this._recordRepo,
      this._spendingBus,
      ) {
    _planSavedSub = _planSavedBus.stream.listen((_) {
      refresh();
    });
    _spendingSub = _spendingBus.stream.listen((event) async {
      if (_isLoading || _handlingSpendingEvent) return;
      _handlingSpendingEvent = true;
      try {
        final savedDate = event.date;
        final monthKey = DateFormat('yyyy-MM').format(savedDate);

        _monthlyCache.remove(monthKey);
        await _ensureMonthlyLoaded(savedDate);
        await loadDailySpending(_selectedDate, ensureMonthlyLoaded: false);
      } finally {
        _handlingSpendingEvent = false;
      }
    });

  }

  // ---------- 상태 ----------
  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? _loadedUid;

  bool _initialized = false;

  // 프로필
  String _name = '회원';
  String get name => _name;

  // 플랜 스냅샷
  TotalPlan? _latestPlan;
  SavingCalculationResult? _calc;
  TotalPlan? get latestPlan => _latestPlan;
  SavingCalculationResult? get calc => _calc;

  // 이름 변경 진행 상태
  bool _isRenaming = false;
  bool get isRenaming => _isRenaming;

  // ---------- 실시간(1초) 갱신 ----------
  final ValueNotifier<int> secondTick = ValueNotifier<int>(0);
  Timer? _ticker;

  // 자동 저축 + 모인 금액 계산 기준 값들 (Firestore 기준)
  double _currentAsset = 0;
  double _snapshotAmount = 0;
  double _extraIncomeTotal = 0;
  double _savingPerSecond = 0;
  DateTime _snapshotAt = DateTime.now();
  DateTime? _goalDate;

  // ---------- 소비 캐시 (메모리) ----------
  // key: 'yyyy-MM'
  final Map<String, MonthlySpending> _monthlyCache = {};
  Map<String, MonthlySpending> get monthlyCache => _monthlyCache;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  int _todaySpending = 0;
  int get todaySpending => _todaySpending;

  // ---------- Firestore에서 저축 스냅샷 읽기 ----------
  Future<void> _loadSavingBaseState() async {
    final data = await _planRepo.getSavingStateForCurrentUser();
    if (data == null) return;

    _currentAsset = (data['currentAsset'] as num?)?.toDouble() ?? 0.0;
    _snapshotAmount = (data['snapshotAmount'] as num?)?.toDouble() ?? 0.0;
    _extraIncomeTotal =
        (data['extraIncomeTotal'] as num?)?.toDouble() ?? 0.0;

    final rawSnapshotAt = data['snapshotAt'];
    if (rawSnapshotAt is Timestamp) {
      _snapshotAt = rawSnapshotAt.toDate();
    } else if (rawSnapshotAt is String) {
      _snapshotAt = DateTime.tryParse(rawSnapshotAt) ?? DateTime.now();
    } else {
      _snapshotAt = DateTime.now();
    }
  }

  // ---------- 월 로딩 (Repo 중심) ----------
  Future<void> _ensureMonthlyLoaded(DateTime date) async {
    final monthKey = DateFormat('yyyy-MM').format(date);
    if (_monthlyCache.containsKey(monthKey)) return;

    try {
      final monthly = await _recordRepo.loadMonthlySpending(monthKey);
      _monthlyCache[monthKey] = monthly;
    } catch (_) {
      _monthlyCache[monthKey] = MonthlySpending.empty(monthKey);
    }
  }

  // ---------- 로드 ----------
  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // uid 변경 감지 -> 메모리 캐시 리셋
    if (_loadedUid != currentUid) {
      _loadedUid = currentUid;
      _initialized = false;
      _monthlyCache.clear();
      _todaySpending = 0;

      _ticker?.cancel();
      try { secondTick.value = 0; } catch (_) {}
    }

    if (_initialized && !forceRefresh) {
      await loadDailySpending(DateTime.now());
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1) 사용자 이름
      _name = await _authRepo.getUserName();

      // 2) 최신 플랜
      _latestPlan = await _planRepo.getLatestPlanForCurrentUser();

      // 3) 플랜 기반 계산 결과
      if (_latestPlan != null && _hasMetrics(_latestPlan!)) {
        _calc = SavingPlanCalculator(plan: _latestPlan!).calculate();
      } else {
        _calc = null;
      }

      _savingPerSecond = _calc?.savingPerSecond ?? 0;
      _goalDate = _calc?.goalDateTime;

      // 4) Firestore 스냅샷 값 로드
      await _loadSavingBaseState();

      if (_currentAsset == 0 &&
          _snapshotAmount == 0 &&
          _extraIncomeTotal == 0 &&
          _latestPlan != null) {
        _currentAsset = (_latestPlan?.currentAmount ?? 0).toDouble();
        _snapshotAt = DateTime.now();
      }

      // 5) 1초 타이머 시작
      _startTicker();

      // 6) 이번 달 소비 월 데이터 로드 + 오늘 지출 갱신
      await _ensureMonthlyLoaded(DateTime.now());
      await loadDailySpending(DateTime.now(), ensureMonthlyLoaded: false);

      _initialized = true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- 플랜 이름 변경 ----------
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

  // ---------- 타이머 ----------
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      secondTick.value++;
    });
  }

  // ---------- 날짜별 지출 (Repo + 메모리 캐시) ----------
  Future<void> loadDailySpending(
      DateTime date, {
        bool ensureMonthlyLoaded = true,
      }) async {
    _selectedDate = date;

    // 로그인 안 된 상태면 0 처리
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _todaySpending = 0;
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
      debugPrint('[HOME] monthKey=$monthKey hasDays=${monthly?.days.length}');
      debugPrint('[HOME] dateKey=$dateKey hasDay=${monthly?.days.containsKey(dateKey)}');
      final day = monthly?.days[dateKey];

      _todaySpending = day?.totalAmount ?? 0;
    } catch (_) {
      _todaySpending = 0;
    }

    notifyListeners();
  }

  // ---------- 저장 후 캐시 즉시 반영 + Repo 저장 ----------
  Future<void> updateLocalDaySpending({
    required DateTime date,
    required int totalAmount,
    required String emotion,
    required String comment,
    required List<SpendingEntry> entries,
  }) async {
    final monthKey = DateFormat('yyyy-MM').format(date);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // 1) 월 데이터 확보 (메모리 or repo)
    final existingMonthly =
        _monthlyCache[monthKey] ?? await _recordRepo.loadMonthlySpending(monthKey);

    // 2) DaySpending 구성
    final newDay = DaySpending(
      date: date,
      totalAmount: totalAmount,
      emotion: emotion,
      comment: comment,
      entries: entries,
    );

    // 3) 메모리 캐시 업데이트
    final newDays = Map<String, DaySpending>.from(existingMonthly.days);
    newDays[dateKey] = newDay;

    final updatedMonthly = existingMonthly.copyWith(days: newDays);
    _monthlyCache[monthKey] = updatedMonthly;

    // 4) repo 저장 (Hive/Firestore는 repo가 담당)
    await _recordRepo.saveMonthlySpending(updatedMonthly);

    // 5) 선택 날짜면 todaySpending 갱신
    if (DateFormat('yyyy-MM-dd').format(_selectedDate) == dateKey) {
      _todaySpending = totalAmount;
    }

    notifyListeners();
  }

  // ---------- 실시간 Getter ----------
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
    return SavingPlanCalculator.formatAmount(liveSavedAmount) + '원';
  }

  String get planTitle => _latestPlan?.planName ?? '플랜 없음';

  String get dailyLimitText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return SavingPlanCalculator.formatAmount(
      metrics.sumDailyConsume.toDouble(),
    ) +
        '원';
  }

  String get perSecondSaving => _savingPerSecond.toStringAsFixed(2);
  double get progressRatio => _calc?.savingRatio ?? 0.0;

  bool _hasMetrics(TotalPlan plan) {
    final metrics = plan.result.totalMetrics;
    final hasIncome = metrics.sumMonthlyIncome > 0;
    final hasTarget = (plan.targetAmount ?? 0) > 0;
    final hasDaily = metrics.sumDailyConsume >= 0;
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

  /// (선택) 홈에서 월 캐시를 강제로 비우고 싶을 때
  void clearMemoryMonthlyCache() {
    _monthlyCache.clear();
  }

  @override
  void dispose() {
    _spendingSub?.cancel();
    _ticker?.cancel();
    secondTick.dispose();
    _planSavedSub?.cancel();
    super.dispose();
  }
}

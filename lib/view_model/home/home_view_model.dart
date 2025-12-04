import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../model/plan/total_plan.dart';
import '../../model/saving_calculation_result.dart';
import '../../repository/auth_repository.dart';
import '../../repository/plan_repository.dart';
import '../services/saving_calculator.dart';
import '../../services/plan_saved_event_bus.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;
  final PlanSavedEventBus _planSavedBus;
  StreamSubscription<void>? _planSavedSub;

  HomeViewModel(
      this._authRepo,
      this._planRepo,
      this._planSavedBus,
      ) {
    _planSavedSub = _planSavedBus.stream.listen((_) {
      refresh();
    });
  }

  // ---------- 상태 ----------
  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  // 실시간 계산 기준점
  DateTime _baseNow = DateTime.now();
  double _baseSaved = 0;
  double _savingPerSecond = 0;
  DateTime? _goalDate;

  // 🔥 추가: 선택한 날짜 지출 관리
  int _todaySpending = 0;
  int get todaySpending => _todaySpending;

  // ---------- 로드 ----------
  Future<void> load() async {
    if (_isLoading) return;
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

      _baseNow = DateTime.now();
      _baseSaved = (_latestPlan?.currentAmount ?? 0).toDouble();
      _savingPerSecond = _calc?.savingPerSecond ?? 0;
      _goalDate = _calc?.goalDateTime;

      _startTicker();

      // 🔥 오늘 지출 하드코딩 로드
      await loadDailySpending(DateTime.now());

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

  // 🔥 하드코딩된 지출 불러오기
  Future<void> loadDailySpending(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200)); // UI 부드럽게
    // TODO: Firestore 연결되면 아래 라인 교체 예정
    _todaySpending = _mockDailySpending(date);
    notifyListeners();
  }

  /// 단순 데모용 하드코딩 로직
  int _mockDailySpending(DateTime date) {
    final day = date.day;
    const amounts = {
      1: 8500,
      2: 6200,
      3: 0,
      4: 12000,
      5: 5600,
      6: 7800,
      7: 0,
      8: 4500,
      9: 9200,
      10: 6800,
    };
    return amounts[day] ?? 0;
  }

  // ---------- 실시간 Getter ----------
  Duration? get liveRemaining {
    if (_goalDate == null) return null;
    return _goalDate!.difference(DateTime.now());
  }

  String get liveSavedAmountText {
    return SavingPlanCalculator.formatAmount(liveSavedAmount) + '원';
  }

  double get liveSavedAmount {
    final secs = max(0, DateTime.now().difference(_baseNow).inSeconds);
    return _baseSaved + _savingPerSecond * secs;
  }

  String get planTitle => _latestPlan?.planName ?? '플랜 없음';

  String get dailyLimitText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return SavingPlanCalculator.formatAmount(metrics.sumDailyConsume.toDouble()) + '원';
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

  Future<void> refresh() => load();

  @override
  void dispose() {
    _ticker?.cancel();
    secondTick.dispose();
    _planSavedSub?.cancel();
    super.dispose();
  }
}

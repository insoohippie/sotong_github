import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../model/plan_info.dart';
import '../../model/saving_calculation_result.dart';
import '../../repository/auth_repository.dart';
import '../../repository/plan_repository.dart';
import '../services/saving_calculator.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;

  HomeViewModel(this._authRepo, this._planRepo);

  // ---------- 상태 ----------
  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 프로필
  String _name = '회원';
  String get name => _name;

  // 플랜 스냅샷
  PlanInfo? _latestPlan;
  SavingCalculationResult? _calc;
  PlanInfo? get latestPlan => _latestPlan;
  SavingCalculationResult? get calc => _calc;

  // 이름 변경 진행 상태
  bool _isRenaming = false;
  bool get isRenaming => _isRenaming;

  // ---------- 실시간(1초) 갱신 ----------
  final ValueNotifier<int> secondTick = ValueNotifier<int>(0);
  Timer? _ticker;

  // 실시간 계산 기준점(로드 완료 시 고정)
  late DateTime _baseNow;
  double _baseSaved = 0;              // 스냅샷 시점 누적 저축액(있으면 반영, 없으면 0)
  double _savingPerSecond = 0;        // 초당 저축액
  DateTime? _goalDate;                // 목표일

  // ---------- 로드 ----------
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1) 사용자 이름
      _name = await _authRepo.getUserName();

      // 2) 최신 플랜
      _latestPlan = await _planRepo.getLatestPlanForCurrentUser();

      // 3) 계산 스냅샷
      if (_latestPlan != null &&
          _latestPlan!.fixedIncomeSum != null &&
          _latestPlan!.fixedConsumptionSum != null &&
          _latestPlan!.dailyConsumptionSum != null &&
          _latestPlan!.targetAmount != null) {
        _calc = SavingPlanCalculator(planInfo: _latestPlan!).calculate();
      } else {
        _calc = null;
      }

      // 4) 실시간 계산 기준 설정
      _baseNow = DateTime.now();
      _baseSaved = _latestPlan?.currentAmount ?? 0;
      _savingPerSecond = _calc?.savingPerSecond ?? 0;
      _goalDate = _calc?.goalDateTime;

      _startTicker();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      secondTick.value++; // 이걸 리스닝하는 위젯만 리빌드됨
    });
  }

  // ---------- 실시간 Getter ----------
  Duration? get liveRemaining {
    if (_goalDate == null) return null;
    return _goalDate!.difference(DateTime.now());
  }

  String get liveCountdownText {
    final remain = liveRemaining;
    if (remain == null) return '—';
    if (remain.isNegative) return '달성 완료';
    final d = remain.inDays;
    final h = remain.inHours % 24;
    final m = remain.inMinutes % 60;
    final s = remain.inSeconds % 60;
    return '${d}일 : ${h.toString().padLeft(2, '0')}시 : '
        '${m.toString().padLeft(2, '0')}분 : ${s.toString().padLeft(2, '0')}초';
  }

  double get liveSavedAmount {
    final secs = max(0, DateTime.now().difference(_baseNow).inSeconds);
    return _baseSaved + _savingPerSecond * secs;
  }

  String get liveSavedAmountText {
    return SavingPlanCalculator.formatAmount(liveSavedAmount) + '원';
  }

  // ---------- UI 헬퍼 ----------
  String get planTitle => _latestPlan?.planName ?? '플랜 없음';

  String get dailyLimitText {
    final v = _latestPlan?.dailyConsumptionSum;
    if (v == null) return '—';
    return SavingPlanCalculator.formatAmount(v) + '원';
  }

  String get perSecondSaving => _savingPerSecond.toStringAsFixed(2);

  double get progressRatio => _calc?.savingRatio ?? 0.0;

  // ---------- 최신 플랜 이름 변경 ----------
  Future<bool> updatePlanName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    _isRenaming = true;
    _error = null;
    notifyListeners();

    try {
      // 서버 반영
      await _planRepo.updateLatestPlanName(trimmed);

      // 로컬 상태 즉시 반영(낙관적 업데이트)
      if (_latestPlan != null) {
        _latestPlan = PlanInfo.fromMap({
          ..._latestPlan!.toMap(),
          'planName': trimmed,
        });
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

  Future<void> refresh() => load();

  @override
  void dispose() {
    _ticker?.cancel();
    secondTick.dispose();
    super.dispose();
  }
}

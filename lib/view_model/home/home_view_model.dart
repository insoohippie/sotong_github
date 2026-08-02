import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/plan/total_plan.dart';
import '../../model/plan/mini_plan.dart'; //세은님 추가부분
import '../../model/plan/sub_plan.dart'; //세은님 추가부분
import '../../model/record/day_record.dart';
import '../../model/record/monthly_record.dart';
import '../../model/record/record_entry.dart';
import '../../model/saving_calculation_result.dart';
import '../../repository/auth_repository.dart';
import '../../repository/past_plan_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/record_repository.dart';
import '../../repository/ref_data_repository.dart'; //세은님 추가부분
import '../../model/refData/entry.dart';
import '../../model/refData/ref_data.dart'; //세은님 추가부분
import '../../services/record_event_bus.dart'; //하경 수정 부분 - spending_event_bus -> record_event_bus로 바뀜(수입, 지출 이벤트 전부 관리)
import '../services/saving_calculator.dart';
import '../../model/setting/past_plan_snapshot.dart';
import '../../services/plan_saved_event_bus.dart';
import '../../services/home_graph_intro_storage.dart';
import '../../services/home_widget_sync_service.dart';
import '../../services/plan_celebration_storage.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;
  final PlanSavedEventBus _planSavedBus;
  final RecordRepository _recordRepo;
  final RecordEventBus _recordEventBus;
  final RefDataRepository _refDataRepo; //세은님 추가부분

  bool _handlingRecordEvent = false;

  StreamSubscription<void>? _planSavedSub;
  StreamSubscription<RecordUpdatedEvent>? _recordSub;

  HomeViewModel(
      this._authRepo,
      this._planRepo,
      this._planSavedBus,
      this._recordRepo,
      this._recordEventBus,
      this._refDataRepo, //세은님 추가부분
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
        await _rebuildDailyNetThroughToday();
        await loadDailySummary(
          savedDate,
          ensureMonthlyLoaded: false,
        ); // 세은 추가 후 하경 수정 loadDailySpending -> loadDailySummary
        unawaited(_syncHomeWidget());
      } finally {
        _handlingRecordEvent = false;
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
  bool _shouldShowPlanGraphIntro = false;
  bool get shouldShowPlanGraphIntro => _shouldShowPlanGraphIntro;

  // 플랜 완료(목표 금액 달성) 상태 — true인 동안 홈 대신 celebration으로 잠금
  bool _shouldShowPlanCelebration = false;
  bool get shouldShowPlanCelebration => _shouldShowPlanCelebration;
  bool _completionPersistStarted = false;

  // 프로필
  String _name = '회원';
  String get name => _name;

  // 플랜 스냅샷
  TotalPlan? _latestPlan;
  SavingCalculationResult? _calc;
  RefData? _refData; //세은님 추가부분
  TotalPlan? get latestPlan => _latestPlan;
  SavingCalculationResult? get calc => _calc;

  // 이름 변경 진행 상태
  bool _isRenaming = false;
  bool get isRenaming => _isRenaming;

  // ---------- 실시간(1초) 갱신 ----------
  final ValueNotifier<int> secondTick = ValueNotifier<int>(0);
  Timer? _ticker;

  // 자동 저축 + 모인 금액 계산 기준 값들
  // 세은님 수정 부분
  bool _autoFillRunning = false;
  final Map<String, _DailyNet> _dailyNet = {};
  double _actualSavedThroughConfirmedDays = 0;
  DateTime _guideStart = DateTime.now();
  DateTime? _guideLockUntil;
  DateTime _todayAnchor = DateTime.now();
  bool _dayBoundaryRefreshRunning = false;

  // ---------- 기록 캐시 (메모리) ----------
  // key: 'yyyy-MM'
  final Map<String, MonthlyRecord> _monthlyCache = {};
  Map<String, MonthlyRecord> get monthlyCache => _monthlyCache;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  int _todaySpending = 0;
  int get todaySpending => _todaySpending;

  // 하경 추가 부분 (추가 수입)
  int _todayIncome = 0;
  int get todayIncome => _todayIncome;

  // 하경 추가 부분
  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // 하경 추가 부분
  DateTime? get _planStartDate {
    final plan = _latestPlan;
    if (plan == null) return null;
    final raw = plan.startDate ?? plan.creationDate;
    return raw == null ? null : _normalizeDate(raw);
  }

  // 하경 추가 부분
  DateTime? get _planEndDate {
    final plan = _latestPlan;
    if (plan == null) return null;
    final raw = plan.modEndDate ?? plan.endDate;
    return raw == null ? null : _normalizeDate(raw);
  }

  // 하경 추가 부분
  DateTime _clampDateToAllowedRange(DateTime date) {
    DateTime normalized = _normalizeDate(date);

    final planStart = _planStartDate;
    if (planStart != null && normalized.isBefore(planStart)) {
      normalized = planStart;
    }

    final planEnd = _planEndDate;
    if (planEnd != null && normalized.isAfter(planEnd)) {
      normalized = planEnd;
    }

    return normalized;
  }

  // ---------- 월 로딩 (Repo 중심) ----------
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

      // 하경 추가
      _todayIncome = 0;
      _selectedDate = DateTime.now();
      _shouldShowPlanGraphIntro = false;

      // 세은 추가
      _dailyNet.clear();
      _actualSavedThroughConfirmedDays = 0;
      _guideStart = _normalizeDay(DateTime.now());
      _guideLockUntil = null;
      _todayAnchor = _normalizeDay(DateTime.now());

      _ticker?.cancel();
      try {
        secondTick.value = 0;
      } catch (_) {}
    }

    if (_initialized && !forceRefresh) {
      _refreshPlanForToday();
      await _autoFillMissingDays();
      await _rebuildDailyNetThroughToday();
      await loadDailySummary(
        _selectedDate,
      ); // 세은 추가 후 하경 수정 loadDailySpending(DateTime.now()); -> loadDailySummary(_selectedDate);
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
      _refData = await _refDataRepo.loadAll(); //세은님 추가 부분
      _refreshPlanForToday();
      _refreshPlanGraphIntroState();
      _refreshPlanCelebrationState();

      _selectedDate = _clampDateToAllowedRange(_selectedDate);

      await _autoFillMissingDays(); // 세은님 추가 부분
      await _rebuildDailyNetThroughToday();

      // 4) 1초 타이머 시작
      _startTicker();

      // 5) 이번 달 기록 로드 + 오늘 지출 갱신 (주석 부분: 함수명 다름. 세은님 작업은 DateTime.now 사용)
      // await _ensureMonthlyLoaded(DateTime.now());
      // await loadDailySpending(DateTime.now(), ensureMonthlyLoaded: false);
      await _ensureMonthlyLoaded(_selectedDate);
      await loadDailySummary(_selectedDate, ensureMonthlyLoaded: false);

      _initialized = true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
      unawaited(_syncHomeWidget());
    }
  }

  Future<void> _syncHomeWidget() async {
    final hasPlan = _latestPlan != null;
    await HomeWidgetSyncService.syncPlanData(
      planName: planTitle,
      planPercent: planProgressPercentValue,
      dDayText: HomeWidgetSyncService.formatDDayText(liveRemaining),
      hasPlan: hasPlan,
    );
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

  void _refreshPlanGraphIntroState() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final planId = _latestPlan?.planId;
    if (uid == null || planId == null || planId.isEmpty) {
      _shouldShowPlanGraphIntro = false;
      return;
    }

    _shouldShowPlanGraphIntro = !HomeGraphIntroStorage.instance.hasSeen(
      uid: uid,
      planId: planId,
    );
  }

  Future<void> markPlanGraphIntroSeen() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final planId = _latestPlan?.planId;

    _shouldShowPlanGraphIntro = false;
    notifyListeners();

    if (uid == null || planId == null || planId.isEmpty) return;
    await HomeGraphIntroStorage.instance.markSeen(uid: uid, planId: planId);
  }

  // ---------- 플랜 완료(목표 금액 달성) 감지 ----------
  void _refreshPlanCelebrationState() {
    // 플랜이 바뀌었을 수 있으므로(새 플랜 생성 등) 완료 상태를 다시 계산한다.
    _shouldShowPlanCelebration = false;
    _completionPersistStarted = false;
    _checkPlanCelebration();
  }

  void _checkPlanCelebration({bool notify = false}) {
    if (_shouldShowPlanCelebration) {
      // 표시가 보류될 수 있으므로(홈이 최상단이 아닐 때) 재통지로 재시도를 유도한다.
      if (notify) notifyListeners();
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final planId = _latestPlan?.planId;
    if (uid == null || planId == null || planId.isEmpty) return;

    // 이미 완료 처리된 플랜: 재접속·재빌드 시에도 celebration 잠금 유지
    if (PlanCelebrationStorage.instance
        .isPlanCompleted(uid: uid, planId: planId)) {
      _shouldShowPlanCelebration = true;
      if (notify) notifyListeners();
      return;
    }

    if (!hasReachedSavingTarget) return;

    _shouldShowPlanCelebration = true;
    unawaited(_persistPlanCompletion(uid: uid, planId: planId));
    if (notify) notifyListeners();
  }

  /// 완료 감지 시점에 스냅샷과 완료 상태를 즉시 영속화한다.
  /// 표시 여부와 무관하게 기록되므로, 표시 전에 앱이 종료돼도
  /// 재접속 시 celebration으로 라우팅된다.
  Future<void> _persistPlanCompletion({
    required String uid,
    required String planId,
  }) async {
    if (_completionPersistStarted) return;
    _completionPersistStarted = true;

    final snapshot = buildCompletionSnapshot();
    if (snapshot != null) {
      await PastPlanRepository().add(snapshot);
    }
    await PlanCelebrationStorage.instance.markCompleted(
      uid: uid,
      planId: planId,
      planName: snapshot?.planName ?? planTitle,
      daysTaken: snapshot?.daysTaken ?? 0,
      completedAt: DateTime.now(),
    );
  }

  /// 저장된 완료 정보 {planId, planName, daysTaken, completedAt} (없으면 null)
  Map<String, dynamic>? get planCompletionInfo {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return PlanCelebrationStorage.instance.completedInfo(uid: uid);
  }

  /// 목표 달성 시점의 실데이터로 지난 플랜 스냅샷을 생성.
  /// (_persistPlanCompletion이 완료 감지 시 1회 저장해 '지난 플랜 돌아보기'에서 사용)
  PastPlanSnapshot? buildCompletionSnapshot() {
    final plan = _latestPlan;
    if (plan == null) return null;

    final now = DateTime.now();
    final today = _normalizeDay(now);
    final rawStart = plan.startDate ?? plan.creationDate;
    final start = rawStart != null ? _normalizeDay(rawStart) : today;
    final daysTaken = max(1, today.difference(start).inDays + 1);

    // 절제 달성률: 소비를 기록한 날 중 하루 예산을 지킨 날의 비율
    var recordedDays = 0;
    var withinBudgetDays = 0;
    _dailyNet.forEach((_, net) {
      if (net.date.isAfter(today)) return;
      if (!net.hasSpendingEntries) return;
      recordedDays++;
      if (net.actualSpending <= net.plannedBudget) withinBudgetDays++;
    });
    final restraintProgress = recordedDays > 0
        ? ((withinBudgetDays / recordedDays) * 100).round()
        : 0;

    final target = effectiveTargetAmount;
    final targetProgress = target > 0
        ? ((actualSavedNow / target) * 100).clamp(0, 999).round()
        : 0;
    final savingProgress = ((_calc?.savingRatio ?? 0) * 100).round();

    // 감정/카테고리/일지: 로드된 월 기록에서 플랜 기간(시작일~오늘)만 집계
    final emotionCounts = <String, int>{};
    final categorySpending = <String, double>{};
    final dayRecords = <DayRecord>[];
    _monthlyCache.forEach((_, monthly) {
      monthly.days.forEach((_, day) {
        final date = _normalizeDay(day.date);
        if (date.isBefore(start) || date.isAfter(today)) return;
        dayRecords.add(day);
      });
    });
    dayRecords.sort((a, b) => b.date.compareTo(a.date));

    final diaries = <Map<String, dynamic>>[];
    for (final day in dayRecords) {
      if (day.emotion.isNotEmpty) {
        emotionCounts[day.emotion] = (emotionCounts[day.emotion] ?? 0) + 1;
      }
      for (final entry in day.spendingEntries) {
        final key = entry.category.isNotEmpty ? entry.category : '기타';
        categorySpending[key] = (categorySpending[key] ?? 0) + entry.amount;
      }
      if (_isManuallyRecordedDay(day) && diaries.length < 30) {
        diaries.add({
          'date': day.date.toIso8601String(),
          'totalAmount': day.totalSpendingAmount,
          'emotion': day.emotion,
          'comment': day.comment,
        });
      }
    }

    return PastPlanSnapshot(
      id: '${plan.planId}_${now.millisecondsSinceEpoch}',
      planName: planTitle,
      completedAt: now,
      daysTaken: daysTaken,
      startDate: start,
      endDate: today,
      restraintProgress: restraintProgress,
      targetProgress: targetProgress,
      savingProgress: savingProgress,
      emotionCounts: emotionCounts,
      categorySpending: categorySpending,
      diaries: diaries,
      averagePace: (_calc?.savingRatio ?? 0).toStringAsFixed(2),
      averageDailySaving: averageDailySaving.round(),
    );
  }

  // ---------- 타이머 ----------
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      secondTick.value++;
      _scheduleDayBoundaryRefreshIfNeeded();
      _checkPlanCelebration(notify: true);
    });
  }

  // 하경 추가(날짜 변경을 뷰모델에서 관리하게 하고 싶어서)
  Future<void> changeDate(int days) async {
    final nextDate = _selectedDate.add(Duration(days: days));
    final clampedDate = _clampDateToAllowedRange(nextDate);

    if (_normalizeDate(clampedDate) == _normalizeDate(_selectedDate)) {
      return;
    }

    await loadDailySummary(clampedDate);
  }

  // 하경 추가(날짜 변경을 뷰모델에서 관리하게 하고 싶어서)
  Future<void> setSelectedDate(DateTime date) async {
    final clampedDate = _clampDateToAllowedRange(date);
    await loadDailySummary(clampedDate);
  }

  // ---------- 날짜별 소비/수입 요약 ----------
  Future<void> loadDailySummary(
      DateTime date, {
        bool ensureMonthlyLoaded = true,
      }) async {
    _selectedDate = _clampDateToAllowedRange(date);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _todaySpending = 0;
      _todayIncome = 0; // 하경 추가
      notifyListeners();
      return;
    }

    try {
      if (ensureMonthlyLoaded) {
        await _ensureMonthlyLoaded(_selectedDate);
      }

      final monthKey = DateFormat('yyyy-MM').format(_selectedDate);
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final monthly = _monthlyCache[monthKey];
      // 세은님 작업 디버깅 프린트문
      debugPrint('[HOME] monthKey=$monthKey hasDays=${monthly?.days.length}');
      debugPrint(
        '[HOME] dateKey=$dateKey hasDay=${monthly?.days.containsKey(dateKey)}',
      );

      final day = monthly?.days[dateKey];

      _todaySpending = day?.totalSpendingAmount ?? 0;
      _todayIncome = day?.totalIncomeAmount ?? 0; // 하경 추가 부분
    } catch (_) {
      _todaySpending = 0;
      _todayIncome = 0; // 하경 추가 부분
    }
    notifyListeners();
  }

  /// 세은 삭제 부분
  // Future<void> loadDailySpending(
  //     DateTime date, {
  //       bool ensureMonthlyLoaded = true,
  //     }) async {
  //   await loadDailySummary(date, ensureMonthlyLoaded: ensureMonthlyLoaded);
  // }

  // ---------- 저장 후 캐시 즉시 반영 + Repo 저장 ----------
  Future<void> updateLocalDaySpending({
    required DateTime date,
    required int totalAmount,
    required String emotion,
    required String comment,
    required List<RecordEntry> entries,
  }) async {
    final monthKey = DateFormat('yyyy-MM').format(date);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // 1) 월 데이터 확보
    final existingMonthly =
        _monthlyCache[monthKey] ??
            await _recordRepo.loadMonthlyRecord(monthKey);
    // 2) 기존 day가 있으면 income 유지
    final existingDay = existingMonthly.days[dateKey];

    final newDay = DayRecord(
      date: date,
      totalSpendingAmount: totalAmount,
      totalIncomeAmount: existingDay?.totalIncomeAmount ?? 0,
      emotion: emotion,
      comment: comment,
      spendingEntries: entries,
      incomeEntries: existingDay?.incomeEntries ?? const [],
      isAutoGenerated: false, // 세은 추가 부분
    );

    // 3) 메모리 캐시 업데이트
    final newDays = Map<String, DayRecord>.from(existingMonthly.days);
    newDays[dateKey] = newDay;

    final updatedMonthly = existingMonthly.copyWith(days: newDays);
    _monthlyCache[monthKey] = updatedMonthly;

    // 4) repo 저장
    await _recordRepo.saveMonthlyRecord(updatedMonthly);

    // 5) 선택 날짜면 todaySpending 갱신
    if (DateFormat('yyyy-MM-dd').format(_selectedDate) == dateKey) {
      _todaySpending = totalAmount;
      _todayIncome = existingDay?.totalIncomeAmount ?? 0; // 하경 추가 부분
    }

    await _rebuildDailyNetThroughToday();

    notifyListeners();
  }

  // ---------- 실시간 Getter ----------
  Duration? get liveRemaining {
    final target = effectiveTargetAmount;
    if (target <= 0) return Duration.zero;

    if (actualSavedNow >= target) return Duration.zero;

    final goalDate =
        _calc?.goalDateTime ?? _latestPlan?.modEndDate ?? _latestPlan?.endDate;
    if (goalDate == null) return null;

    return goalDate.difference(DateTime.now());
  }

  // 세은님 수정 내용
  double get liveSavedAmount => actualSavedNow;

  String get liveSavedAmountText {
    return '${SavingPlanCalculator.formatAmount(liveSavedAmount)}원';
  }

  String get planTitle => _latestPlan?.planName ?? '플랜 없음';

  String get planDailyNetIncomeText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    final daysInMonth =
        DateTime(metrics.startDate.year, metrics.startDate.month + 1, 0).day;
    if (daysInMonth <= 0) return '—';
    final dailyIncome = metrics.monthlyIncomeAmount / daysInMonth;
    return '${SavingPlanCalculator.formatAmount(dailyIncome)}원';
  }

  String get planDailyNetConsumeText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return '${SavingPlanCalculator.formatAmount(metrics.dailyConsumeAmount.toDouble())}원';
  }

  String get planDailyNetSavingText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return '${SavingPlanCalculator.formatAmount(metrics.dailyNetSaving.toDouble())}원';
  }

  String get planMonthlyIncomeText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return '${SavingPlanCalculator.formatAmount(metrics.monthlyIncomeAmount.toDouble())}원';
  }

  String get planMonthlyFixedConsumeText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return '${SavingPlanCalculator.formatAmount(metrics.monthlyConsumeAmount.toDouble())}원';
  }

  String get planDailyVariableConsumeText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return '${SavingPlanCalculator.formatAmount(metrics.dailyConsumeAmount.toDouble())}원';
  }

  String get planGoalPeriodText {
    final goalDate =
        _calc?.goalDateTime ?? _latestPlan?.modEndDate ?? _latestPlan?.endDate;
    if (goalDate == null) return '목표기간';
    return '${DateFormat('yyyy년 M월 d일').format(goalDate)}까지';
  }

  /// 플랜 생성 시 입력한 일 소비(변동소비) 카테고리·금액 목록.
  List<Entry> get planDailyConsumeEntries {
    final refData = _refData;
    if (refData != null) {
      final primaryEntries = List<Entry>.from(refData.primaryDailyConsumeEntries);
      if (primaryEntries.isNotEmpty) {
        primaryEntries.sort((a, b) => a.order.compareTo(b.order));
        return primaryEntries;
      }
    }

    final plan = _latestPlan;
    if (plan == null || refData == null) return const [];

    final today = _normalizeDay(DateTime.now());
    final key = DateFormat('yyyyMM').format(today);
    final subPlan = plan.subPlans[key];
    if (subPlan == null) return const [];

    final mini = _miniForDate(subPlan, today);
    if (mini == null) return const [];

    final refEntries = mini.dailyConsumeRef?.entries;
    if (refEntries != null && refEntries.isNotEmpty) {
      final entries = List<Entry>.from(refEntries);
      entries.sort((a, b) => a.order.compareTo(b.order));
      return entries;
    }

    final daily = refData.dailyConsumeById(mini.dailyConsumeId);
    if (daily == null || daily.entries.isEmpty) return const [];

    final entries = List<Entry>.from(daily.entries);
    entries.sort((a, b) => a.order.compareTo(b.order));
    return entries;
  }

  String get planTargetAmountText {
    final plan = _latestPlan;
    if (plan == null) return '—';
    return '${SavingPlanCalculator.formatAmount((plan.targetAmount ?? 0).toDouble())}원';
  }

  String get planCurrentAssetText {
    final plan = _latestPlan;
    if (plan == null) return '—';
    return '${SavingPlanCalculator.formatAmount(plan.currentAsset.toDouble())}원';
  }

  String get planRemainingTargetText {
    return '${SavingPlanCalculator.formatAmount(effectiveTargetAmount)}원';
  }

  String get dailyLimitText {
    final metrics = _latestPlan?.result.totalMetrics;
    if (metrics == null) return '—';
    return '${SavingPlanCalculator.formatAmount(metrics.dailyConsumeAmount.toDouble())}원';
  }

  int get selectedDateDailyLimit => _dailyBudgetForDate(_selectedDate) ?? 0;

  String get selectedDateDailyLimitText {
    final limit = _dailyBudgetForDate(_selectedDate);
    if (limit == null) return '—';
    return '${SavingPlanCalculator.formatAmount(limit.toDouble())}원';
  }

  // 하경 추가 내용
  String get todayIncomeText {
    return '${SavingPlanCalculator.formatAmount(_todayIncome.toDouble())}원';
  }

  int get selectedDateIncome => _todayIncome;

  String get selectedDateIncomeText => todayIncomeText;

  // 하경 추가 내용
  String get todaySpendingText {
    return '${SavingPlanCalculator.formatAmount(_todaySpending.toDouble())}원';
  }

  int get selectedDateSpending => _todaySpending;

  String get selectedDateSpendingText => todaySpendingText;

  // 하경 추가 내용
  bool get isTodayRecorded => _isManuallyRecordedDay(selectedDayRecord);

  bool get isSelectedDateRecorded => isTodayRecorded;

  /// 선택 날짜가 사용자 직접 기록이 아닌 경우 (미기록·자동입력·빈 날)
  bool get isSelectedDateUnrecorded => !isSelectedDateRecorded;

  /// 플랜 시작~오늘 중 미기록 날이 하나라도 있으면 true
  bool get hasUnrecordedSpendingDays {
    final plan = _latestPlan;
    if (plan == null) return false;

    final rawStart = plan.startDate ?? plan.creationDate;
    if (rawStart == null) return false;

    final start = _normalizeDay(rawStart);
    final today = _normalizeDay(DateTime.now());
    if (start.isAfter(today)) return false;

    var cursor = start;
    while (!cursor.isAfter(today)) {
      if (!_isManuallyRecordedDay(_recordForDate(cursor))) {
        return true;
      }
      cursor = _nextDay(cursor);
    }
    return false;
  }

  DayRecord? get selectedDayRecord {
    //선택된 날짜의 DayRecord
    final monthKey = DateFormat('yyyy-MM').format(_selectedDate);
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _monthlyCache[monthKey]?.days[dateKey];
  }

  DayRecord? get selectedDateRecord => selectedDayRecord;

  String get perSecondSaving => activeMiniPerSecondSaving.toStringAsFixed(2);
  double get progressRatio => _calc?.savingRatio ?? 0.0;

  double get effectiveTargetAmount {
    final plan = _latestPlan;
    if (plan == null) return 0;
    final target = (plan.targetAmount ?? 0).toDouble();
    return max(0, target - plan.currentAsset.toDouble());
  }

  double get confirmedSaved => _actualSavedThroughConfirmedDays;

  double get actualSavedNow => confirmedSaved + guideSum;

  double get graphTargetAmount {
    final plan = _latestPlan;
    if (plan == null) return 0;
    return max(0, (plan.targetAmount ?? 0).toDouble());
  }

  double get graphUserAmount {
    final plan = _latestPlan;
    if (plan == null) return 0;
    return actualSavedNow + plan.currentAsset.toDouble();
  }

  double get graphPlanAmount {
    final plan = _latestPlan;
    if (plan == null) return 0;
    return plannedSavedNow + plan.currentAsset.toDouble();
  }

  bool get hasReachedSavingTarget {
    final target = effectiveTargetAmount;
    return target > 0 && actualSavedNow >= target;
  }

  double get paceAmountDiff => actualSavedNow - plannedSavedNow;

  int get totalPlanDays {
    final plan = _latestPlan;
    if (plan == null) return 0;
    final rawStart = plan.startDate ?? plan.creationDate;
    final rawEnd = _calc?.goalDateTime ?? plan.modEndDate ?? plan.endDate;
    if (rawStart == null || rawEnd == null) return 0;

    final start = _normalizeDay(rawStart);
    final end = _normalizeDay(rawEnd);
    if (end.isBefore(start)) return 0;
    return end.difference(start).inDays + 1;
  }

  double get averageDailySaving {
    final days = totalPlanDays;
    if (days <= 0) return 0;
    return effectiveTargetAmount / days;
  }

  double get averagePaceDayDiff {
    final average = averageDailySaving;
    if (average <= 0) return 0;
    return paceAmountDiff / average;
  }

  double get plannedSavedNow {
    final today = _normalizeDay(DateTime.now());
    if (_isSavingConfirmedForDate(today)) {
      return _plannedSavedThrough(today);
    }

    final yesterday = today.subtract(const Duration(days: 1));
    final throughYesterday = _plannedSavedThrough(yesterday);
    final elapsedSeconds = _secondsElapsedToday();
    return throughYesterday + elapsedSeconds * activeMiniPerSecondSaving;
  }

  double get guideSum {
    _refreshGuideAnchors();
    if (_isSavingConfirmedForDate(DateTime.now())) {
      return 0;
    }
    final perSecond = activeMiniPerSecondSaving;
    if (perSecond == 0) return 0;
    if (_guideLockUntil != null && DateTime.now().isBefore(_guideLockUntil!)) {
      return 0;
    }
    return _secondsElapsedToday() * perSecond;
  }

  // 세은 추가 내용
  double get userPercent {
    final target = effectiveTargetAmount;
    if (target <= 0) return 0;
    final value = actualSavedNow / target;
    return value.clamp(0.0, 1.0);
  }

  // 세은 추가 내용
  double get planPercent {
    final target = effectiveTargetAmount;
    if (target <= 0) return 0;
    final value = plannedSavedNow / target;
    return value.clamp(0.0, 1.0);
  }

  double get graphUserPercent {
    final target = graphTargetAmount;
    if (target <= 0) return 0;
    final value = graphUserAmount / target;
    return value.clamp(0.0, 1.0);
  }

  double get graphPlanPercent {
    final target = graphTargetAmount;
    if (target <= 0) return 0;
    final value = graphPlanAmount / target;
    return value.clamp(0.0, 1.0);
  }

  double get currentMiniDailyNetSaving {
    return _plannedDailyNetForDate(DateTime.now());
  }

  double get activeMiniPerSecondSaving => currentMiniDailyNetSaving / 86400.0;

  double get planProgressPercentValue => (planPercent * 100).clamp(0.0, 100.0);

  bool _hasMetrics(TotalPlan plan) {
    final metrics = plan.result.totalMetrics;
    final hasIncome = metrics.monthlyIncomeAmount > 0;
    final hasTarget = (plan.targetAmount ?? 0) > 0;
    final hasDaily = metrics.dailyConsumeAmount >= 0;
    return hasIncome && hasTarget && hasDaily;
  }

  void addLocalIncome(double amount) {
    // TODO: implement extra income handling via TotalPlan
    notifyListeners();
  }

  // 기존 flushAutoSavingToSnapshot() 삭제 후  세은님이 추가하신 함수
  void registerExtraIncome(DateTime date, int amount) {
    if (amount <= 0) return;
    final plan = _latestPlan;
    if (plan == null) return;
    final normalized = _normalizeDay(date);
    final updatedRecords = List<ExtraIncomeRecord>.from(plan.extraIncomeRecords)
      ..add(ExtraIncomeRecord(date: normalized, amount: amount));
    _latestPlan = plan.copyWith(
      extraIncomeTotal: plan.extraIncomeTotal + amount,
      extraIncomeRecords: updatedRecords,
    );
    notifyListeners();
  }

  void flushAutoSavingToSnapshot() {}

  Future<void> refresh() => load(forceRefresh: true);

  void clearMemoryMonthlyCache() {
    _monthlyCache.clear();
  }

  // 세은님 추가 내용
  Future<void> _autoFillMissingDays() async {
    if (_autoFillRunning) return;
    final plan = _latestPlan;
    if (plan == null) return;
    final today = _normalizeDay(DateTime.now());
    final lastAuto = _recordRepo.getLastAutoFillDate();
    final planStart = plan.startDate ?? plan.creationDate ?? today;
    var cursor = lastAuto != null
        ? _nextDay(_normalizeDay(lastAuto))
        : _normalizeDay(planStart);
    if (!cursor.isBefore(today)) return;
    _autoFillRunning = true;
    DateTime? lastProcessed;
    final monthNeedsReload = <String>{};
    try {
      while (cursor.isBefore(today)) {
        var entries = _buildAutoSpendingEntries(cursor);
        if (entries == null || entries.isEmpty) {
          final fallbackAmount = _dailyBudgetForDate(cursor);
          if (fallbackAmount != null && fallbackAmount > 0) {
            entries = _buildFallbackEntries(cursor, fallbackAmount);
          }
        }
        if (entries != null && entries.isNotEmpty) {
          final inserted = await _recordRepo.ensureAutoSpendingDay(
            date: cursor,
            spendingEntries: entries,
          );
          if (inserted) {
            monthNeedsReload.add(_toMonthKey(cursor));
          }
        }
        lastProcessed = cursor;
        cursor = cursor.add(const Duration(days: 1));
      }
      if (lastProcessed != null) {
        await _recordRepo.setLastAutoFillDate(lastProcessed);
      }
      for (final key in monthNeedsReload) {
        final monthly = await _recordRepo.loadMonthlyRecord(key);
        _monthlyCache[key] = monthly;
      }
      await _rebuildDailyNetThroughToday();
    } finally {
      _autoFillRunning = false;
    }
  }

  // 세은님 추가 내용
  int? _dailyBudgetForDate(DateTime date) {
    final plan = _latestPlan;
    if (plan == null) return null;
    final normalized = _normalizeDay(date);
    final key = DateFormat('yyyyMM').format(normalized);
    final subPlan = plan.subPlans[key];
    if (subPlan == null) return null;
    final mini = _miniForDate(subPlan, normalized);
    if (mini != null) return mini.dailyConsumeAmount;
    return subPlan.monthlySummary().dailyConsumeAmount;
  }

  // 세은님 추가 내용
  List<RecordEntry>? _buildAutoSpendingEntries(DateTime date) {
    final plan = _latestPlan;
    final refData = _refData;
    if (plan == null || refData == null) return null;
    final normalized = _normalizeDay(date);
    final key = DateFormat('yyyyMM').format(normalized);
    final subPlan = plan.subPlans[key];
    if (subPlan == null) return null;
    final mini = _miniForDate(subPlan, normalized);
    if (mini == null) return null;
    final daily = refData.dailyConsumeById(mini.dailyConsumeId);
    if (daily == null || daily.entries.isEmpty) return null;
    final dateKey = DateFormat('yyyyMMdd').format(normalized);
    return List<RecordEntry>.generate(daily.entries.length, (index) {
      final entry = daily.entries[index];
      final id = 'auto_${dateKey}_${entry.categoryKey}_$index';
      return RecordEntry(
        id: id,
        categoryKey: entry.categoryKey,
        category: entry.category,
        amount: entry.amount,
        note: entry.note,
      );
    });
  }

  // 세은님 추가 내용
  List<RecordEntry> _buildFallbackEntries(DateTime date, int amount) {
    final normalized = _normalizeDay(date);
    final dateKey = DateFormat('yyyyMMdd').format(normalized);
    return [
      RecordEntry(
        id: 'auto_${dateKey}_default',
        categoryKey: 'auto_default',
        category: '자동 소비',
        amount: amount.toDouble(),
        note: '자동 소비 등록',
      ),
    ];
  }

  // 세은님 추가 내용
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

  // 세은님 추가 내용
  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  // 세은님 추가 내용
  DateTime _nextDay(DateTime value) =>
      DateTime(value.year, value.month, value.day).add(const Duration(days: 1));

  // 세은님 추가 내용
  String _toMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

  DayRecord? _recordForDate(DateTime date) {
    final normalized = _normalizeDay(date);
    final monthKey = DateFormat('yyyy-MM').format(normalized);
    final dateKey = DateFormat('yyyy-MM-dd').format(normalized);
    return _monthlyCache[monthKey]?.days[dateKey];
  }

  bool _isManuallyRecordedDay(DayRecord? day) {
    if (day == null) return false;
    if (day.isAutoGenerated) return false;

    return day.totalSpendingAmount > 0 || day.spendingEntries.isNotEmpty;
  }

  bool _isSavingConfirmedForDate(DateTime date) {
    final record = _recordForDate(date);
    return record != null && record.spendingEntries.isNotEmpty;
  }

  double _plannedDailyNetForDate(DateTime date) {
    final plan = _latestPlan;
    if (plan == null) return 0;
    final normalized = _normalizeDay(date);
    final key = DateFormat('yyyyMM').format(normalized);
    final subPlan = plan.subPlans[key];
    if (subPlan == null) return 0;
    final mini = _miniForDate(subPlan, normalized);
    if (mini == null) return 0;
    final daysInMonth = DateTime(normalized.year, normalized.month + 1, 0).day;
    final monthlyNet =
        mini.monthlyIncomeAmount -
            mini.monthlyConsumeAmount -
            (mini.dailyConsumeAmount * daysInMonth);
    return monthlyNet / daysInMonth;
  }

  double _plannedSavedThrough(DateTime endDate) {
    final plan = _latestPlan;
    if (plan == null) return 0;
    final rawStart = plan.startDate ?? plan.creationDate;
    if (rawStart == null) return 0;
    final start = _normalizeDay(rawStart);
    final end = _normalizeDay(endDate);
    if (end.isBefore(start)) return 0;

    var sum = 0.0;
    var cursor = start;
    while (!cursor.isAfter(end)) {
      sum += _plannedDailyNetForDate(cursor);
      cursor = _nextDay(cursor);
    }
    return sum;
  }

  int _secondsElapsedToday() {
    final now = DateTime.now();
    final todayStart = _normalizeDay(now);
    return max(0, now.difference(todayStart).inSeconds);
  }

  // 세은님 추가 내용
  void _updateDailyNetForDate(DateTime date, DayRecord? record) {
    final normalized = _normalizeDay(date);
    final key = DateFormat('yyyy-MM-dd').format(normalized);
    final plannedBudget = _dailyBudgetForDate(normalized) ?? 0;
    final plannedDailySaving = _plannedDailyNetForDate(normalized);
    if (record == null && plannedBudget == 0 && plannedDailySaving == 0) {
      _dailyNet.remove(key);
      return;
    }
    final actual = record?.totalSpendingAmount ?? 0;
    final income = record?.totalIncomeAmount ?? 0;
    if (plannedBudget == 0 &&
        plannedDailySaving == 0 &&
        actual == 0 &&
        income == 0) {
      _dailyNet.remove(key);
      return;
    }
    final hasSpendingEntries = record?.spendingEntries.isNotEmpty ?? false;
    _dailyNet[key] = _DailyNet(
      date: normalized,
      plannedBudget: plannedBudget,
      plannedDailySaving: plannedDailySaving,
      actualSpending: actual,
      extraIncome: income,
      hasSpendingEntries: hasSpendingEntries,
    );
  }

  // 세은님 추가 내용
  void _recomputeDailyNetSummary() {
    double sum = 0;
    final today = _normalizeDay(DateTime.now());
    var todayConfirmed = false;
    _dailyNet.forEach((_, net) {
      if (net.date.isAfter(today)) return;
      if (net.date.isBefore(today) || net.hasSpendingEntries) {
        sum += net.actualSaved;
      }
      if (net.hasSpendingEntries) {
        if (net.date.isAtSameMomentAs(today)) {
          todayConfirmed = true;
        }
      }
    });
    _actualSavedThroughConfirmedDays = sum;
    _guideStart = _normalizeDay(DateTime.now());
    if (todayConfirmed) {
      _guideLockUntil = _nextDay(_guideStart);
    } else {
      _guideLockUntil = null;
      _refreshGuideAnchors();
    }
    _checkPlanCelebration();
  }

  Future<void> _rebuildDailyNetThroughToday() async {
    final plan = _latestPlan;
    if (plan == null) {
      _dailyNet.clear();
      _actualSavedThroughConfirmedDays = 0;
      _guideStart = _normalizeDay(DateTime.now());
      _guideLockUntil = null;
      return;
    }

    final start = _normalizeDay(
      plan.startDate ?? plan.creationDate ?? DateTime.now(),
    );
    final today = _normalizeDay(DateTime.now());

    _dailyNet.clear();

    var cursor = start;
    while (!cursor.isAfter(today)) {
      await _ensureMonthlyLoaded(cursor);
      final monthKey = DateFormat('yyyy-MM').format(cursor);
      final dateKey = DateFormat('yyyy-MM-dd').format(cursor);
      final day = _monthlyCache[monthKey]?.days[dateKey];
      _updateDailyNetForDate(cursor, day);
      cursor = _nextDay(cursor);
    }

    _recomputeDailyNetSummary();
  }

  void _refreshPlanForToday() {
    final plan = _latestPlan;
    if (plan == null) {
      _calc = null;
      return;
    }

    final normalizedPlan = plan.recalculateTotals();
    _latestPlan = normalizedPlan;

    if (_hasMetrics(normalizedPlan)) {
      _calc = SavingPlanCalculator(plan: normalizedPlan).calculate();
    } else {
      _calc = null;
    }
  }

  void _scheduleDayBoundaryRefreshIfNeeded() {
    final today = _normalizeDay(DateTime.now());
    if (_todayAnchor.isAtSameMomentAs(today) || _dayBoundaryRefreshRunning) {
      return;
    }

    _todayAnchor = today;
    _dayBoundaryRefreshRunning = true;
    Future<void>(() async {
      try {
        _refreshPlanForToday();
        await _autoFillMissingDays();
        await _rebuildDailyNetThroughToday();
        await loadDailySummary(_selectedDate);
      } finally {
        _dayBoundaryRefreshRunning = false;
      }
    });
  }

  // 세은님 추가 내용
  void _refreshGuideAnchors() {
    final todayStart = _normalizeDay(DateTime.now());
    if (!_guideStart.isAtSameMomentAs(todayStart)) {
      _guideStart = todayStart;
    }
    if (_guideLockUntil != null && !DateTime.now().isBefore(_guideLockUntil!)) {
      _guideLockUntil = null;
    }
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

// 세은님 추가 내용
class _DailyNet {
  _DailyNet({
    required this.date,
    required this.plannedBudget,
    required this.plannedDailySaving,
    required this.actualSpending,
    required this.extraIncome,
    required this.hasSpendingEntries,
  });

  final DateTime date;
  final int plannedBudget;
  final double plannedDailySaving;
  final int actualSpending;
  final int extraIncome;
  final bool hasSpendingEntries;

  double get actualSaved =>
      plannedDailySaving + plannedBudget - actualSpending + extraIncome;
}

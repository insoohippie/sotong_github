import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../model/category/plan_category_item.dart';
import '../../model/plan/chat_message.dart';
import '../../model/refData/daily_consume.dart';
import '../../model/refData/entry.dart';
import '../../model/commands/update_daily_command.dart';
import '../../model/commands/update_monthly_command.dart';
import '../../model/plan/plan_edit_result.dart';
import '../../model/plan/total_plan.dart';
import '../../model/plan/mini_plan.dart';
import '../../model/refData/monthly_consume.dart';
import '../../model/refData/monthly_income.dart';
import '../../model/refData/ref_data.dart';
import '../../model/plan/sub_plan.dart';
import '../../model/saving_calculation_result.dart';
import '../../repository/auth_repository.dart';
import '../../repository/plan_category_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/ref_data_repository.dart';
import '../../repository/plan_cache_repository.dart';
import '../../services/app_session_reset_service.dart';
import '../../services/category_key.dart';
import '../../services/plan_debug_printer.dart';
import '../../services/plan_saved_event_bus.dart';
import '../services/ref_data_viewmodel.dart';
import '../services/plan_preview_service.dart';
import '../services/saving_calculator.dart';
import '../services/total_plan_viewmodel.dart';
import '../../services/plan_mutation_service.dart';
import '../../repository/plan_mutation_repository.dart';
import '../../model/plan/plan_snapshot.dart';
import 'enums/chat_step.dart';

/// 섹터 기반 메시지 관리 클래스
/// 모달(버튼)이 나타나는 시점을 기준으로 섹터를 구분
class ChatSection {
  final ChatStep step;
  final List<String> messages;
  final int delayBetweenMessages;

  ChatSection({
    required this.step,
    required this.messages,
    this.delayBetweenMessages = 1000,
  });
}

// 기본 회원가입 창의 viewmodel
class ChatPlanViewModel extends ChangeNotifier implements SessionResettable {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;
  final RefDataRepository _refDataRepo;
  final PlanCacheRepository _planCacheRepo;
  final PlanCategoryRepository _planCategoryRepo;
  final PlanSavedEventBus? _planSavedBus;

  ChatPlanViewModel(
      this._authRepo,
      this._planRepo,
      this._refDataRepo,
      this._planCacheRepo,
      this._planCategoryRepo, {
        PlanSavedEventBus? planSavedBus,
      })  : _planSavedBus = planSavedBus,
        _mutationRepository = PlanMutationRepository() {
    _mutationService = PlanMutationService(_mutationRepository);
    _refDataVM = RefDataViewModel(_refData);
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _calculationVM = SavingPlanCalculator(plan: _totalPlan);

    debugPrint(
      '[ChatPlanViewModel] ctor: cachedHasPlan=${_authRepo.cachedHasPlan}',
    );

    unawaited(_initializePlanState());
  }

  String _userName = '회원';
  String get userName => _userName;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // 플랜 정보
  TotalPlan _totalPlan = TotalPlan.empty();
  TotalPlan get totalPlan => _totalPlan;

  // 참조 데이터 (월 수입, 고정 소비, 하루 소비 한도)
  RefData _refData = RefData(planId: '');
  RefData get refData => _refData;

  // --------------------------------------
  // RefData 기반 실시간 합계 / 한도 / 예상 소요 기간 계산
  // --------------------------------------
  double get liveMonthlyIncomeFromRef => _refData.primaryMonthlyIncomeSum;

  double get liveMonthlyFixedConsumeFromRef =>
      _refData.primaryMonthlyConsumeSum;

  double get liveDailyConsumeFromRef => _refData.primaryDailyConsumeSum;

  /// 월 잔여 예산 = 월 수입 - 월 고정소비
  double get liveDailyBudgetLimitFromRef {
    final leftover =
        _refData.primaryMonthlyIncomeSum - _refData.primaryMonthlyConsumeSum;
    return leftover > 0 ? leftover : 0.0;
  }

  List<UpdateMonthlyCommand> _pendingMonthlyCommands = [];
  List<UpdateDailyCommand> _pendingDailyCommands = [];
  List<UpdateMonthlyCommand> get pendingMonthlyCommands =>
      _pendingMonthlyCommands;
  List<UpdateDailyCommand> get pendingDailyCommands => _pendingDailyCommands;
  final List<_PendingMonthlyInput> _pendingAutoMonthlyInputs = [];
  final List<_PendingDailyInput> _pendingAutoDailyInputs = [];
  final List<Future<void>> _pendingRefDataWrites = [];
  DateTime? _pendingPlanEditGoalDate;
  DateTime? _pendingPlanEditApplyDate;
  bool _pendingPlanTreeMaterialized = false;

  // 계산 결과
  SavingCalculationResult? _calculationResult;
  SavingCalculationResult? get calculationResult => _calculationResult;

  // 요약 추천 멘트 (요약 카드 내부에서 표시)
  String? _summaryRecommendation;
  String? get summaryRecommendation => _summaryRecommendation;
  int _summaryRenderVersion = 0;
  int get summaryRenderVersion => _summaryRenderVersion;

  // 현재 단계
  ChatStep _currentStep = ChatStep.onboarding1;
  ChatStep get currentStep => _currentStep;

  // 각 섹터의 메시지 개수 추적
  final Map<ChatStep, int> _sectionMessageCounts = {};

  // 각 섹터의 시작 인덱스 추적 (섹터별 메시지 구분용)
  final Map<ChatStep, int> _sectionStartIndices = {};

  /// 현재 섹터의 메시지 개수를 반환
  int? getSectionMessageCount(ChatStep step) {
    return _sectionMessageCounts[step];
  }

  /// 현재 섹터의 시작 인덱스를 반환
  int? getSectionStartIndex(ChatStep step) {
    return _sectionStartIndices[step];
  }

  // 메시지 목록
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _initialPlanResolved = false;
  bool _needsInitialUpload = true;

  String? _loadedUid;

  Future<void> _initializePlanState() async {
    if (_initialPlanResolved) return;
    _initialPlanResolved = true;
    debugPrint('[ChatPlanViewModel] initializing plan state');
    var loaded = false;
    if (_authRepo.cachedHasPlan) {
      debugPrint('[ChatPlanViewModel] cachedHasPlan=true -> try cache');
      loaded = await _restorePlanFromCache();
      if (!loaded) {
        debugPrint('[ChatPlanViewModel] cache miss -> fallback server load');
        loaded = await _tryLoadPlanFromServer();
      }
    } else {
      debugPrint('[ChatPlanViewModel] cachedHasPlan=false -> try server load');
      loaded = await _tryLoadPlanFromServer();
    }
    if (!loaded) return;
    _calculationVM.updatePlan(_totalPlan);
    calculate();
    notifyListeners();
  }

  Future<bool> _restorePlanFromCache() async {
    final result = await initializeFromCacheIfAvailable();
    debugPrint('[ChatPlanViewModel] restorePlanFromCache result=$result');
    return result;
  }

  Future<bool> initializeFromCacheIfAvailable() async {
    final uid = _authRepo.cachedUid ?? _authRepo.currentUserId;
    if (uid == null) return false;
    final snapshot = _planCacheRepo.loadSnapshot(uid);
    if (snapshot == null) {
      debugPrint('[ChatPlanViewModel] cache snapshot missing for uid=$uid');
      return false;
    }
    debugPrint(
      '[ChatPlanViewModel] cache snapshot found for uid=$uid, planId=${snapshot.plan.planId}',
    );
    _hydrateFromSnapshot(snapshot);
    _setHasSavedPlan(true, syncCache: false);
    return true;
  }

  void _hydrateFromSnapshot(PlanCacheSnapshot snapshot) {
    _totalPlan = snapshot.plan.recalculateTotals();
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _refData = snapshot.refData;
    _refDataVM = RefDataViewModel(_refData);
    _needsInitialUpload = snapshot.needsInitialUpload;
    _logPlanTree('Loaded From Cache');
  }

  Future<bool> _tryLoadPlanFromServer() async {
    try {
      final plan = await _planRepo.getLatestPlanForCurrentUser();
      if (plan == null) {
        debugPrint('[ChatPlanViewModel] server plan not found');
        return false;
      }
      debugPrint(
        '[ChatPlanViewModel] server plan loaded planId=${plan.planId}',
      );
      final refData = await _refDataRepo.loadAll();
      refData.planId = plan.planId;
      _totalPlan = plan.recalculateTotals();
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _refData = refData;
      _refDataVM = RefDataViewModel(_refData);
      _needsInitialUpload = false;
      _setHasSavedPlan(true);
      _logPlanTree('Loaded From Server');
      return true;
    } catch (e) {
      debugPrint('[ChatPlanViewModel] failed to load plan from server: $e');
      return false;
    }
  }

  // 타이핑 상태
  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // 버튼 클릭 상태 (onboarding 단계에서만 사용)
  bool _buttonClicked = false;
  bool get buttonClicked => _buttonClicked;

  late RefDataViewModel _refDataVM;
  bool _refDataLoaded = false;
  late TotalPlanViewModel _totalPlanVM;
  late SavingPlanCalculator _calculationVM;
  final PlanPreviewService _previewService = const PlanPreviewService();
  final PlanMutationRepository _mutationRepository;
  late final PlanMutationService _mutationService;

  bool _hasIncomeInput = false;
  bool _hasFixedConsumeInput = false;
  bool _hasDailyInput = false;
  bool _hasSavedPlan = false;
  DateTime? _lastPersistedGoal;
  bool _printedInitialPlanTree = false;

  double _previewDailyTotal = 0;
  double get previewDailyTotal => _previewDailyTotal;

  // --------------------------------------
  // 메시지
  // --------------------------------------
  void addMessage(String content, MessageType type, {bool isTyping = false}) {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      content: content,
      timestamp: DateTime.now(),
      isTyping: isTyping,
    );
    _messages.add(newMessage);
    notifyListeners();
  }

  void updateDailyPreview(double total) {
    _previewDailyTotal = total;
    notifyListeners();
  }

  double computeEffectiveDailyTotal(double fallback) {
    if (_previewDailyTotal > 0) {
      return _previewDailyTotal;
    }
    final dailyId = _refData.primaryDailyConsumeId;
    if (dailyId == null) return fallback;
    final daily = _refData.dailyConsumeMap[dailyId];
    if (daily == null) return fallback;
    final refTotal = daily.entries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    return refTotal > 0 ? refTotal : fallback;
  }

  SavingCalculationResult? previewDailyEntries(
    List<Entry> entries, {
    DateTime? applyDate,
  }) {
    final targetAmount = (_totalPlan.targetAmount ?? 0).toDouble();
    if (targetAmount <= 0) {
      return null;
    }

    final basePlan = _buildPreviewPlan();
    final normalizedApply = _clampPreviewDate(
      applyDate ?? DateTime.now(),
      basePlan,
    );
    final dailyTotal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    return _previewService.calculatePreview(
      PlanPreviewInput(
        plan: basePlan,
        refData: _refData,
        applyDate: normalizedApply,
        targetAmount: targetAmount,
        currentAsset: _totalPlan.currentAsset.toDouble(),
        monthlyIncome: _refData.primaryMonthlyIncomeSum,
        monthlyFixedCost: _refData.primaryMonthlyConsumeSum,
        dailySpendingLimit: dailyTotal,
        dailySpendingApplyDate: normalizedApply,
      ),
    );
  }

  /// 섹터 내 메시지들을 순차적으로 타이핑
  /// - 마지막 메시지가 아닌 메시지들에만 타이핑 인디케이터 표시
  /// - 마지막 메시지 완료 후에만 모달(버튼) 표시
  Future<void> addSectionMessages(ChatSection section) async {
    if (section.messages.isEmpty) return;

    // 섹터 시작 전에 currentStep을 먼저 업데이트 (버튼이 올바른 단계에서 나타나도록)
    _currentStep = section.step;
    notifyListeners();

    // 섹터의 메시지 개수 저장
    _sectionMessageCounts[section.step] = section.messages.length;

    // 섹터 시작 시점의 봇 메시지 개수 저장 (현재 섹터의 메시지만 확인하기 위함)
    // 예: onboarding1 섹터 시작 시점 = 0, onboarding2 섹터 시작 시점 = 3 (onboarding1의 3개 메시지 이후)
    final currentBotMessageCount = _messages
        .where((m) => m.type == MessageType.bot)
        .length;
    _sectionStartIndices[section.step] = currentBotMessageCount;

    debugPrint(
      '[addSectionMessages] 섹터 ${section.step} 시작 인덱스: $currentBotMessageCount, 메시지 개수: ${section.messages.length}',
    );

    for (int i = 0; i < section.messages.length; i++) {
      final isLast = i == section.messages.length - 1;
      final delay = i == 0 ? 500 : section.delayBetweenMessages;

      // 마지막 메시지 시작 전에 _isTyping을 확실히 false로 설정
      if (isLast) {
        _isTyping = false;
        notifyListeners();
        // 상태 업데이트를 위한 짧은 대기
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await addBotMessageWithTyping(
        section.messages[i],
        delay: delay,
        isLastMessage: isLast,
        showTypingIndicator: !isLast, // 마지막 메시지가 아니면 인디케이터 표시
      );
    }
  }

  Future<void> addBotMessageWithTyping(
    String content, {
    int delay = 1000,
    bool awaitTyping = false,
    bool isLastMessage = false,
    bool showTypingIndicator = true,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    // 마지막 메시지는 인디케이터 없이 처리
    // 마지막 메시지 시작 전에 _isTyping을 false로 설정
    if (isLastMessage) {
      _isTyping = false;
      notifyListeners();
    } else if (showTypingIndicator) {
      // 마지막 메시지가 아니고 showTypingIndicator가 true면 타이핑 상태 설정
      _isTyping = true;
      notifyListeners();
    }

    // 초기 delay (메시지 간 간격)
    // showTypingIndicator가 true면 이 시간 동안 타이핑 인디케이터 유지
    await Future.delayed(Duration(milliseconds: delay));

    // 메시지 추가
    addMessage(trimmed, MessageType.bot);

    // 마지막 메시지인 경우, 메시지 추가 후 즉시 _isTyping을 false로 설정
    // (타이핑 애니메이션은 인디케이터 없이 진행)
    if (isLastMessage) {
      _isTyping = false;
      notifyListeners();
    }

    // 타이핑 애니메이션 시간 계산 (30ms per char)
    final typingDuration = trimmed.runes.length * 30;

    // 타이핑 애니메이션이 완료될 때까지 대기
    await Future.delayed(Duration(milliseconds: typingDuration));

    // 마지막 메시지인 경우 처리
    if (isLastMessage) {
      // ChatMessageWidget의 completedMessageIds 업데이트를 기다림
      // 타이핑 애니메이션이 완료된 후 약간의 시간을 더 기다려서
      // completedMessageIds에 메시지가 추가되도록 함
      await Future.delayed(const Duration(milliseconds: 200));
    } else {
      // 마지막 메시지가 아니면 타이핑 상태 유지 (다음 메시지가 바로 시작되도록)
      // showTypingIndicator가 true면 계속 유지, false면 다음 메시지 시작 전에 false로 설정
      if (!showTypingIndicator) {
        _isTyping = false;
        notifyListeners();
      }
    }
  }

  // --------------------------------------
  // 요약 추천 멘트 갱신 로직
  // --------------------------------------
  String _buildSummaryRecommendationMessage({
    required double months,
    required double dailyNetSaving,
  }) {
    final curr = _totalPlan.currentAsset.toDouble();
    final amt3m = curr + dailyNetSaving * 90; // 대략 3개월
    final amt6m = curr + dailyNetSaving * 180; // 대략 6개월

    String fmt(double v) => SavingPlanCalculator.formatAmount(v);

    if (months <= 1.0) {
      return '현재 계획대로라면 목표까지 약 ${months.toStringAsFixed(1)}개월밖에 걸리지 않아요!\n'
          '너무 짧으면 약간 늘려 잡는 걸 추천드려요 😊\n\n'
          '• 3개월 목표: 약 ${fmt(amt3m)}원\n'
          '• 6개월 목표: 약 ${fmt(amt6m)}원\n'
          '참고만 해주세요!';
    }

    if (months >= 6.0) {
      return '현재 계획대로라면 목표까지 약 ${months.toStringAsFixed(1)}개월이 걸려요.\n'
          '조금 길 수 있어서 목표를 나눠보는 걸 추천드려요 😊\n\n'
          '• 3개월 목표: 약 ${fmt(amt3m)}원\n'
          '• 6개월 목표: 약 ${fmt(amt6m)}원\n'
          '참고만 해주세요!';
    }

    return '좋은 플랜이네요! 🎉\n'
        '현재 계획대로라면 목표까지 약 ${months.toStringAsFixed(1)}개월입니다.\n'
        '충분히 현실적인 계획이에요 👍';
  }

  void _overwriteSummaryRecommendationFromPlanEdit({
    required DateTime projectedGoal,
    required DateTime applyDate,
  }) {
    final c = _calculationResult;
    if (c == null || c.dailyNetSaving <= 0) return;

    final base = DateTime(applyDate.year, applyDate.month, applyDate.day);
    final diffSeconds = projectedGoal.difference(base).inSeconds.toDouble();
    final months = diffSeconds <= 0 ? 0.0 : (diffSeconds / 86400.0) / 30.0;

    _summaryRecommendation = _buildSummaryRecommendationMessage(
      months: months,
      dailyNetSaving: c.dailyNetSaving,
    );
  }

  void _updateSummaryRecommendation() {
    final c = _calculationResult;
    if (c == null || c.dailyNetSaving <= 0) {
      _summaryRecommendation = null;
      return;
    }

    final months = c.daysToGoal / 30.0;
    _summaryRecommendation = _buildSummaryRecommendationMessage(
      months: months,
      dailyNetSaving: c.dailyNetSaving,
    );
  }

  // --------------------------------------
  // Plan/RefData 업데이트
  // --------------------------------------
  bool _hasRequiredInputs() {
    final target = (_totalPlan.targetAmount ?? 0) > 0;
    return _hasIncomeInput && _hasFixedConsumeInput && _hasDailyInput && target;
  }

  void updatePlanInfo({
    String? planName,
    double? targetAmount,
    double? currentAsset,
    bool? autoService,
    double? fixedIncomeSum,
    double? fixedConsumptionSum,
    double? dailyConsumptionSum,
  }) {
    _totalPlan = _totalPlan.copyWith(
      planName: planName ?? _totalPlan.planName,
      targetAmount: targetAmount?.round() ?? _totalPlan.targetAmount,
      currentAsset: currentAsset?.round() ?? _totalPlan.currentAsset,
      autoService: autoService ?? _totalPlan.autoService,
    );

    if (fixedIncomeSum != null) {
      _hasIncomeInput = true;
      debugPrint('[updatePlanInfo] monthlyIncome input=$fixedIncomeSum');
    }
    if (fixedConsumptionSum != null) {
      _hasFixedConsumeInput = true;
      debugPrint('[updatePlanInfo] monthlyConsume input=$fixedConsumptionSum');
    }
    if (dailyConsumptionSum != null) {
      _hasDailyInput = true;
      debugPrint('[updatePlanInfo] dailyConsume input=$dailyConsumptionSum');
    }

    final hasAll = _hasRequiredInputs();
    if (!_hasSavedPlan && hasAll) {
      _rebuildSkeletonWithLatestGoal();
    } else if (_hasSavedPlan && hasAll) {
      calculate();
    }

    notifyListeners();
  }

  void updateRefData({
    List<Entry>? fixedIncomes,
    List<Entry>? fixedConsumptions,
    List<Entry>? dailyConsumptions,
    DateTime? applyDate,
    DateTime? modEndDate,
  }) {
    final now = DateTime.now();
    final apply = applyDate ?? now;
    final endDate =
        modEndDate ?? (_totalPlan.modEndDate ?? _totalPlan.endDate ?? now);
    final applyMonth = DateTime(apply.year, apply.month, 1);
    final modEndMonth = DateTime(endDate.year, endDate.month, 1);
    debugPrint(
      '[updateRefData] apply=$apply end=$endDate '
      'incomes=${fixedIncomes?.length ?? 0} '
      'consumes=${fixedConsumptions?.length ?? 0} '
      'daily=${dailyConsumptions?.length ?? 0} '
      '(_hasSavedPlan=$_hasSavedPlan)',
    );

    if (fixedIncomes != null && fixedIncomes.isNotEmpty) {
      final previousId = _refData.primaryMonthlyIncomeId;
      final newIncome = _refDataVM.appendMonthlyIncome(
        applyDate: apply,
        modEndDate: endDate,
        entries: fixedIncomes,
      );
      _trackRefDataWrite(_refDataRepo.saveMonthlyIncome(newIncome));
      if (previousId == null) {
        debugPrint('[updateRefData] monthlyIncome previousId missing');
      }
      debugPrint(
        '[updateRefData] new monthlyIncome ${newIncome.id} from $applyMonth to $modEndMonth',
      );
      if (_hasSavedPlan) {
        _pendingAutoMonthlyInputs.add(
          _PendingMonthlyInput(
            applyMonth: applyMonth,
            modEndMonth: modEndMonth,
            entries: List<Entry>.from(fixedIncomes),
            newDocumentId: newIncome.id,
            previousDocumentId: previousId,
            isIncome: true,
            allowBeforePlanStart: !_hasSavedPlan,
          ),
        );
      }
    }

    if (fixedConsumptions != null && fixedConsumptions.isNotEmpty) {
      final previousId = _refData.primaryMonthlyConsumeId;
      final newConsume = _refDataVM.appendMonthlyConsume(
        applyDate: apply,
        modEndDate: endDate,
        entries: fixedConsumptions,
      );
      _trackRefDataWrite(_refDataRepo.saveMonthlyConsume(newConsume));
      if (previousId == null) {
        debugPrint('[updateRefData] monthlyConsume previousId missing');
      }
      debugPrint(
        '[updateRefData] new monthlyConsume ${newConsume.id} from $applyMonth to $modEndMonth',
      );
      if (_hasSavedPlan) {
        _pendingAutoMonthlyInputs.add(
          _PendingMonthlyInput(
            applyMonth: applyMonth,
            modEndMonth: modEndMonth,
            entries: List<Entry>.from(fixedConsumptions),
            newDocumentId: newConsume.id,
            previousDocumentId: previousId,
            isIncome: false,
            allowBeforePlanStart: !_hasSavedPlan,
          ),
        );
      }
    }

    if (dailyConsumptions != null && dailyConsumptions.isNotEmpty) {
      final previousId = _refData.primaryDailyConsumeId;
      final newDaily = _refDataVM.appendDailyConsume(
        applyDate: apply,
        modEndDate: endDate,
        entries: dailyConsumptions,
      );
      _trackRefDataWrite(_refDataRepo.saveDailyConsume(newDaily));
      if (previousId == null) {
        debugPrint('[updateRefData] dailyConsume previousId missing');
      }
      debugPrint(
        '[updateRefData] new dailyConsume ${newDaily.id} from $apply to $endDate',
      );
      if (_hasSavedPlan) {
        _pendingAutoDailyInputs.add(
          _PendingDailyInput(
            applyDate: DateTime(apply.year, apply.month, apply.day),
            modEndDate: DateTime(endDate.year, endDate.month, endDate.day),
            entries: List<Entry>.from(dailyConsumptions),
            newDailyId: newDaily.id,
            previousDailyId: previousId,
            newMiniDocId: _nextMiniDocId(apply),
            allowBeforePlanStart: !_hasSavedPlan,
          ),
        );
      }
    }

    updatePlanInfo(
      fixedIncomeSum: fixedIncomes != null
          ? refData.primaryMonthlyIncomeSum
          : null,
      fixedConsumptionSum: fixedConsumptions != null
          ? refData.primaryMonthlyConsumeSum
          : null,
      dailyConsumptionSum: dailyConsumptions != null
          ? refData.primaryDailyConsumeSum
          : null,
    );
    debugPrint(
      '[UPDATE_REFDATA_AFTER] '
      'refIncome=${refData.primaryMonthlyIncomeSum}, '
      'refFixed=${refData.primaryMonthlyConsumeSum}, '
      'refDaily=${refData.primaryDailyConsumeSum}, '
      'metricIncome=${_totalPlan.result.totalMetrics.monthlyIncomeAmount}, '
      'metricFixed=${_totalPlan.result.totalMetrics.monthlyConsumeAmount}, '
      'metricDaily=${_totalPlan.result.totalMetrics.dailyConsumeAmount}',
    );
  }

  void _trackRefDataWrite(Future<void> write) {
    late final Future<void> tracked;
    tracked = write
        .catchError((Object e, StackTrace stack) {
          debugPrint('[RefDataWrite] failed but deferred to final save: $e');
        })
        .whenComplete(() {
          _pendingRefDataWrites.remove(tracked);
        });
    _pendingRefDataWrites.add(tracked);
  }

  Future<void> _waitForPendingRefDataWrites() async {
    while (_pendingRefDataWrites.isNotEmpty) {
      final pending = List<Future<void>>.from(_pendingRefDataWrites);
      await Future.wait(pending);
    }
  }
  String _fallbackEmojiByName(String name, {String fallback = '💰'}) {
    switch (name.trim()) {
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

  Future<void> _upsertInitialPlanCategoriesFromRefData() async {
    final dailyEntries = <Entry>[];

    for (final daily in _refData.dailyConsumeMap.values) {
      for (final entry in daily.entries) {
        if (entry.type != EntryType.daily) continue;

        final key = entry.categoryKey.trim();
        final name = entry.category.trim();

        if (!CategoryKey.isValid(key)) continue;
        if (name.isEmpty) continue;

        dailyEntries.add(entry);
      }
    }

    if (dailyEntries.isEmpty) {
      debugPrint('[PlanCategories] no daily consume entries to register');
      return;
    }

    final now = DateTime.now();

    final items = <PlanCategoryItem>[];
    final seenKeys = <String>{};

    for (final entry in dailyEntries) {
      final key = entry.categoryKey.trim();
      final name = entry.category.trim();

      if (seenKeys.contains(key)) continue;
      seenKeys.add(key);

      items.add(
        PlanCategoryItem(
          categoryKey: key,
          name: name,
          emoji: entry.emoji.trim().isNotEmpty
              ? entry.emoji.trim()
              : _fallbackEmojiByName(name),
          createdAt: now,
          updatedAt: now,
          lastUsedAt: now,
          isArchived: false,
        ),
      );
    }

    await _planCategoryRepo.upsertMany(items);

    debugPrint(
      '[PlanCategories] registered initial plan categories count=${items.length}',
    );
  }

  Future<void> loadRemoteRefData() async {
    if (_refDataLoaded) return;
    try {
      final fetched = await _refDataRepo.loadAll();
      _refData = fetched;
      _refDataVM = RefDataViewModel(_refData);
      _refDataLoaded = true;
      notifyListeners();
    } catch (_) {
      // swallow for now; caller can retry later if needed.
    }
  }

  void applyPlanEditResult(PlanEditResult result) {
    // 만든 결과를 앱의 메인 상태에 반영
    _refData = result.updatedRefData;
    _refData.planId = result.updatedPlan.planId;
    _refDataVM = RefDataViewModel(_refData);
    debugPrint(
      '[applyPlanEditResult] updated totalPlan planId=${result.updatedPlan.planId}',
    );
    if (result.updatedPlan.planId.isNotEmpty && !_hasSavedPlan) {
      debugPrint(
        '[applyPlanEditResult] detected existing plan, setting _hasSavedPlan true',
      );
      _setHasSavedPlan(true);
    }
    final isOnboardingDraftEdit =
        !_hasSavedPlan && result.updatedPlan.planId.isEmpty;
    final monthlyCommands = List<UpdateMonthlyCommand>.from(
      result.monthlyCommands.where((cmd) => cmd.entries.isNotEmpty),
    );
    final dailyCommands = List<UpdateDailyCommand>.from(
      result.dailyCommands.where((cmd) => cmd.entries.isNotEmpty),
    );
    if (isOnboardingDraftEdit) {
      _totalPlan = _materializeOnboardingPreviewPlan(
        seedPlan: result.updatedPlan,
        goalDate: result.projectedGoalDate,
      );
      _pendingMonthlyCommands.clear();
      _pendingDailyCommands.clear();
      _pendingPlanEditGoalDate = null;
      _pendingPlanEditApplyDate = null;
      _pendingPlanTreeMaterialized = false;
      debugPrint('[applyPlanEditResult] materialized onboarding preview plan');
    } else {
      _totalPlan = _hasSavedPlan
          ? _materializeEditedPlanTree(
              plan: result.updatedPlan,
              refData: _refData,
              goalDate: result.projectedGoalDate,
              monthlyCommands: monthlyCommands,
              dailyCommands: dailyCommands,
            )
          : result.updatedPlan;
      _pendingPlanTreeMaterialized = _hasSavedPlan;
    }
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    if (_hasSavedPlan) {
      _pendingMonthlyCommands = monthlyCommands;
      _pendingDailyCommands = dailyCommands;
      _pendingPlanEditGoalDate = result.projectedGoalDate;
      _pendingPlanEditApplyDate = result.applyDate;
      debugPrint('[applyPlanEditResult] commands captured (hasSavedPlan=true)');
    } else {
      debugPrint(
        '[applyPlanEditResult] skipping commands (_hasSavedPlan=false)',
      );
      _pendingMonthlyCommands.clear();
      _pendingDailyCommands.clear();
      _pendingPlanEditGoalDate = null;
      _pendingPlanEditApplyDate = null;
      _pendingPlanTreeMaterialized = false;
    }
    _calculationVM.updatePlan(_totalPlan);
    calculate();
    if (!isOnboardingDraftEdit) {
      _overwriteSummaryRecommendationFromPlanEdit(
        projectedGoal: result.projectedGoalDate,
        applyDate: result.applyDate,
      );
    }
    _summaryRenderVersion++;
    notifyListeners();
    _logPlanTree('After Edit');
  }

  /// Returns a human readable tree view of the current plan/mini/sub linkage.
  String debugPlanTree() {
    return PlanDebugPrinter.describe(plan: _totalPlan, refData: _refData);
  }

  void _logPlanTree(String label) {
    print('--- Plan Tree $label ---\n${debugPlanTree()}');
  }

  // --------------------------------------
  // 단계 이동
  // --------------------------------------
  Future<void> nextStep() async {
    final steps = ChatStep.values;
    final currentIndex = steps.indexOf(_currentStep);

    if (currentIndex < steps.length - 1) {
      _currentStep = steps[currentIndex + 1];
      notifyListeners();

      // summary 단계 진입 시 계산/추천문구는 calculate()에서 처리됨
      if (_currentStep == ChatStep.summary) {
        final calc = calculate();
        if (calc == null || calc.dailyNetSaving <= 0) {
          print('저축 불가');
        }
      }
    }
  }

  // --------------------------------------
  // 사용자 응답 처리
  // --------------------------------------
  void handleUserResponse(String response) async {
    switch (_currentStep) {
      case ChatStep.onboarding1:
        if (response == '소통에 대해 더 알아볼래요') {
          _buttonClicked = true;
          notifyListeners();
          addMessage(response, MessageType.user);
          _currentStep = ChatStep.onboarding2;
          notifyListeners();

          // onboarding2 섹터 (메시지 1개)
          final onboarding2Section = ChatSection(
            step: ChatStep.onboarding2,
            messages: [
              '소통은 $_userName님의 재정 상황을 바탕으로,\n'
                  '목표 달성까지 걸리는 시간을 계산해드려요.\n\n'
                  '계획만 세우는 게 아니라, \n'
                  '목표 달성까지 함께 가는 \n'
                  '재정 파트너예요. 💙',
            ],
          );

          await addSectionMessages(onboarding2Section);

          _buttonClicked = false;
          notifyListeners();
        }
        break;

      case ChatStep.onboarding2:
        if (response == '너무 신기해요!') {
          _buttonClicked = true;
          notifyListeners();
          addMessage(response, MessageType.user);
          _currentStep = ChatStep.onboarding3;
          notifyListeners();

          // onboarding3 섹터 (메시지 1개)
          final onboarding3Section = ChatSection(
            step: ChatStep.onboarding3,
            messages: [
              '그럼 이제 $_userName님만의 목표를 향한 플랜을\n'
                  '저와 함께 하나씩 만들어볼까요? 🚀\n\n'
                  '현재 재정 상황과 목표만 알려주시면,\n'
                  '소통플랜을 만들어드릴게요! 🤝',
            ],
            delayBetweenMessages: 500,
          );

          await addSectionMessages(onboarding3Section);

          _buttonClicked = false;
          notifyListeners();
        }
        break;

      case ChatStep.onboarding3:
        if (response == '좋아요, 시작할게요!') {
          _buttonClicked = true;
          addMessage(response, MessageType.user);
          notifyListeners();
          _currentStep = ChatStep.planName;
          notifyListeners();

          // planName 섹터 (메시지 1개)
          final planNameSection = ChatSection(
            step: ChatStep.planName,
            messages: [
              '$_userName님은 어떤 목표로 돈을 모으고 싶으세요? 💭\n\n플랜에 이름을 붙여주세요.\n예: 세계여행🌍 / 학자금 모으기🧑‍🎓',
            ],
            delayBetweenMessages: 500,
          );

          await addSectionMessages(planNameSection);

          _buttonClicked = false;
          notifyListeners();
        }
        break;

      case ChatStep.planName:
        if (response.isNotEmpty && response.length >= 2) {
          updatePlanInfo(planName: response);
          notifyListeners();

          addMessage('제 플랜 이름은 "$response"이에요!', MessageType.user);

          // targetAmount 섹터 (메시지 1개)
          final targetAmountSection = ChatSection(
            step: ChatStep.targetAmount,
            messages: ['좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n원하시는 금액을 입력해주세요!'],
            delayBetweenMessages: 500,
          );

          _currentStep = ChatStep.targetAmount;
          notifyListeners();
          await addSectionMessages(targetAmountSection);
        } else {
          // 에러 메시지 (1개)
          final errorSection = ChatSection(
            step: ChatStep.planName,
            messages: ['플랜 이름을 2글자 이상 입력해주세요.'],
            delayBetweenMessages: 500,
          );
          await addSectionMessages(errorSection);
        }
        break;

      case ChatStep.targetAmount:
        {
          final amountStr = response.replaceAll(',', '').trim();
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) {
            addMessage(
              '목표 금액은 ${SavingPlanCalculator.formatAmount(amount)}원이에요!',
              MessageType.user,
            );
            updatePlanInfo(targetAmount: amount);
            notifyListeners();

            // currentAssetAsk 섹터 (메시지 1개)
            final currentAssetAskSection = ChatSection(
              step: ChatStep.currentAssetAsk,
              messages: [
                '보유하고 계신 자산이 있으신가요? 😊\n보유하고 계신 자산 금액을 입력해주세요.\n\n💡 소통 tip 💡\n보유 자산을 입력하시면 목표 금액에서 자동 차감돼요!\n따라서 플랜에 보유 자산을 반영하고 싶지 않다면 \'없어요\' 버튼을 눌러주세요.',
              ],
              delayBetweenMessages: 500,
            );

            _currentStep = ChatStep.currentAssetAsk;
            notifyListeners();
            await addSectionMessages(currentAssetAskSection);
          } else {
            // 에러 메시지 (1개)
            final errorSection = ChatSection(
              step: ChatStep.targetAmount,
              messages: ['올바른 목표 금액을 입력해주세요. (예: 1000000)'],
              delayBetweenMessages: 500,
            );
            await addSectionMessages(errorSection);
          }
          break;
        }

      case ChatStep.currentAssetAsk:
        {
          final lower = response.trim().toLowerCase();
          if (lower == '없어요' ||
              lower == '없음' ||
              lower == '없다' ||
              lower == 'no') {
            addMessage('보유 자산 없이 진행할게요!', MessageType.user);
            updatePlanInfo(currentAsset: 0);
            notifyListeners();

            // monthlyIncome 섹터 (메시지 1개)
            final monthlyIncomeSection = ChatSection(
              step: ChatStep.monthlyIncome,
              messages: [
                '좋아요! 이제 회원님의 월 수입을 입력해볼게요. 💼\n\n💡 소통 tip 💡\n월 수입은 한 달 동안 들어오는 모든 돈이에요.\n예: 급여, 용돈, 사업 수입, 이자·배당금 등\n\n고정되지 않은 수입은 최근 3개월 평균치를 입력해주세요😉',
              ],
              delayBetweenMessages: 500,
            );

            _currentStep = ChatStep.monthlyIncome;
            notifyListeners();
            await addSectionMessages(monthlyIncomeSection);
          } else if (lower == '있어요' ||
              lower == '있음' ||
              lower == '있다' ||
              lower == 'yes') {
            addMessage('보유 자산이 있어요!', MessageType.user);
            notifyListeners();

            // currentAsset 섹터 (메시지 1개) - "있어요" 선택 시
            final currentAssetSection = ChatSection(
              step: ChatStep.currentAsset,
              messages: [
                '보유하고 계신 자산 금액을 입력해주세요.\n빚(부채)은 보유 자산 입력 시 \'-\'를 붙여서 기입해주세요!',
              ],
              delayBetweenMessages: 500,
            );

            _currentStep = ChatStep.currentAsset;
            notifyListeners();
            await addSectionMessages(currentAssetSection);
          } else {
            // 에러 메시지 (1개)
            final errorSection = ChatSection(
              step: ChatStep.currentAssetAsk,
              messages: ['"있어요" 또는 "없어요"로 답해주세요 🙂'],
              delayBetweenMessages: 500,
            );
            await addSectionMessages(errorSection);
          }
          break;
        }

      case ChatStep.currentAsset:
        {
          final amountStr = response.replaceAll(',', '').trim();
          final amount = double.tryParse(amountStr);
          if (amount != null) {
            addMessage(
              amount.isNegative
                  ? '빚(부채)이 ${SavingPlanCalculator.formatAmount(amount.abs())}원 있어요.'
                  : '보유 자산은 ${SavingPlanCalculator.formatAmount(amount)}원이에요!',
              MessageType.user,
            );
            updatePlanInfo(currentAsset: amount);
            notifyListeners();

            // monthlyIncome 섹터 (메시지 1개)
            final monthlyIncomeSection = ChatSection(
              step: ChatStep.monthlyIncome,
              messages: [
                '좋아요! 이제 회원님의 월 수입을 입력해볼게요. 💼\n\n💡 소통 tip 💡\n월 수입은 한 달 동안 들어오는 모든 돈이에요.\n예: 급여, 용돈, 사업 수입, 이자·배당금 등\n\n고정되지 않은 수입은 최근 3개월 평균치를 입력해주세요😉',
              ],
              delayBetweenMessages: 500,
            );

            _currentStep = ChatStep.monthlyIncome;
            notifyListeners();
            await addSectionMessages(monthlyIncomeSection);
          } else {
            // 에러 메시지 (1개)
            final errorSection = ChatSection(
              step: ChatStep.currentAsset,
              messages: [
                '숫자로 입력해 주세요. (예: 5000000 / -3000000)\n또는 "없어요"라고 입력하셔도 됩니다.',
              ],
              delayBetweenMessages: 500,
            );
            await addSectionMessages(errorSection);
          }
          break;
        }

      case ChatStep.summary:
        if (response == '다음 단계로') {
          addMessage(response, MessageType.user);

          // autoService 섹터 (메시지 1개)
          final autoServiceSection = ChatSection(
            step: ChatStep.autoService,
            messages: [
              '📌 소통 자동등록 서비스란?\n\n소비 입력을 깜빡한 날에도,\n오늘 기록한 일일소비로 자동 등록해드려요.\n물론, 언제든 수정할 수 있어요.\n\n소통 자동등록 서비스는\n별도 비용 없이 제공되는 기능이에요.\n\n👉 소통 자동등록 서비스를 활성화할까요?',
            ],
            delayBetweenMessages: 500,
          );

          await addSectionMessages(autoServiceSection);
          await nextStep();
        } else {
          // 에러 메시지 (1개)
          final errorSection = ChatSection(
            step: ChatStep.summary,
            messages: ['"다음 단계로" 버튼을 눌러주세요.'],
            delayBetweenMessages: 500,
          );
          await addSectionMessages(errorSection);
        }
        break;

      case ChatStep.autoService:
        if (response == '네, 좋아요!') {
          updatePlanInfo(autoService: true);
          addMessage(response, MessageType.user);

          // complete 섹터 (메시지 1개)
          final completeSection = ChatSection(
            step: ChatStep.complete,
            messages: ['완료되었습니다!\n이제 본격적으로 저와 소통해볼까요?'],
            delayBetweenMessages: 500,
          );

          _currentStep = ChatStep.complete;
          notifyListeners();
          await addSectionMessages(completeSection);
        } else {
          // 에러 메시지 (1개)
          final errorSection = ChatSection(
            step: ChatStep.autoService,
            messages: ['"네, 좋아요!" 버튼을 눌러주세요.'],
            delayBetweenMessages: 500,
          );
          await addSectionMessages(errorSection);
        }
        break;

      default:
        break;
    }
  }

  // --------------------------------------
  // 모달 완료 후 섹터 메시지 처리
  // --------------------------------------
  Future<void> addMonthlyFixedCostSection() async {
    final monthlyFixedCostSection = ChatSection(
      step: ChatStep.monthlyFixedCost,
      messages: [
        '이제 소비를 입력해볼게요! ✏️\n소비는 두 단계로 나누어 입력할 거예요.',
        '먼저 월 고정소비를 먼저 입력해볼게요. 🧾\n\n월 고정소비는\n매달 거의 변하지 않고\n정기적으로 나가는 지출이에요.',
        '💡 소통 tip 💡\n월 고정소비는 한 달에 반드시 빠져나가는 비용이에요.\n예: 주거비, 통신비, 보험료, 구독 서비스, 대출 상환금 등',
      ],
      delayBetweenMessages: 500,
    );

    await addSectionMessages(monthlyFixedCostSection);
    // nextStep()은 메시지가 모두 완료된 후에 호출되므로 여기서는 호출하지 않음
    // (모달 완료 후 다음 섹터로 이동)
  }

  Future<void> addDailySpendingSection() async {
    final dailySpendingSection = ChatSection(
      step: ChatStep.dailySpending,
      messages: [
        '이제 하루 단위로 사용하는 일일 소비를 입력해볼게요. 💳\n\n사용자의 노력에 따라 충분히 줄일 수 있는 소비에요,\n소통에서는 지금 작성하실 목표 일일 소비를 인지하고,\n동기부여를 드릴거에요',
        '💡 소통 tip 💡\n일 변동소비는 매일 반복되는 생활비예요.\n예: 식비, 교통비, 카페비, 여가비 등',
        '나중에 레포트 페이지에서\n$_userName님의 일일 소비를\n카테고리별로 꼼꼼히 분석해드릴게요 😉',
      ],
      delayBetweenMessages: 500,
    );

    await addSectionMessages(dailySpendingSection);
    // nextStep()은 메시지가 모두 완료된 후에 호출되므로 여기서는 호출하지 않음
    // (모달 완료 후 다음 섹터로 이동)
  }

  Future<void> addNoSaveMoneySection() async {
    final noSaveMoneySection = ChatSection(
      step: ChatStep.noSaveMoney,
      messages: [
        '현재 $_userName님의 재정상황으로는 저축할 수 있는 금액이 없어😢\n혹시 입력이 잘못된 게 없는지 확인해보실래요?',
      ],
      delayBetweenMessages: 500,
    );

    await addSectionMessages(noSaveMoneySection);
  }

  Future<void> addSummarySection() async {
    // summary 섹터 시작 전에 currentStep을 먼저 업데이트
    _currentStep = ChatStep.summary;
    notifyListeners();

    // summary 섹터: 첫 번째 메시지 + summary 위젯
    // 섹터 시작 시점의 봇 메시지 개수 저장
    final currentBotMessageCount = _messages
        .where((m) => m.type == MessageType.bot)
        .length;
    _sectionStartIndices[ChatStep.summary] = currentBotMessageCount;

    // 첫 번째 메시지 추가
    await addBotMessageWithTyping(
      '이제 모든 입력이 끝났습니다.\n지금까지 입력해주신 내용을 바탕으로 저축 플랜을 계산해드릴게요!',
      delay: 500,
      isLastMessage: false,
      showTypingIndicator: true,
    );

    // 두 번째 메시지: summary 위젯 (도넛 차트만)
    await Future.delayed(const Duration(milliseconds: 500));
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // 0.5초로 단축
    _isTyping = false;
    addMessage('', MessageType.summary);

    // summary 섹터 정보 저장 (첫 번째 메시지 1개 + summary 위젯 1개 = 총 2개)
    _sectionMessageCounts[ChatStep.summary] = 2;
    notifyListeners();
  }

  // --------------------------------------
  // 계산 (요약 추천 멘트도 함께 갱신)
  // --------------------------------------
  SavingCalculationResult? calculate() {
    _calculationVM.updatePlan(_totalPlan);
    _calculationResult = _calculationVM.calculate(); // 위임
    debugPrint(
      '[CALCULATE] '
      'metricIncome=${_totalPlan.result.totalMetrics.monthlyIncomeAmount}, '
      'metricFixed=${_totalPlan.result.totalMetrics.monthlyConsumeAmount}, '
      'metricDaily=${_totalPlan.result.totalMetrics.dailyConsumeAmount}, '
      'dailyNetSaving=${_calculationResult?.dailyNetSaving}',
    );
    // 요약 추천 멘트 갱신
    _updateSummaryRecommendation();

    // 요약 단계면 UI 즉시 반영
    if (_currentStep == ChatStep.summary) {
      notifyListeners();
    }
    return _calculationResult;
  }

  // --------------------------------------
  // 초기화
  // --------------------------------------
  void _resetUserScopedState() {
    _totalPlan = TotalPlan.empty();
    _refData = RefData(planId: '');

    _refDataVM = RefDataViewModel(_refData);
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _calculationVM = SavingPlanCalculator(plan: _totalPlan);

    _calculationResult = null;
    _summaryRecommendation = null;
    _summaryRenderVersion = 0;

    _messages.clear();
    _sectionMessageCounts.clear();
    _sectionStartIndices.clear();

    _currentStep = ChatStep.onboarding1;
    _isTyping = false;
    _buttonClicked = false;
    _isSaving = false;

    _pendingMonthlyCommands.clear();
    _pendingDailyCommands.clear();
    _pendingAutoMonthlyInputs.clear();
    _pendingAutoDailyInputs.clear();
    _pendingRefDataWrites.clear();

    _pendingPlanEditGoalDate = null;
    _pendingPlanEditApplyDate = null;
    _pendingPlanTreeMaterialized = false;

    _hasIncomeInput = false;
    _hasFixedConsumeInput = false;
    _hasDailyInput = false;
    _hasSavedPlan = false;
    _lastPersistedGoal = null;
    _printedInitialPlanTree = false;

    _previewDailyTotal = 0;
    _initialPlanResolved = false;
    _needsInitialUpload = true;
    _refDataLoaded = false;
    _loadedUid = null;
  }

  @override
  void resetSession() {
    _userName = '회원';
    _resetUserScopedState();
    notifyListeners();
  }

  Future<void> initializeChat() async {
    final currentUid = _authRepo.cachedUid ?? _authRepo.currentUserId;

    if (_loadedUid != currentUid) {
      _loadedUid = currentUid;
      _resetUserScopedState();
      await _initializePlanState();
    }

    // 1) 이름 로드
    try {
      _userName = await _authRepo.getUserName();
    } catch (_) {
      _userName = '회원';
    }

    // 2) 초기화 + 인삿말
    _messages.clear();
    _currentStep = ChatStep.onboarding1;
    _summaryRecommendation = null;
    _summaryRenderVersion = 0;
    _calculationResult = null;
    notifyListeners();

    // 초기 인사 섹터 (모달: "소통에 대해 더 알아볼래요" 버튼)
    final greetingSection = ChatSection(
      step: ChatStep.onboarding1,
      messages: [
        '안녕하세요, $_userName님!\n소통에 오신 걸 환영합니다🤗\n\n저는 $_userName님과 함께 재정에 대한 이야기를 나누며,\n$_userName님의 소비 통제를 도와드릴 소통이🤖입니다!',
        '목표 자산까지 가는 길이\n흐트러지지 않도록,\n옆에서 계속 함께할게요.\n\n저와 조금 더 이야기해볼까요?',
      ],
    );

    await addSectionMessages(greetingSection);
  }

  // --------------------------------------
  // 저장
  // --------------------------------------
  Future<bool> savePlan() async {
    //
    if (_isSaving) return false;
    _isSaving = true;
    notifyListeners();
    debugPrint(
      '[savePlan] pendingMonthly=${_pendingMonthlyCommands.length} '
      'pendingDaily=${_pendingDailyCommands.length} '
      'autoMonthly=${_pendingAutoMonthlyInputs.length} '
      'autoDaily=${_pendingAutoDailyInputs.length} '
      '(_hasSavedPlan=$_hasSavedPlan)',
    );
    try {
      await _cacheSnapshotIfPossible();
      await _preparePlanStructureForSave();
      await _waitForPendingRefDataWrites();
      _logPlanTree('Ready To Save');
      if (_totalPlan.planId.isEmpty || !_hasSavedPlan) {
        final savedId = await _planRepo.saveCurrentUserPlan(_totalPlan);
        debugPrint('[savePlan] created new plan docId=$savedId');
        if (savedId.isNotEmpty) {
          _totalPlan = _totalPlan.copyWith(planId: savedId);
          _refData.planId = savedId;
          _refDataVM = RefDataViewModel(_refData);
        }
      } else {
        debugPrint('[savePlan] replace existing planId=${_totalPlan.planId}');
        await _planRepo.replacePlan(_totalPlan);
      }

      if (_totalPlan.planId.isNotEmpty &&
          _refData.planId != _totalPlan.planId) {
        _refData.planId = _totalPlan.planId;
        _refDataVM = RefDataViewModel(_refData);
      }

      await _upsertInitialPlanCategoriesFromRefData();
      await _persistRefDataSnapshot(
        incomes: _refData.monthlyIncomeMap,
        consumes: _refData.monthlyConsumeMap,
        dailyConsumes: _refData.dailyConsumeMap,
      );

      _logPlanTree('After Save');
      _needsInitialUpload = false;
      _lastPersistedGoal = _totalPlan.modEndDate ?? _totalPlan.endDate;
      _planSavedBus?.notify();
      debugPrint('[savePlan] success: _hasSavedPlan $_hasSavedPlan -> true');
      _setHasSavedPlan(true);
      _clearPlanEditOverrides();
      return true;
    } catch (e, stack) {
      debugPrint('[savePlan] failed: $e');
      debugPrint(stack.toString());
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // --------------------------------------
  // 헬퍼
  // --------------------------------------
  Future<void> waitForTypingToFinish() async {
    while (_isTyping) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void testPrint() {
    print('totalPlan: $_totalPlan');
    print('refData: $refData');
    print('calculationResult: $calculationResult');
    print('summaryRecommendation: $_summaryRecommendation');
  }

  void _clearPlanEditOverrides() {
    _pendingPlanEditGoalDate = null;
    _pendingPlanEditApplyDate = null;
    _pendingPlanTreeMaterialized = false;
  }

  Future<void> _preparePlanStructureForSave() async {
    debugPrint('[preparePlan] start');
    final now = DateTime.now();
    final DateTime start = _totalPlan.startDate != null
        ? DateTime(
            _totalPlan.startDate!.year,
            _totalPlan.startDate!.month,
            _totalPlan.startDate!.day,
          )
        : DateTime(now.year, now.month, now.day);
    if (_totalPlan.startDate == null) {
      _totalPlan = _totalPlan.copyWith(startDate: start);
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _calculationVM.updatePlan(_totalPlan);
    }
    final bool hasPlanEditOverride =
        _hasSavedPlan && _pendingPlanEditGoalDate != null;
    late final DateTime computedGoal;
    if (hasPlanEditOverride) {
      computedGoal = _pendingPlanEditGoalDate!;
      debugPrint(
        '[preparePlan] using PlanEdit projected goal ${computedGoal.toIso8601String()} '
        '(applyDate=${_pendingPlanEditApplyDate?.toIso8601String() ?? '-'})',
      );
    } else {
      final calc = calculate();
      computedGoal = calc?.goalDateTime ?? start.add(const Duration(days: 120));
    }
    final exactPlanEnd = computedGoal;
    final previousGoal = _lastPersistedGoal;
    final previousModEnd = _totalPlan.modEndDate;
    _totalPlan = _totalPlan.copyWith(modEndDate: computedGoal);
    final planEnd = _totalPlan.modEndDate ?? computedGoal;
    final persistedEnd = _hasSavedPlan && _totalPlan.endDate != null
        ? _totalPlan.endDate!
        : planEnd;
    debugPrint(
      '[preparePlan] startDate=$start goal=$computedGoal modEnd=${_totalPlan.modEndDate}',
    );
    if (_totalPlan.modEndDate != null &&
        computedGoal != _totalPlan.modEndDate) {
      debugPrint(
        '[preparePlan] WARNING goal!=modEnd (${computedGoal.toIso8601String()} vs ${_totalPlan.modEndDate!.toIso8601String()})',
      );
    }
    if (previousModEnd != _totalPlan.modEndDate) {
      debugPrint(
        '[preparePlan] modEnd changed: prev=${previousModEnd?.toIso8601String() ?? '-'} '
        'next=${_totalPlan.modEndDate?.toIso8601String() ?? '-'} '
        'endDate=${_totalPlan.endDate?.toIso8601String() ?? '-'}',
      );
    }

    // ⭐ 1) 먼저 RefData coverage 확장 (항상 실행)
    await _ensureRefDataCoverage(start, planEnd);

    // ⭐ 2) 아직 저장되지 않은 플랜이면 skeleton 재생성
    final shouldRebuildSkeleton = _totalPlan.subPlans.isEmpty;
    if (shouldRebuildSkeleton) {
      _totalPlan = _totalPlan.copyWith(
        startDate: start,
        endDate: persistedEnd,
        modEndDate: planEnd,
        subPlans: _buildInitialSubPlanSkeleton(start, planEnd),
      );
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _calculationVM.updatePlan(_totalPlan);
    }

    // ⭐ 3) pending 커맨드 확인
    final hasPending =
        _pendingMonthlyCommands.isNotEmpty ||
        _pendingDailyCommands.isNotEmpty ||
        _pendingAutoMonthlyInputs.isNotEmpty ||
        _pendingAutoDailyInputs.isNotEmpty;
    debugPrint(
      '[preparePlan] hasPending=$hasPending '
      '(monthly=${_pendingMonthlyCommands.length} '
      'daily=${_pendingDailyCommands.length} '
      'autoMonthly=${_pendingAutoMonthlyInputs.length} '
      'autoDaily=${_pendingAutoDailyInputs.length})',
    );

    if (!hasPending) {
      // 커맨드가 없으면 기간만 업데이트하고 종료
      _totalPlan = _totalPlan.copyWith(
        startDate: start,
        endDate: persistedEnd,
        modEndDate: planEnd,
      );
      _totalPlan = hasPlanEditOverride
          ? _materializeEditedPlanTree(
              plan: _totalPlan,
              refData: _refData,
              goalDate: exactPlanEnd,
              monthlyCommands: const <UpdateMonthlyCommand>[],
              dailyCommands: const <UpdateDailyCommand>[],
            )
          : _applyExactPlanEnd(_totalPlan, exactPlanEnd);
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _calculationVM.updatePlan(_totalPlan);
      debugPrint('[preparePlan] no pending commands, only updated period');
      return;
    }

    // ⭐ 4) 이하 기존 커맨드 처리 로직
    var monthlyCommands = <UpdateMonthlyCommand>[
      ..._pendingMonthlyCommands,
      ..._pendingAutoMonthlyInputs.map(
        (input) => UpdateMonthlyCommand(
          applyMonth: input.applyMonth,
          modEndMonth: DateTime(planEnd.year, planEnd.month, 1),
          entries: List<Entry>.from(input.entries),
          newDocumentId: input.newDocumentId,
          previousDocumentId: input.previousDocumentId,
          isIncome: input.isIncome,
          allowBeforePlanStart: input.allowBeforePlanStart,
        ),
      ),
    ];

    var dailyCommands = <UpdateDailyCommand>[
      ..._pendingDailyCommands,
      ..._pendingAutoDailyInputs.map(
        (input) => UpdateDailyCommand(
          applyDate: input.applyDate,
          modEndDate: DateTime(planEnd.year, planEnd.month, planEnd.day),
          entries: List<Entry>.from(input.entries),
          newDailyId: input.newDocumentId,
          newMiniDocId: input.newMiniDocId ?? _nextMiniDocId(input.applyDate),
          previousDailyId: input.previousDocumentId,
          allowBeforePlanStart: input.allowBeforePlanStart,
        ),
      ),
    ];

    // no-op 필터링
    monthlyCommands = monthlyCommands
        .where((cmd) => cmd.newDocumentId != cmd.previousDocumentId)
        .toList();
    dailyCommands = dailyCommands
        .where((cmd) => cmd.newDailyId != cmd.previousDailyId)
        .toList();
    debugPrint(
      '[preparePlan] final monthly=${monthlyCommands.length}, daily=${dailyCommands.length}',
    );

    bool trimmedAfterGoal = false;

    if (monthlyCommands.isEmpty && dailyCommands.isEmpty) {
      _totalPlan = _totalPlan.copyWith(
        startDate: start,
        endDate: persistedEnd,
        modEndDate: planEnd,
      );
      _totalPlan = hasPlanEditOverride
          ? _materializeEditedPlanTree(
              plan: _totalPlan,
              refData: _refData,
              goalDate: exactPlanEnd,
              monthlyCommands: const <UpdateMonthlyCommand>[],
              dailyCommands: const <UpdateDailyCommand>[],
            )
          : _applyExactPlanEnd(_totalPlan, exactPlanEnd);
      if (previousGoal != null && exactPlanEnd.isBefore(previousGoal)) {
        trimmedAfterGoal = _trimPlanBeyond(exactPlanEnd);
        _totalPlan = hasPlanEditOverride
            ? _materializeEditedPlanTree(
                plan: _totalPlan,
                refData: _refData,
                goalDate: exactPlanEnd,
                monthlyCommands: const <UpdateMonthlyCommand>[],
                dailyCommands: const <UpdateDailyCommand>[],
              )
            : _applyExactPlanEnd(_totalPlan, exactPlanEnd);
      }
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _calculationVM.updatePlan(_totalPlan);
      if (trimmedAfterGoal) {
        await _persistRefDataSnapshot(
          incomes: _refData.monthlyIncomeMap,
          consumes: _refData.monthlyConsumeMap,
          dailyConsumes: _refData.dailyConsumeMap,
        );
      }
      debugPrint('[preparePlan] commands filtered out, nothing to mutate');
      return;
    }

    if (_pendingPlanTreeMaterialized) {
      _totalPlan = _materializeEditedPlanTree(
        plan: _totalPlan.copyWith(
          startDate: start,
          endDate: persistedEnd,
          modEndDate: planEnd,
        ),
        refData: _refData,
        goalDate: exactPlanEnd,
        monthlyCommands: monthlyCommands,
        dailyCommands: dailyCommands,
      );
      if (previousGoal != null && exactPlanEnd.isBefore(previousGoal)) {
        trimmedAfterGoal = _trimPlanBeyond(exactPlanEnd);
        _totalPlan = _materializeEditedPlanTree(
          plan: _totalPlan,
          refData: _refData,
          goalDate: exactPlanEnd,
          monthlyCommands: monthlyCommands,
          dailyCommands: dailyCommands,
        );
      }
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _calculationVM.updatePlan(_totalPlan);
      _refData.setReferenceDate(DateTime.now());
      _refDataVM = RefDataViewModel(_refData);
      await _persistRefDataSnapshot(
        incomes: _refData.monthlyIncomeMap,
        consumes: _refData.monthlyConsumeMap,
        dailyConsumes: _refData.dailyConsumeMap,
      );
      _pendingMonthlyCommands.clear();
      _pendingDailyCommands.clear();
      _pendingAutoMonthlyInputs.clear();
      _pendingAutoDailyInputs.clear();
      _pendingPlanTreeMaterialized = false;
      if (trimmedAfterGoal) {
        debugPrint('[preparePlan] trimmed materialized plan after goal');
      }
      debugPrint(
        '[preparePlan] pending plan already materialized; skip mutation',
      );
      return;
    }

    final TotalPlan basePlan = _totalPlan.subPlans.isEmpty
        ? _totalPlan.copyWith(
            subPlans: _buildInitialSubPlanSkeleton(start, planEnd),
          )
        : _totalPlan;

    final snapshot = PlanSnapshot(
      totalPlan: basePlan,
      monthlyIncomes: Map.from(_refData.monthlyIncomeMap),
      monthlyConsumes: Map.from(_refData.monthlyConsumeMap),
      dailyConsumes: Map.from(_refData.dailyConsumeMap),
    );

    final result = _mutationService.applyCommands(
      monthlyCommands: monthlyCommands,
      dailyCommands: dailyCommands,
      snapshot: snapshot,
    );

    final updatedRefData = RefData(
      planId: _refData.planId,
      monthlyIncomes: result.monthlyIncomes,
      monthlyConsumes: result.monthlyConsumes,
      dailyConsumes: result.dailyConsumes,
    );
    _totalPlan = _materializeEditedPlanTree(
      plan: result.totalPlan,
      refData: updatedRefData,
      goalDate: exactPlanEnd,
      monthlyCommands: monthlyCommands,
      dailyCommands: dailyCommands,
    );
    debugPrint(
      '[applyPlanEditResult] updated totalPlan planId=${_totalPlan.planId}',
    );
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _calculationVM.updatePlan(_totalPlan);
    _refData = updatedRefData;
    _refData.setReferenceDate(DateTime.now());
    if (previousGoal != null && exactPlanEnd.isBefore(previousGoal)) {
      trimmedAfterGoal = _trimPlanBeyond(exactPlanEnd);
      _totalPlan = _materializeEditedPlanTree(
        plan: _totalPlan,
        refData: _refData,
        goalDate: exactPlanEnd,
        monthlyCommands: monthlyCommands,
        dailyCommands: dailyCommands,
      );
    }
    _refDataVM = RefDataViewModel(_refData);
    await _persistRefDataSnapshot(
      incomes: _refData.monthlyIncomeMap,
      consumes: _refData.monthlyConsumeMap,
      dailyConsumes: _refData.dailyConsumeMap,
    );
    _pendingMonthlyCommands.clear();
    _pendingDailyCommands.clear();
    _pendingAutoMonthlyInputs.clear();
    _pendingAutoDailyInputs.clear();
    _pendingPlanTreeMaterialized = false;
  }

  Future<void> _ensureRefDataCoverage(DateTime start, DateTime end) async {
    // 구간 확인 진행

    final tasks = <Future<void>>[];
    final months = _monthSequence(start, end);

    final incomeId = _refData.primaryMonthlyIncomeId;
    if (incomeId != null) {
      final income = _refData.monthlyIncomeMap[incomeId];
      if (income != null) {
        // 구간 확인
        final missing = months
            .where((m) => !_containsMonth(income.yearMonthList, m))
            .toList();
        if (missing.isNotEmpty) {
          // 빠진 구간 없다면
          final updated = income.addMonths(missing);
          _refData.monthlyIncomeMap[incomeId] = updated;
          tasks.add(_refDataRepo.saveMonthlyIncome(updated));
        }
      }
    }

    final consumeId = _refData.primaryMonthlyConsumeId;
    if (consumeId != null) {
      final consume = _refData.monthlyConsumeMap[consumeId];
      if (consume != null) {
        final missing = months
            .where((m) => !_containsMonth(consume.yearMonthList, m))
            .toList();
        if (missing.isNotEmpty) {
          final updated = consume.addMonths(missing);
          _refData.monthlyConsumeMap[consumeId] = updated;
          tasks.add(_refDataRepo.saveMonthlyConsume(updated));
        }
      }
    }

    final dailyId = _refData.primaryDailyConsumeId;
    if (dailyId != null) {
      final daily = _refData.dailyConsumeMap[dailyId];
      if (daily != null) {
        final normalizedStart = DateTime(start.year, start.month, start.day);
        final normalizedEnd = DateTime(end.year, end.month, end.day);
        final newStart = daily.startDate.isAfter(normalizedStart)
            ? normalizedStart
            : daily.startDate;
        final newEnd = daily.endDate.isBefore(normalizedEnd)
            ? normalizedEnd
            : daily.endDate;
        if (newStart != daily.startDate || newEnd != daily.endDate) {
          final updated = daily.copyWith(startDate: newStart, endDate: newEnd);
          _refData.dailyConsumeMap[dailyId] = updated;
          tasks.add(_refDataRepo.saveDailyConsume(updated));
        }
      }
    }

    if (tasks.isNotEmpty) {
      await Future.wait(tasks);
    }
  }

  Future<void> _persistRefDataSnapshot({
    required Map<String, MonthlyIncome> incomes,
    required Map<String, MonthlyConsume> consumes,
    required Map<String, DailyConsume> dailyConsumes,
  }) async {
    final tasks = <Future<void>>[];
    for (final income in incomes.values) {
      tasks.add(_refDataRepo.saveMonthlyIncome(income));
    }
    for (final consume in consumes.values) {
      tasks.add(_refDataRepo.saveMonthlyConsume(consume));
    }
    for (final daily in dailyConsumes.values) {
      tasks.add(_refDataRepo.saveDailyConsume(daily));
    }
    if (tasks.isNotEmpty) {
      await Future.wait(tasks);
    }
  }

  List<DateTime> _monthSequence(DateTime start, DateTime end) {
    final list = <DateTime>[];
    var cursor = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(last)) {
      list.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return list;
  }

  Map<String, SubPlan> _buildInitialSubPlanSkeleton(
    DateTime start,
    DateTime end,
  ) {
    final result = <String, SubPlan>{};
    final metrics = _totalPlan.result.totalMetrics;
    final months = _monthSequence(start, end);
    for (final monthStart in months) {
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
      final actualStart = _isSameMonth(monthStart, start)
          ? DateTime(start.year, start.month, start.day)
          : monthStart;
      final isFinalMonth = _isSameMonth(monthStart, end);
      final normalizedEnd = isFinalMonth
          ? DateTime(end.year, end.month, end.day)
          : monthEnd;
      final actualEnd = normalizedEnd;
      final fractionalSeconds = isFinalMonth
          ? min(86399, max(0, end.difference(normalizedEnd).inSeconds))
          : 0;
      final key = _formatYearMonth(monthStart);
      final miniId = '${key}_mini_seed';
      final monthlyIncomeId =
          _refData.primaryMonthlyIncomeId ?? _fallbackDocId('income');
      final monthlyConsumeId =
          _refData.primaryMonthlyConsumeId ?? _fallbackDocId('consume');
      final dailyConsumeId =
          _refData.primaryDailyConsumeId ?? _fallbackDocId('daily');
      final income = monthlyIncomeId != _fallbackDocId('income')
          ? _refData.monthlyIncomeMap[monthlyIncomeId]
          : null;
      final consume = monthlyConsumeId != _fallbackDocId('consume')
          ? _refData.monthlyConsumeMap[monthlyConsumeId]
          : null;
      final daily = dailyConsumeId != _fallbackDocId('daily')
          ? _refData.dailyConsumeMap[dailyConsumeId]
          : null;
      final incomeSum = monthlyIncomeId != _fallbackDocId('income')
          ? _refData.monthlyIncomeSum(monthlyIncomeId)
          : metrics.monthlyIncomeAmount.toDouble();
      final consumeSum = monthlyConsumeId != _fallbackDocId('consume')
          ? _refData.monthlyConsumeSum(monthlyConsumeId)
          : metrics.monthlyConsumeAmount.toDouble();
      final dailySum = dailyConsumeId != _fallbackDocId('daily')
          ? _refData.dailyConsumeSum(dailyConsumeId)
          : metrics.dailyConsumeAmount.toDouble();
      final mini = MiniPlan(
        docId: miniId,
        yearMonth: monthStart,
        startDate: actualStart,
        endDate: actualEnd,
        monthlyIncomeId: monthlyIncomeId,
        monthlyConsumeId: monthlyConsumeId,
        dailyConsumeId: dailyConsumeId,
        monthlyIncomeRef: income,
        monthlyConsumeRef: consume,
        dailyConsumeRef: daily,
        monthlyIncomeAmount: incomeSum.round(),
        monthlyConsumeAmount: consumeSum.round(),
        dailyConsumeAmount: dailySum.round(),
      ).recalculateNetAmounts();
      result[key] = SubPlan(
        yearMonth: monthStart,
        headDocId: miniId,
        miniPlans: {miniId: mini},
        miniResult: MiniPlanResult(
          headDocId: miniId,
          miniMetrics: [mini.toMetrics()],
          miniPlanHead: mini,
        ),
        fractionalEndSeconds: fractionalSeconds,
      );
    }
    return result;
  }

  bool _containsMonth(List<DateTime> source, DateTime target) {
    return source.any((m) => m.year == target.year && m.month == target.month);
  }

  String _formatYearMonth(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}';
  }

  String _fallbackDocId(String kind) => 'bootstrap_$kind';

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  TotalPlan _buildPreviewPlan() {
    if (_hasSavedPlan) {
      return _totalPlan;
    }
    final start = _normalizeDay(_totalPlan.startDate ?? DateTime.now());
    final horizonEnd = start.add(const Duration(days: 1095));
    return _totalPlan
        .copyWith(
          startDate: start,
          endDate: horizonEnd,
          modEndDate: horizonEnd,
          subPlans: _buildInitialSubPlanSkeleton(start, horizonEnd),
        )
        .recalculateTotals();
  }

  DateTime _clampPreviewDate(DateTime date, TotalPlan plan) {
    var normalized = _normalizeDay(date);
    final start = plan.startDate != null
        ? _normalizeDay(plan.startDate!)
        : null;
    final end = plan.modEndDate != null
        ? _normalizeDay(plan.modEndDate!)
        : (plan.endDate != null ? _normalizeDay(plan.endDate!) : null);
    if (start != null && normalized.isBefore(start)) {
      normalized = start;
    }
    if (end != null && normalized.isAfter(end)) {
      normalized = end;
    }
    return normalized;
  }

  String _nextMiniDocId(DateTime applyDate) {
    final key = _formatYearMonth(applyDate);
    final subPlan = _totalPlan.subPlans[key];
    var maxSeq = 0;
    if (subPlan != null) {
      for (final id in subPlan.miniPlans.keys) {
        final parts = id.split('-');
        if (parts.length != 2) continue;
        final seq = int.tryParse(parts[1]) ?? 0;
        if (seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }
    final nextSeq = (maxSeq + 1).toString().padLeft(3, '0');
    return '$key-$nextSeq';
  }

  void _setHasSavedPlan(bool value, {bool syncCache = true}) {
    if (_hasSavedPlan == value && value) {
      if (syncCache) {
        unawaited(_cacheSnapshotIfPossible());
      }
      return;
    }
    debugPrint('[ChatPlanViewModel] _hasSavedPlan: $_hasSavedPlan -> $value');
    _hasSavedPlan = value;
    final uid = _authRepo.cachedUid ?? _authRepo.currentUserId;
    if (value) {
      if (_lastPersistedGoal == null) {
        _lastPersistedGoal = _totalPlan.modEndDate ?? _totalPlan.endDate;
      }
      if (syncCache && uid != null) {
        unawaited(_authRepo.setHasPlan(true));
        unawaited(_cacheSnapshotIfPossible(uidOverride: uid));
      }
    } else if (syncCache && uid != null) {
      unawaited(_authRepo.setHasPlan(false));
      unawaited(_planCacheRepo.clearSnapshot(uid));
    }
  }

  Future<void> _cacheSnapshotIfPossible({String? uidOverride}) async {
    final uid = uidOverride ?? _authRepo.cachedUid ?? _authRepo.currentUserId;
    if (uid == null) {
      debugPrint('[ChatPlanViewModel] skip cache snapshot: missing uid');
      return;
    }
    await _planCacheRepo.saveSnapshot(
      uid: uid,
      snapshot: PlanCacheSnapshot(
        plan: _totalPlan,
        refData: _refData,
        needsInitialUpload: _needsInitialUpload,
      ),
    );
    debugPrint('[ChatPlanViewModel] cached snapshot for uid=$uid');
  }

  double _sumEntries(List<Entry> entries) =>
      entries.fold<double>(0, (sum, entry) => sum + entry.amount);

  int _fractionalFromDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final seconds = date.difference(normalized).inSeconds;
    if (seconds <= 0) return 0;
    if (seconds >= 86399) return 86399;
    return seconds;
  }

  TotalPlan _materializeEditedPlanTree({
    required TotalPlan plan,
    required RefData refData,
    required DateTime goalDate,
    required List<UpdateMonthlyCommand> monthlyCommands,
    required List<UpdateDailyCommand> dailyCommands,
  }) {
    final planStart = _normalizeDay(
      plan.startDate ?? plan.creationDate ?? goalDate,
    );
    var normalizedGoal = goalDate;
    if (_normalizeDay(normalizedGoal).isBefore(planStart)) {
      normalizedGoal = planStart;
    }
    final goalDay = _normalizeDay(normalizedGoal);
    final firstMonth = DateTime(planStart.year, planStart.month, 1);
    final goalMonth = DateTime(goalDay.year, goalDay.month, 1);
    final updatedSubPlans = <String, SubPlan>{};

    var cursorMonth = firstMonth;
    while (!cursorMonth.isAfter(goalMonth)) {
      final monthEnd = DateTime(cursorMonth.year, cursorMonth.month + 1, 0);
      final rangeStart = _isSameMonth(cursorMonth, planStart)
          ? planStart
          : cursorMonth;
      final rangeEnd = _isSameMonth(cursorMonth, goalDay) ? goalDay : monthEnd;
      final subPlan = _materializeSubPlanMonth(
        plan: plan,
        refData: refData,
        monthStart: cursorMonth,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        exactGoal: normalizedGoal,
        monthlyCommands: monthlyCommands,
        dailyCommands: dailyCommands,
      );
      final key = _formatYearMonth(cursorMonth);
      updatedSubPlans[key] = subPlan;
      cursorMonth = DateTime(cursorMonth.year, cursorMonth.month + 1, 1);
    }

    final materialized = plan
        .copyWith(
          startDate: planStart,
          modEndDate: normalizedGoal,
          subPlans: updatedSubPlans,
        )
        .recalculateTotals();
    _logMaterializedPlanTree(materialized, goalDate);
    return _applyExactPlanEnd(materialized, normalizedGoal);
  }

  SubPlan _materializeSubPlanMonth({
    required TotalPlan plan,
    required RefData refData,
    required DateTime monthStart,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime exactGoal,
    required List<UpdateMonthlyCommand> monthlyCommands,
    required List<UpdateDailyCommand> dailyCommands,
  }) {
    final key = _formatYearMonth(monthStart);
    final existingSubPlan = plan.subPlans[key];
    final existingIds = <String>{
      if (existingSubPlan != null) ...existingSubPlan.miniPlans.keys,
    };
    final assignedIds = <String>{};
    final groups = <_MaterializedMiniGroup>[];
    _MiniPlanAttrs? previousAttrs;

    var cursor = rangeStart;
    while (!cursor.isAfter(rangeEnd)) {
      final sourceMini = _miniForDate(plan, cursor);
      var attrs = sourceMini != null
          ? _attrsFromMini(sourceMini)
          : previousAttrs ??
                _templateAttrsForDate(
                  plan: plan,
                  refData: refData,
                  date: cursor,
                );
      attrs = _applyMonthlyCommandAttrs(
        attrs: attrs,
        monthStart: monthStart,
        refData: refData,
        monthlyCommands: monthlyCommands,
      );
      attrs = _applyDailyCommandAttrs(
        attrs: attrs,
        date: cursor,
        refData: refData,
        dailyCommands: dailyCommands,
      );

      if (groups.isNotEmpty && groups.last.attrs.sameValues(attrs)) {
        groups.last.end = cursor;
        if (sourceMini != null) {
          groups.last.sourceDocIds.add(sourceMini.docId);
        }
      } else {
        groups.add(
          _MaterializedMiniGroup(
            start: cursor,
            end: cursor,
            attrs: attrs,
            sourceDocIds: sourceMini == null ? <String>{} : {sourceMini.docId},
          ),
        );
      }
      previousAttrs = attrs;
      cursor = cursor.add(const Duration(days: 1));
    }

    final minis = <MiniPlan>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final docId = _docIdForMaterializedGroup(
        key: key,
        group: group,
        assignedIds: assignedIds,
        reservedIds: existingIds,
      );
      assignedIds.add(docId);
      minis.add(
        MiniPlan(
          docId: docId,
          yearMonth: monthStart,
          startDate: group.start,
          endDate: group.end,
          prevDocId: i == 0 ? null : minis[i - 1].docId,
          nextDocId: null,
          monthlyIncomeId: group.attrs.monthlyIncomeId,
          monthlyConsumeId: group.attrs.monthlyConsumeId,
          dailyConsumeId: group.attrs.dailyConsumeId,
          monthlyIncomeRef:
              refData.monthlyIncomeMap[group.attrs.monthlyIncomeId],
          monthlyConsumeRef:
              refData.monthlyConsumeMap[group.attrs.monthlyConsumeId],
          dailyConsumeRef: refData.dailyConsumeMap[group.attrs.dailyConsumeId],
          monthlyIncomeAmount: group.attrs.monthlyIncomeAmount,
          monthlyConsumeAmount: group.attrs.monthlyConsumeAmount,
          dailyConsumeAmount: group.attrs.dailyConsumeAmount,
        ).recalculateNetAmounts(),
      );
    }

    final linkedMinis = <String, MiniPlan>{};
    for (var i = 0; i < minis.length; i++) {
      final prev = i == 0 ? null : minis[i - 1].docId;
      final next = i == minis.length - 1 ? null : minis[i + 1].docId;
      final linked = minis[i].copyWith(prevDocId: prev, nextDocId: next);
      linkedMinis[linked.docId] = linked;
    }

    final head = minis.first;
    final fractionalEndSeconds = _isSameMonth(monthStart, exactGoal)
        ? _fractionalFromDate(exactGoal)
        : 0;
    return SubPlan(
      yearMonth: monthStart,
      headDocId: head.docId,
      miniPlans: linkedMinis,
      miniResult: MiniPlanResult(
        headDocId: head.docId,
        miniMetrics: linkedMinis.values
            .map((mini) => mini.toMetrics())
            .toList(),
        miniPlanHead: head,
      ),
      fractionalEndSeconds: fractionalEndSeconds,
    ).recalculate();
  }

  _MiniPlanAttrs _attrsFromMini(MiniPlan mini) {
    return _MiniPlanAttrs(
      monthlyIncomeId: mini.monthlyIncomeId,
      monthlyConsumeId: mini.monthlyConsumeId,
      dailyConsumeId: mini.dailyConsumeId,
      monthlyIncomeAmount: mini.monthlyIncomeAmount,
      monthlyConsumeAmount: mini.monthlyConsumeAmount,
      dailyConsumeAmount: mini.dailyConsumeAmount,
    );
  }

  _MiniPlanAttrs _templateAttrsForDate({
    required TotalPlan plan,
    required RefData refData,
    required DateTime date,
  }) {
    final nearest = _nearestMiniForDate(plan, date);
    if (nearest != null) {
      return _attrsFromMini(nearest);
    }
    final metrics = plan.result.totalMetrics;
    return _MiniPlanAttrs(
      monthlyIncomeId:
          refData.primaryMonthlyIncomeId ?? _fallbackDocId('income'),
      monthlyConsumeId:
          refData.primaryMonthlyConsumeId ?? _fallbackDocId('consume'),
      dailyConsumeId: refData.primaryDailyConsumeId ?? _fallbackDocId('daily'),
      monthlyIncomeAmount: refData.primaryMonthlyIncomeSum.round() > 0
          ? refData.primaryMonthlyIncomeSum.round()
          : metrics.monthlyIncomeAmount,
      monthlyConsumeAmount: refData.primaryMonthlyConsumeSum.round() > 0
          ? refData.primaryMonthlyConsumeSum.round()
          : metrics.monthlyConsumeAmount,
      dailyConsumeAmount: refData.primaryDailyConsumeSum.round() > 0
          ? refData.primaryDailyConsumeSum.round()
          : metrics.dailyConsumeAmount,
    );
  }

  _MiniPlanAttrs _applyMonthlyCommandAttrs({
    required _MiniPlanAttrs attrs,
    required DateTime monthStart,
    required RefData refData,
    required List<UpdateMonthlyCommand> monthlyCommands,
  }) {
    var result = attrs;
    final incomeCommand = _latestMonthlyCommandForMonth(
      monthStart: monthStart,
      monthlyCommands: monthlyCommands,
      isIncome: true,
    );
    if (incomeCommand != null) {
      result = result.copyWith(
        monthlyIncomeId: incomeCommand.newDocumentId,
        monthlyIncomeAmount: _sumEntries(incomeCommand.entries).round(),
      );
    }
    final consumeCommand = _latestMonthlyCommandForMonth(
      monthStart: monthStart,
      monthlyCommands: monthlyCommands,
      isIncome: false,
    );
    if (consumeCommand != null) {
      result = result.copyWith(
        monthlyConsumeId: consumeCommand.newDocumentId,
        monthlyConsumeAmount: _sumEntries(consumeCommand.entries).round(),
      );
    }
    return result;
  }

  _MiniPlanAttrs _applyDailyCommandAttrs({
    required _MiniPlanAttrs attrs,
    required DateTime date,
    required RefData refData,
    required List<UpdateDailyCommand> dailyCommands,
  }) {
    final command = _latestDailyCommandForDate(
      date: date,
      dailyCommands: dailyCommands,
    );
    if (command == null) {
      return attrs;
    }
    return attrs.copyWith(
      dailyConsumeId: command.newDailyId,
      dailyConsumeAmount: _sumEntries(command.entries).round(),
    );
  }

  UpdateMonthlyCommand? _latestMonthlyCommandForMonth({
    required DateTime monthStart,
    required List<UpdateMonthlyCommand> monthlyCommands,
    required bool isIncome,
  }) {
    UpdateMonthlyCommand? latest;
    final normalizedMonth = DateTime(monthStart.year, monthStart.month, 1);
    for (final command in monthlyCommands) {
      if (command.isIncome != isIncome) continue;
      final applyMonth = DateTime(
        command.applyMonth.year,
        command.applyMonth.month,
        1,
      );
      final endMonth = DateTime(
        command.modEndMonth.year,
        command.modEndMonth.month,
        1,
      );
      if (normalizedMonth.isBefore(applyMonth) ||
          normalizedMonth.isAfter(endMonth)) {
        continue;
      }
      latest = command;
    }
    return latest;
  }

  UpdateDailyCommand? _latestDailyCommandForDate({
    required DateTime date,
    required List<UpdateDailyCommand> dailyCommands,
  }) {
    UpdateDailyCommand? latest;
    final normalized = _normalizeDay(date);
    for (final command in dailyCommands) {
      final apply = _normalizeDay(command.applyDate);
      final end = _normalizeDay(command.modEndDate);
      if (normalized.isBefore(apply) || normalized.isAfter(end)) {
        continue;
      }
      latest = command;
    }
    return latest;
  }

  MiniPlan? _miniForDate(TotalPlan plan, DateTime date) {
    final key = _formatYearMonth(date);
    final subPlan = plan.subPlans[key];
    if (subPlan == null) return null;
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

  MiniPlan? _nearestMiniForDate(TotalPlan plan, DateTime date) {
    MiniPlan? latestBefore;
    MiniPlan? earliestAfter;
    final minis = <MiniPlan>[];
    final entries = plan.subPlans.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      minis.addAll(entry.value.orderedMinis());
    }
    for (final mini in minis) {
      if (!mini.endDate.isAfter(date)) {
        latestBefore = mini;
      } else if (earliestAfter == null && mini.startDate.isAfter(date)) {
        earliestAfter = mini;
      }
    }
    return latestBefore ?? earliestAfter;
  }

  String _docIdForMaterializedGroup({
    required String key,
    required _MaterializedMiniGroup group,
    required Set<String> assignedIds,
    required Set<String> reservedIds,
  }) {
    if (group.sourceDocIds.length == 1) {
      final sourceId = group.sourceDocIds.single;
      if (!assignedIds.contains(sourceId)) {
        return sourceId;
      }
    }
    var seq = 1;
    while (true) {
      final id = '$key-${seq.toString().padLeft(3, '0')}';
      if (!assignedIds.contains(id) && !reservedIds.contains(id)) {
        return id;
      }
      seq++;
    }
  }

  void _logMaterializedPlanTree(TotalPlan plan, DateTime goalDate) {
    final ordered = plan.subPlans.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (ordered.isEmpty) {
      debugPrint('[materializePlan] empty subPlans goal=$goalDate');
      return;
    }
    final lastSubPlan = ordered.last.value;
    final lastMini = lastSubPlan.orderedMinis().last;
    debugPrint(
      '[materializePlan] goal=${goalDate.toIso8601String()} '
      'months=${ordered.length} '
      'lastMini=${lastMini.docId} '
      '${lastMini.startDate.toIso8601String()}~${lastMini.endDate.toIso8601String()}',
    );
  }

  TotalPlan _applyExactPlanEnd(TotalPlan plan, DateTime exactEnd) {
    final normalized = DateTime(exactEnd.year, exactEnd.month, exactEnd.day);
    final fractionalSeconds = min(
      86399,
      max(0, exactEnd.difference(normalized).inSeconds),
    );
    final key = _formatYearMonth(normalized);
    final subPlan = plan.subPlans[key];
    if (subPlan == null) {
      return plan.copyWith(modEndDate: exactEnd);
    }
    if (subPlan.fractionalEndSeconds == fractionalSeconds &&
        plan.modEndDate == exactEnd) {
      return plan;
    }
    final updatedSubPlans = Map<String, SubPlan>.from(plan.subPlans)
      ..[key] = subPlan.copyWith(fractionalEndSeconds: fractionalSeconds);
    return plan.copyWith(subPlans: updatedSubPlans, modEndDate: exactEnd);
  }

  bool _trimPlanBeyond(DateTime goal) {
    final targetMonth = DateTime(goal.year, goal.month, 1);
    final updatedSubPlans = Map<String, SubPlan>.from(_totalPlan.subPlans);
    final keysToRemove = <String>[];
    updatedSubPlans.forEach((key, subPlan) {
      final month = DateTime(
        subPlan.yearMonth.year,
        subPlan.yearMonth.month,
        1,
      );
      if (month.isAfter(targetMonth)) {
        keysToRemove.add(key);
      }
    });
    var planChanged = false;
    for (final key in keysToRemove) {
      updatedSubPlans.remove(key);
      planChanged = true;
    }
    if (planChanged) {
      _totalPlan = _totalPlan
          .copyWith(subPlans: updatedSubPlans)
          .recalculateTotals();
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _calculationVM.updatePlan(_totalPlan);
    }
    final refChanged = _trimRefDataAfter(goal);
    if (refChanged) {
      _refData.setReferenceDate(DateTime.now());
      _refDataVM = RefDataViewModel(_refData);
    }
    return planChanged || refChanged;
  }

  bool _trimRefDataAfter(DateTime goal) {
    final goalMonth = DateTime(goal.year, goal.month, 1);
    var changed = false;

    void trimMonthly<T extends Object>({
      required Map<String, T> map,
      required List<DateTime> Function(T item) monthsSelector,
      required T Function(T item, List<DateTime> months) remover,
    }) {
      map.forEach((key, value) {
        final months = monthsSelector(value);
        final removal = months.where((m) => m.isAfter(goalMonth)).toList();
        if (removal.isEmpty) return;
        changed = true;
        final updated = remover(value, removal);
        map[key] = updated;
      });
    }

    trimMonthly<MonthlyIncome>(
      map: _refData.monthlyIncomeMap,
      monthsSelector: (income) => income.yearMonthList,
      remover: (income, months) => income.removeMonths(months),
    );
    trimMonthly<MonthlyConsume>(
      map: _refData.monthlyConsumeMap,
      monthsSelector: (consume) => consume.yearMonthList,
      remover: (consume, months) => consume.removeMonths(months),
    );

    _refData.dailyConsumeMap.forEach((key, daily) {
      if (!daily.isActive) return;
      if (daily.startDate.isAfter(goal)) {
        _refData.dailyConsumeMap[key] = daily.softDelete(goal);
        changed = true;
      } else if (daily.endDate.isAfter(goal)) {
        _refData.dailyConsumeMap[key] = daily.endAt(goal);
        changed = true;
      }
    });

    return changed;
  }

  Future<void> preparePlanStructureForSummary() async {
    await _preparePlanStructureForSave();
  }

  void _rebuildSkeletonWithLatestGoal() {
    final start = _totalPlan.startDate ?? DateTime.now();
    final goal = _initialCalculate(start: start);
    final skeleton = _buildInitialSubPlanSkeleton(start, goal);
    var updated = _totalPlan
        .copyWith(
          startDate: start,
          endDate: goal,
          modEndDate: goal,
          subPlans: skeleton,
        )
        .recalculateTotals();
    updated = _applyExactPlanEnd(updated, goal);
    _totalPlan = updated;
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _calculationVM.updatePlan(_totalPlan);
    calculate();
  }

  TotalPlan _materializeOnboardingPreviewPlan({
    required TotalPlan seedPlan,
    required DateTime goalDate,
  }) {
    final normalizedStart = _normalizeDay(
      seedPlan.startDate ?? _totalPlan.startDate ?? DateTime.now(),
    );
    var exactGoal = goalDate;
    if (exactGoal.isBefore(normalizedStart)) {
      exactGoal = normalizedStart;
    }
    final skeleton = _buildInitialSubPlanSkeleton(normalizedStart, exactGoal);
    final materialized = seedPlan
        .copyWith(
          startDate: normalizedStart,
          endDate: exactGoal,
          modEndDate: exactGoal,
          subPlans: skeleton,
        )
        .recalculateTotals();
    return _applyExactPlanEnd(materialized, exactGoal);
  }

  DateTime _initialCalculate({required DateTime start}) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final horizonEnd = normalizedStart.add(
      const Duration(days: 1095),
    ); // approx. 3년
    final tempPlan = _totalPlan.copyWith(
      startDate: normalizedStart,
      endDate: horizonEnd,
      modEndDate: horizonEnd,
      subPlans: _buildInitialSubPlanSkeleton(normalizedStart, horizonEnd),
    );
    final tempCalc = SavingPlanCalculator(plan: tempPlan).calculate();
    debugPrint(
      '[initialCalculate] horizon ${horizonEnd.toIso8601String()} '
      'goal=${tempCalc.goalDateTime?.toIso8601String() ?? '-'}',
    );
    debugPrint(
      PlanDebugPrinter.describe(
        plan: _applyExactPlanEnd(
          tempPlan.copyWith(
            endDate: tempCalc.goalDateTime ?? horizonEnd,
            modEndDate: tempCalc.goalDateTime ?? horizonEnd,
          ),
          tempCalc.goalDateTime ?? horizonEnd,
        ),
        refData: _refData,
      ),
    );
    return tempCalc.goalDateTime ?? horizonEnd;
  }

  // TotalPlan _applyExactPlanEnd(TotalPlan plan, DateTime exactEnd) {
  //   final normalized = DateTime(exactEnd.year, exactEnd.month, exactEnd.day);
  //   final fractionalSeconds = min(
  //     86399,
  //     max(0, exactEnd.difference(normalized).inSeconds),
  //   );
  //   final key = _formatYearMonth(normalized);
  //   final subPlan = plan.subPlans[key];
  //   if (subPlan == null) {
  //     return plan.copyWith(modEndDate: exactEnd);
  //   }
  //   if (subPlan.fractionalEndSeconds == fractionalSeconds &&
  //       plan.modEndDate == exactEnd) {
  //     return plan;
  //   }
  //   final updatedSubPlans = Map<String, SubPlan>.from(plan.subPlans)
  //     ..[key] = subPlan.copyWith(fractionalEndSeconds: fractionalSeconds);
  //   return plan.copyWith(subPlans: updatedSubPlans, modEndDate: exactEnd);
  // }

  // Future<void> preparePlanStructureForSummary() async {
  //   await _preparePlanStructureForSave();
  // }
  //
  // void _rebuildSkeletonWithLatestGoal() {
  //   final start = _totalPlan.startDate ?? DateTime.now();
  //   final goal = _initialCalculate(start: start);
  //   final skeleton = _buildInitialSubPlanSkeleton(start, goal);
  //   var updated = _totalPlan
  //       .copyWith(
  //     startDate: start,
  //     endDate: goal,
  //     modEndDate: goal,
  //     subPlans: skeleton,
  //   )
  //       .recalculateTotals();
  //   updated = _applyExactPlanEnd(updated, goal);
  //   _totalPlan = updated;
  //   _totalPlanVM = TotalPlanViewModel(_totalPlan);
  //   _calculationVM.updatePlan(_totalPlan);
  //   calculate();
  // }
  //
  // DateTime _initialCalculate({required DateTime start}) {
  //   final horizonEnd = start.add(const Duration(days: 3650)); // approx. 10년
  //   final tempPlan = _totalPlan.copyWith(
  //     startDate: start,
  //     endDate: horizonEnd,
  //     modEndDate: horizonEnd,
  //     subPlans: _buildInitialSubPlanSkeleton(start, horizonEnd),
  //   );
  //   final tempCalc = SavingPlanCalculator(plan: tempPlan).calculate();
  //   debugPrint(
  //     '[initialCalculate] horizon ${horizonEnd.toIso8601String()} '
  //         'goal=${tempCalc.goalDateTime?.toIso8601String() ?? '-'}',
  //   );
  //   debugPrint(
  //     PlanDebugPrinter.describe(
  //       plan: _applyExactPlanEnd(
  //         tempPlan.copyWith(
  //           endDate: tempCalc.goalDateTime ?? horizonEnd,
  //           modEndDate: tempCalc.goalDateTime ?? horizonEnd,
  //         ),
  //         tempCalc.goalDateTime ?? horizonEnd,
  //       ),
  //       refData: _refData,
  //     ),
  //   );
  //   return tempCalc.goalDateTime ?? horizonEnd;
  // }
}

class _MiniPlanAttrs {
  const _MiniPlanAttrs({
    required this.monthlyIncomeId,
    required this.monthlyConsumeId,
    required this.dailyConsumeId,
    required this.monthlyIncomeAmount,
    required this.monthlyConsumeAmount,
    required this.dailyConsumeAmount,
  });

  final String monthlyIncomeId;
  final String monthlyConsumeId;
  final String dailyConsumeId;
  final int monthlyIncomeAmount;
  final int monthlyConsumeAmount;
  final int dailyConsumeAmount;

  _MiniPlanAttrs copyWith({
    String? monthlyIncomeId,
    String? monthlyConsumeId,
    String? dailyConsumeId,
    int? monthlyIncomeAmount,
    int? monthlyConsumeAmount,
    int? dailyConsumeAmount,
  }) {
    return _MiniPlanAttrs(
      monthlyIncomeId: monthlyIncomeId ?? this.monthlyIncomeId,
      monthlyConsumeId: monthlyConsumeId ?? this.monthlyConsumeId,
      dailyConsumeId: dailyConsumeId ?? this.dailyConsumeId,
      monthlyIncomeAmount: monthlyIncomeAmount ?? this.monthlyIncomeAmount,
      monthlyConsumeAmount: monthlyConsumeAmount ?? this.monthlyConsumeAmount,
      dailyConsumeAmount: dailyConsumeAmount ?? this.dailyConsumeAmount,
    );
  }

  bool sameValues(_MiniPlanAttrs other) {
    return monthlyIncomeId == other.monthlyIncomeId &&
        monthlyConsumeId == other.monthlyConsumeId &&
        dailyConsumeId == other.dailyConsumeId &&
        monthlyIncomeAmount == other.monthlyIncomeAmount &&
        monthlyConsumeAmount == other.monthlyConsumeAmount &&
        dailyConsumeAmount == other.dailyConsumeAmount;
  }
}

class _MaterializedMiniGroup {
  _MaterializedMiniGroup({
    required this.start,
    required this.end,
    required this.attrs,
    required this.sourceDocIds,
  });

  DateTime start;
  DateTime end;
  final _MiniPlanAttrs attrs;
  final Set<String> sourceDocIds;
}

class _PendingMonthlyInput {
  _PendingMonthlyInput({
    required this.applyMonth,
    required this.modEndMonth,
    required this.entries,
    required this.newDocumentId,
    required this.previousDocumentId,
    required this.isIncome,
    required this.allowBeforePlanStart,
  });

  final DateTime applyMonth;
  final DateTime modEndMonth;
  final List<Entry> entries;
  final String newDocumentId;
  final String? previousDocumentId;
  final bool isIncome;
  final bool allowBeforePlanStart;
}

class _PendingDailyInput {
  _PendingDailyInput({
    required this.applyDate,
    required this.modEndDate,
    required this.entries,
    required this.newDailyId,
    required this.previousDailyId,
    this.newMiniDocId,
    required this.allowBeforePlanStart,
  });

  final DateTime applyDate;
  final DateTime modEndDate;
  final List<Entry> entries;
  final String newDailyId;
  final String? previousDailyId;
  final String? newMiniDocId;
  final bool allowBeforePlanStart;
  String get newDocumentId => newDailyId;
  String? get previousDocumentId => previousDailyId;
}

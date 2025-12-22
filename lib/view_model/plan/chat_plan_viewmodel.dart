import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../model/chat_message.dart';
import '../../model/refData/entry.dart';
import '../../model/commands/update_daily_command.dart';
import '../../model/commands/update_monthly_command.dart';
import '../../model/plan/plan_edit_result.dart';
import '../../model/plan/total_plan.dart';
import '../../model/plan/plan_metrics.dart';
import '../../model/plan/mini_plan.dart';
import '../../model/refData/ref_data.dart';
import '../../model/refData/monthly_income.dart';
import '../../model/refData/monthly_consume.dart';
import '../../model/refData/daily_consume.dart';
import '../../model/plan/sub_plan.dart';
import '../../model/saving_calculation_result.dart';
import '../../repository/auth_repository.dart';
import '../../repository/plan_repository.dart';
import '../../repository/ref_data_repository.dart';
import '../../services/plan_debug_printer.dart';
import '../../services/plan_saved_event_bus.dart';
import '../services/ref_data_viewmodel.dart';
import '../services/saving_calculator.dart';
import '../services/total_plan_viewmodel.dart';
import '../../services/plan_mutation_service.dart';
import '../../repository/plan_mutation_repository.dart';
import '../../model/plan/plan_snapshot.dart';
import 'enums/chat_step.dart';

// 기본 회원가입 창의 viewmodel
class ChatPlanViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;
  final PlanSavedEventBus? _planSavedBus;

  ChatPlanViewModel(
    this._authRepo,
    this._planRepo,
    this._refDataRepo, {
    PlanSavedEventBus? planSavedBus,
  })  : _planSavedBus = planSavedBus,
        _mutationRepository = PlanMutationRepository() {
    _mutationService = PlanMutationService(_mutationRepository);
    _refDataVM = RefDataViewModel(_refData);
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _calculationVM = SavingPlanCalculator(plan: _totalPlan);
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

  List<UpdateMonthlyCommand> _pendingMonthlyCommands = [];
  List<UpdateDailyCommand> _pendingDailyCommands = [];
  List<UpdateMonthlyCommand> get pendingMonthlyCommands => _pendingMonthlyCommands;
  List<UpdateDailyCommand> get pendingDailyCommands => _pendingDailyCommands;
  final List<_PendingMonthlyInput> _pendingAutoMonthlyInputs = [];
  final List<_PendingDailyInput> _pendingAutoDailyInputs = [];

  // 계산 결과
  SavingCalculationResult? _calculationResult;
  SavingCalculationResult? get calculationResult => _calculationResult;

  // 요약 추천 멘트 (요약 카드 내부에서 표시)
  String? _summaryRecommendation;
  String? get summaryRecommendation => _summaryRecommendation;

  // 현재 단계
  ChatStep _currentStep = ChatStep.onboarding1;
  ChatStep get currentStep => _currentStep;

  // 메시지 목록
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // 타이핑 상태
  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // 버튼 클릭 상태 (onboarding 단계에서만 사용)
  bool _buttonClicked = false;
  bool get buttonClicked => _buttonClicked;

  late RefDataViewModel _refDataVM;
  final RefDataRepository _refDataRepo;
  bool _refDataLoaded = false;
  late TotalPlanViewModel _totalPlanVM;
  late SavingPlanCalculator _calculationVM;
  final PlanMutationRepository _mutationRepository;
  late final PlanMutationService _mutationService;

  bool _hasIncomeInput = false;
  bool _hasFixedConsumeInput = false;
  bool _hasDailyInput = false;
  bool _hasSavedPlan = false;
  bool _printedInitialPlanTree = false;


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

  Future<void> addBotMessageWithTyping(
      String content, {
        int delay = 1000,
        bool awaitTyping = false,
      }) async {
    _isTyping = true;
    notifyListeners();
    final trimmed = content.trim();
    if (trimmed.isNotEmpty) {
      int actualDelay = delay;
      if (awaitTyping) {
        // 30ms per char, min 800ms, max 2500ms
        actualDelay = (trimmed.length * 30).clamp(800, 2500);
      }
      await Future.delayed(Duration(milliseconds: actualDelay));
      addMessage(trimmed, MessageType.bot);
    }
    _isTyping = false;
    notifyListeners();
  }

  // --------------------------------------
  // 요약 추천 멘트 갱신 로직
  // --------------------------------------
  void _updateSummaryRecommendation() {
    final c = _calculationResult;
    if (c == null || c.dailyNetSaving <= 0) {
      _summaryRecommendation = null;
      return;
    }

    final months = c.daysToGoal / 30.0;
    final curr = _totalPlan.currentAsset.toDouble();
    final amt3m = curr + c.dailyNetSaving * 90;   // 대략 3개월
    final amt6m = curr + c.dailyNetSaving * 180;  // 대략 6개월

    String fmt(double v) => SavingPlanCalculator.formatAmount(v);

    if (months <= 1.0) {
      // 1개월 이하 → 조금 늘리는 걸 추천 (3개월 이상)
      _summaryRecommendation =
      '현재 계획대로라면 목표까지 약 ${months.toStringAsFixed(1)}개월밖에 걸리지 않아요!\n'
          '너무 짧으면 약간 늘려 잡는 걸 추천드려요 😊\n\n'
          '• 3개월 목표: 약 ${fmt(amt3m)}원\n'
          '• 6개월 목표: 약 ${fmt(amt6m)}원\n'
          '참고만 해주세요!';
    } else if (months >= 6.0) {
      // 6개월 이상 → 조금 줄이는/쪼개는 걸 추천
      _summaryRecommendation =
      '현재 계획대로라면 목표까지 약 ${months.toStringAsFixed(1)}개월이 걸려요.\n'
          '조금 길 수 있어서 목표를 나눠보는 걸 추천드려요 😊\n\n'
          '• 3개월 목표: 약 ${fmt(amt3m)}원\n'
          '• 6개월 목표: 약 ${fmt(amt6m)}원\n'
          '참고만 해주세요!';
    } else {
      // 그 외 → 좋은 플랜
      _summaryRecommendation =
      '좋은 플랜이네요! 🎉\n'
          '현재 계획대로라면 목표까지 약 ${months.toStringAsFixed(1)}개월입니다.\n'
          '충분히 현실적인 계획이에요 👍';
    }
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
    _totalPlanVM.updateMeta(
      planName: planName,
      targetAmount: targetAmount,
      currentAsset: currentAsset,
      autoService: autoService,
    );

    if (fixedIncomeSum != null) {
      _totalPlanVM.updateMetrics(monthlyIncome: fixedIncomeSum);
      _hasIncomeInput = true;
    }
    if (fixedConsumptionSum != null) {
      _totalPlanVM.updateMetrics(monthlyConsume: fixedConsumptionSum);
      _hasFixedConsumeInput = true;
    }
    if (dailyConsumptionSum != null) {
      _totalPlanVM.updateMetrics(dailyConsume: dailyConsumptionSum);
      _hasDailyInput = true;
    }

    _totalPlan = _totalPlanVM.plan;
    _refData.planId = _totalPlan.planId;
    _calculationVM.updatePlan(_totalPlan);

    if (_hasRequiredInputs()) {
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
    final endDate = modEndDate ?? (_totalPlan.modEndDate ?? _totalPlan.endDate ?? now);
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
      unawaited(_refDataRepo.saveMonthlyIncome(newIncome));
      if (previousId == null) {
        debugPrint('[updateRefData] monthlyIncome previousId missing');
      }
      debugPrint(
        '[updateRefData] new monthlyIncome ${newIncome.id} from $applyMonth to $modEndMonth',
      );
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

    if (fixedConsumptions != null && fixedConsumptions.isNotEmpty) {
      final previousId = _refData.primaryMonthlyConsumeId;
      final newConsume = _refDataVM.appendMonthlyConsume(
        applyDate: apply,
        modEndDate: endDate,
        entries: fixedConsumptions,
      );
      unawaited(_refDataRepo.saveMonthlyConsume(newConsume));
      if (previousId == null) {
        debugPrint('[updateRefData] monthlyConsume previousId missing');
      }
      debugPrint(
        '[updateRefData] new monthlyConsume ${newConsume.id} from $applyMonth to $modEndMonth',
      );
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

    if (dailyConsumptions != null && dailyConsumptions.isNotEmpty) {
      final previousId = _refData.primaryDailyConsumeId;
      final newDaily = _refDataVM.appendDailyConsume(
        applyDate: apply,
        modEndDate: endDate,
        entries: dailyConsumptions,
      );
      unawaited(_refDataRepo.saveDailyConsume(newDaily));
      if (previousId == null) {
        debugPrint('[updateRefData] dailyConsume previousId missing');
      }
      debugPrint(
        '[updateRefData] new dailyConsume ${newDaily.id} from $apply to $endDate',
      );
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

    updatePlanInfo(
      fixedIncomeSum:
          fixedIncomes != null ? refData.primaryMonthlyIncomeSum : null,
      fixedConsumptionSum:
          fixedConsumptions != null ? refData.primaryMonthlyConsumeSum : null,
      dailyConsumptionSum:
          dailyConsumptions != null ? refData.primaryDailyConsumeSum : null,
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

  void applyPlanEditResult(PlanEditResult result) { // 만든 결과를 앱의 메인 상태에 반영
    _totalPlan = result.updatedPlan;
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _refData = result.updatedRefData;
    _refData.planId = _totalPlan.planId;
    _refDataVM = RefDataViewModel(_refData);
    debugPrint('[applyPlanEditResult] updated totalPlan planId=${_totalPlan.planId}');
    if (_totalPlan.planId.isNotEmpty && !_hasSavedPlan) {
      debugPrint('[applyPlanEditResult] detected existing plan, setting _hasSavedPlan true');
      _setHasSavedPlan(true);
    }
    if (_hasSavedPlan) {
      _pendingMonthlyCommands = List<UpdateMonthlyCommand>.from(
        result.monthlyCommands.where((cmd) => cmd.entries.isNotEmpty),
      );
      _pendingDailyCommands = List<UpdateDailyCommand>.from(
        result.dailyCommands.where((cmd) => cmd.entries.isNotEmpty),
      );
      debugPrint('[applyPlanEditResult] commands captured (hasSavedPlan=true)');
    } else {
      debugPrint('[applyPlanEditResult] skipping commands (_hasSavedPlan=false)');
      _pendingMonthlyCommands.clear();
      _pendingDailyCommands.clear();
    }
    _calculationVM.updatePlan(_totalPlan);
    calculate();
    notifyListeners();
    print('--- Plan Tree After Edit ---\n${debugPlanTree()}');
  }

  /// Returns a human readable tree view of the current plan/mini/sub linkage.
  String debugPlanTree() {
    return PlanDebugPrinter.describe(plan: _totalPlan, refData: _refData);
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
          print(
            '저축 불가',
          );
        }
      }
    }
  }

  // --------------------------------------
  // 사용자 응답 처리
  // --------------------------------------
  void handleUserResponse(String response) async {
    final userMsg = response.trim();

    switch (_currentStep) {
      case ChatStep.onboarding1:
        if (response == '소통에 대해 더 알아볼래요') {
          _buttonClicked = true;
          notifyListeners();
          addMessage(response, MessageType.user);
          _currentStep = ChatStep.onboarding2;
          notifyListeners();
          await addBotMessageWithTyping(
            '소통은 $_userName님의 재정 상황을 바탕으로,\n'
                '목표 달성까지 걸리는 시간을 계산해드려요.\n\n'
                '계획만 세우는 게 아니라, 목표 달성까지 함께 가는 재정 파트너예요. 💙',
            delay: 500,
          );

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
          await addBotMessageWithTyping(
            '그럼 이제 $_userName님만의 목표를 향한 플랜을\n'
                '저와 함께 하나씩 만들어볼까요? 🚀\n\n'
                '현재 재정 상황과 목표만 알려주시면,\n'
                '가장 현실적인 계획을 제안해드릴게요! 🤝',
            delay: 500,
          );
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
          await addBotMessageWithTyping(
            '$_userName님은 어떤 목표로 돈을 모으고 싶으세요? 💭\n\n플랜에 이름을 붙여주세요.\n예: 세계여행 프로젝트 / 학자금 모으기',
            delay: 500,
          );
          _buttonClicked = false;
          notifyListeners();
        }
        break;

      case ChatStep.planName:
        if (response.isNotEmpty && response.length >= 2) {
          updatePlanInfo(planName: response);
          notifyListeners();

          addMessage('제 플랜 이름은 "$response"이에요!', MessageType.user);
          await addBotMessageWithTyping(
            '좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n원하시는 금액을 입력해주세요!',
          );
          _currentStep = ChatStep.targetAmount;
          notifyListeners();
        } else {
          await addBotMessageWithTyping('플랜 이름을 2글자 이상 입력해주세요.');
        }
        break;

      case ChatStep.targetAmount:
        {
          final amountStr = response.replaceAll(',', '').trim();
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) {
            addMessage('목표 금액은 ${SavingPlanCalculator.formatAmount(amount)}원이에요!', MessageType.user);
            updatePlanInfo(targetAmount: amount);
            notifyListeners();

            await addBotMessageWithTyping(
              '보유하고 계신 자산이 있으신가요? 😊\n\n'
                  '💡 소통 tip 💡\n보유 자산을 입력하시면 목표 금액에서 자동 차감돼요!\n'
                  '따라서 플랜에 보유 자산을 반영하고 싶지 않다면 ‘없어요’ 버튼을 눌러주세요.',
              delay: 500,
            );
            _currentStep = ChatStep.currentAssetAsk;
            notifyListeners();
          } else {
            await addBotMessageWithTyping('올바른 목표 금액을 입력해주세요. (예: 1000000)');
          }
          break;
        }

      case ChatStep.currentAssetAsk:
        {
          final lower = response.trim().toLowerCase();
          if (lower == '없어요' || lower == '없음' || lower == '없다' || lower == 'no') {
            addMessage('보유 자산 없이 진행할게요!', MessageType.user);
            updatePlanInfo(currentAsset: 0);
            notifyListeners();

            await addBotMessageWithTyping(
              '좋아요! 이제 회원님의 월 수입을 입력해볼게요. 💼\n\n'
                  '💡 소통 tip 💡\n월 수입은 한 달 동안 고정적으로 들어오는 돈이에요.\n'
                  '예: 급여, 용돈, 사업 수입, 이자·배당금 등\n\n'
                  '여러 개의 수입이 있다면 항목별로 나눠서 입력해주시면 더 정확해요!',
              delay: 500,
            );

            _currentStep = ChatStep.monthlyIncome;
            notifyListeners();
          } else if (lower == '있어요' || lower == '있음' || lower == '있다' || lower == 'yes') {
            addMessage('보유 자산이 있어요!', MessageType.user);
            notifyListeners();

            await addBotMessageWithTyping(
              '보유하고 계신 자산 금액을 입력해주세요.\n\n'
              '빚(부채)은 보유 자산 입력 시 ‘-’를 붙여서 기입해주세요!',
            );
            _currentStep = ChatStep.currentAsset;
            notifyListeners();
          } else {
            await addBotMessageWithTyping('“있어요” 또는 “없어요”로 답해주세요 🙂');
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

            await addBotMessageWithTyping(
              '좋아요! 이제 회원님의 월 수입을 입력해볼게요. 💼\n\n'
                  '💡 소통 tip 💡\n월 수입은 한 달 동안 고정적으로 들어오는 돈이에요.\n'
                  '예: 급여, 용돈, 사업 수입, 이자·배당금 등\n\n'
                  '여러 개의 수입이 있다면 항목별로 나눠서 입력해주시면 더 정확해요!',
              delay: 500,
            );

            _currentStep = ChatStep.monthlyIncome;
            notifyListeners();
          } else {
            await addBotMessageWithTyping(
              '숫자로 입력해 주세요. (예: 5000000 / -3000000)\n또는 "없어요"라고 입력하셔도 됩니다.',
            );
          }
          break;
        }

      case ChatStep.summaryIntro:
        if (response == '좋아요! 요약해주세요!') {
          addMessage(response, MessageType.user);
          _isTyping = true;
          notifyListeners();

          Future.delayed(const Duration(seconds: 3), () {
            _isTyping = false;
            addMessage('', MessageType.summary);
            nextStep();
          });
        } else {
          await addBotMessageWithTyping('"좋아요! 요약해주세요!" 버튼을 눌러주세요.');
        }
        break;

      case ChatStep.summary:
        if (response == '다음 단계로') {
          addMessage(response, MessageType.user);
          await addBotMessageWithTyping(
            '📌소통 자동등록 서비스란?\n\n소비 입력을 깜빡한 날에도,\n오늘 기록한 일일소비로 자동 등록해드려요.\n물론, 언제든 수정할 수 있어요.\n\n👉 소통 자동등록 서비스를 활성화할까요?',
          );
          await nextStep();
        } else {
          await addBotMessageWithTyping('"다음 단계로" 버튼을 눌러주세요.');
        }
        break;

      case ChatStep.autoService:
        if (response == '네, 좋아요!') {
          updatePlanInfo(autoService: true);
          addMessage(response, MessageType.user);
          await addBotMessageWithTyping('완료되었습니다! 이제 본격적으로 저와 소통해볼까요?');
          _currentStep = ChatStep.complete;
          notifyListeners();
        } else {
          await addBotMessageWithTyping('"네, 좋아요!" 버튼을 눌러주세요.');
        }
        break;

      default:
        break;
    }
  }

  // --------------------------------------
  // 계산 (요약 추천 멘트도 함께 갱신)
  // --------------------------------------
  SavingCalculationResult? calculate() {
    _calculationVM.updatePlan(_totalPlan);
    _calculationResult = _calculationVM.calculate(); // 위임
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
  Future<void> initializeChat() async {
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
    _calculationResult = null;
    notifyListeners();

    await addBotMessageWithTyping(
      '안녕하세요, $_userName님! 😊\n'
          '소통에 오신 걸 환영해요.\n\n'
          '매일 아무 생각 없이 쓰는 돈 있으시죠?\n'
          '소통은 그런 ‘무의식적인 소비 패턴’을 발견하고, '
          '절약으로 전환할 수 있게 함께 도와드려요!\n\n'
          '소통에 대해 더 알아보시겠어요?',
      delay: 500,
    );

  }

  // --------------------------------------
  // 저장
  // --------------------------------------
  Future<bool> savePlan() async { //
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
      await _preparePlanStructureForSave();
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
      print('--- Plan Tree After Save ---\n${debugPlanTree()}');
      _planSavedBus?.notify();
      debugPrint('[savePlan] success: _hasSavedPlan $_hasSavedPlan -> true');
      _setHasSavedPlan(true);
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

  Future<void> _preparePlanStructureForSave() async {
    debugPrint('[preparePlan] start');
    final calc = calculate();
    final now = DateTime.now();
    final rawStart = _totalPlan.startDate ?? DateTime(now.year, now.month, now.day);
    final start = DateTime(rawStart.year, rawStart.month, rawStart.day);
    if (_totalPlan.startDate == null ||
        !_isSameDay(_totalPlan.startDate!, start)) {
      debugPrint(
        '[preparePlan] normalizing startDate '
        '${_totalPlan.startDate?.toIso8601String() ?? 'null'} -> ${start.toIso8601String()}',
      );
      _totalPlan = _totalPlan.copyWith(startDate: start);
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _calculationVM.updatePlan(_totalPlan);
    }
    final computedGoal = calc?.goalDateTime ?? start.add(const Duration(days: 120));
    final exactPlanEnd = computedGoal;
    final previousModEnd = _totalPlan.modEndDate;
    _totalPlan = _totalPlan.copyWith(modEndDate: computedGoal);
    final planEnd = _totalPlan.modEndDate ?? computedGoal;
    final persistedEnd =
        _hasSavedPlan && _totalPlan.endDate != null ? _totalPlan.endDate! : planEnd;
    debugPrint(
      '[preparePlan] startDate=$start goal=$computedGoal modEnd=${_totalPlan.modEndDate}',
    );
    if (_totalPlan.modEndDate != null && computedGoal != _totalPlan.modEndDate) {
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
    final shouldRebuildSkeleton = !_hasSavedPlan || _totalPlan.subPlans.isEmpty;
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
    final hasPending = _pendingMonthlyCommands.isNotEmpty ||
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
      _totalPlan = _applyExactPlanEnd(_totalPlan, exactPlanEnd);
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

    if (monthlyCommands.isEmpty && dailyCommands.isEmpty) {
      _totalPlan = _totalPlan.copyWith(
        startDate: start,
        endDate: persistedEnd,
        modEndDate: planEnd,
      );
      _totalPlan = _applyExactPlanEnd(_totalPlan, exactPlanEnd);
      _totalPlanVM = TotalPlanViewModel(_totalPlan);
      _calculationVM.updatePlan(_totalPlan);
      debugPrint('[preparePlan] commands filtered out, nothing to mutate');
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

    _totalPlan = _applyExactPlanEnd(result.totalPlan, exactPlanEnd);
    debugPrint('[applyPlanEditResult] updated totalPlan planId=${_totalPlan.planId}');
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _calculationVM.updatePlan(_totalPlan);
    _refData = RefData(
      planId: _refData.planId,
      monthlyIncomes: result.monthlyIncomes,
      monthlyConsumes: result.monthlyConsumes,
      dailyConsumes: result.dailyConsumes,
    );
    _refDataVM = RefDataViewModel(_refData);
    _pendingMonthlyCommands.clear();
    _pendingDailyCommands.clear();
    _pendingAutoMonthlyInputs.clear();
    _pendingAutoDailyInputs.clear();
  }


  Future<void> _ensureRefDataCoverage(DateTime start, DateTime end) async { // 구간 확인 진행

    final tasks = <Future<void>>[];
    final months = _monthSequence(start, end);

    final incomeId = _refData.primaryMonthlyIncomeId;
    if (incomeId != null) {
      final income = _refData.monthlyIncomeMap[incomeId];
      if (income != null) { // 구간 확인
        final missing = months.where((m) => !_containsMonth(income.yearMonthList, m)).toList();
        if (missing.isNotEmpty) { // 빠진 구간 없다면
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
        final missing = months.where((m) => !_containsMonth(consume.yearMonthList, m)).toList();
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
        final newStart =
            daily.startDate.isAfter(normalizedStart) ? normalizedStart : daily.startDate;
        final newEnd =
            daily.endDate.isBefore(normalizedEnd) ? normalizedEnd : daily.endDate;
        if (newStart != daily.startDate || newEnd != daily.endDate) {
          final updated = daily.copyWith(
            startDate: newStart,
            endDate: newEnd,
          );
          _refData.dailyConsumeMap[dailyId] = updated;
          tasks.add(_refDataRepo.saveDailyConsume(updated));
        }
      }
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
      final normalizedEnd =
          isFinalMonth ? DateTime(end.year, end.month, end.day) : monthEnd;
      final actualEnd = normalizedEnd;
      final fractionalSeconds = isFinalMonth
          ? min(86399, max(0, end.difference(normalizedEnd).inSeconds))
          : 0;
      final key = _formatYearMonth(monthStart);
      final miniId = '${key}_mini_seed';
      final mini = MiniPlan(
        docId: miniId,
        yearMonth: monthStart,
        startDate: actualStart,
        endDate: actualEnd,
        monthlyIncomeId: _refData.primaryMonthlyIncomeId ?? _fallbackDocId('income'),
        monthlyConsumeId: _refData.primaryMonthlyConsumeId ?? _fallbackDocId('consume'),
        dailyConsumeId: _refData.primaryDailyConsumeId ?? _fallbackDocId('daily'),
        sumMonthlyIncome: metrics.sumMonthlyIncome,
        sumMonthlyConsume: metrics.sumMonthlyConsume,
        sumDailyConsume: metrics.sumDailyConsume,
      );
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
    return source.any(
      (m) => m.year == target.year && m.month == target.month,
    );
  }

  String _formatYearMonth(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}';
  }

  String _fallbackDocId(String kind) => 'bootstrap_$kind';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

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

  void _setHasSavedPlan(bool value) {
    if (_hasSavedPlan == value) return;
    debugPrint('[ChatPlanViewModel] _hasSavedPlan: $_hasSavedPlan -> $value');
    _hasSavedPlan = value;
  }

  TotalPlan _applyExactPlanEnd(TotalPlan plan, DateTime exactEnd) {
    final normalized = DateTime(exactEnd.year, exactEnd.month, exactEnd.day);
    final fractionalSeconds =
        min(86399, max(0, exactEnd.difference(normalized).inSeconds));
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
    return plan.copyWith(
      subPlans: updatedSubPlans,
      modEndDate: exactEnd,
    );
  }

  void prepareSkeletonForSummary() {
    final start = _totalPlan.startDate ?? DateTime.now();
    final modEnd = _totalPlan.modEndDate ?? DateTime.now();
    final skeleton = _buildInitialSubPlanSkeleton(start, modEnd);
    _totalPlan = _totalPlan.copyWith(subPlans: skeleton);
    _totalPlanVM = TotalPlanViewModel(_totalPlan);
    _calculationVM.updatePlan(_totalPlan);
    calculate();
  }
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

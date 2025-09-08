import 'package:flutter/material.dart';

import '../../model/chat_message.dart';
import '../../model/entry.dart';
import '../../model/plan_info.dart';
import '../../model/ref_data.dart';
import '../../model/saving_calculation_result.dart';
import '../../repository/auth_repository.dart';
import '../../repository/plan_repository.dart';
import '../services/plan_info_viewmodel.dart';
import '../services/ref_data_viewmodel.dart';
import '../services/saving_calculator.dart';
import 'enums/chat_step.dart';

// 기본 회원가입 창의 viewmodel

class ChatPlanViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final PlanRepository _planRepo;
  ChatPlanViewModel(this._authRepo, this._planRepo);

  String _userName = '회원';
  String get userName => _userName;

  bool _isSaving = false;
  bool get isSaving => _isSaving;
  // 플랜 정보
  PlanInfo _planInfo = PlanInfo();
  PlanInfo get planInfo => _planInfo;

  // 참조 데이터 (월 수입, 고정 소비, 하루 소비 한도)
  RefData _refData = RefData();
  RefData get refData => _refData;

  // 계산 결과
  SavingCalculationResult? _calculationResult;
  SavingCalculationResult? get calculationResult => _calculationResult;

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

  late final RefDataViewModel _refDataVM = RefDataViewModel(
    _refData,
  ); // refData 관리하는 viewmodel
  late final PlanInfoViewModel _planInfoVM = PlanInfoViewModel(
    _planInfo,
  ); // PlanInfo 관리하는 viewmodel
  late final SavingPlanCalculator _calculationVM = SavingPlanCalculator(
    planInfo: _planInfo,
  ); // saving_cal result 관리 하는 viewmodel

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

  void updatePlanInfo({
    String? planName,
    double? targetAmount,
    double? currentAsset,
    bool? autoService,
    double? fixedIncomeSum,
    double? fixedConsumptionSum,
    double? dailyConsumptionSum,
    double? variableConsumptionSum,
  }) {
    print('=== updatePlanInfo 호출 ===');
    print('fixedIncomeSum: $fixedIncomeSum');
    print('fixedConsumptionSum: $fixedConsumptionSum');
    print('dailyConsumptionSum: $dailyConsumptionSum');
    print('targetAmount: $targetAmount');

    _planInfoVM.updatePlanInfo(
      // 위임 호출
      planName: planName,
      targetAmount: targetAmount,
      currentAsset: currentAsset,
      autoService: autoService,
    );
    if (fixedIncomeSum != null) _planInfo.fixedIncomeSum = fixedIncomeSum;
    if (fixedConsumptionSum != null)
      _planInfo.fixedConsumptionSum = fixedConsumptionSum;
    if (dailyConsumptionSum != null)
      _planInfo.dailyConsumptionSum = dailyConsumptionSum;
    if (variableConsumptionSum != null)
      _planInfo.variableConsumptionSum = variableConsumptionSum;
    if (autoService != null) _planInfo.autoService = autoService;

    print('업데이트 후 planInfo:');
    print('fixedIncomeSum: ${_planInfo.fixedIncomeSum}');
    print('fixedConsumptionSum: ${_planInfo.fixedConsumptionSum}');
    print('dailyConsumptionSum: ${_planInfo.dailyConsumptionSum}');
    print('targetAmount: ${_planInfo.targetAmount}');

    if (_planInfo.fixedIncomeSum != null &&
        _planInfo.fixedConsumptionSum != null &&
        _planInfo.targetAmount != null &&
        _planInfo.dailyConsumptionSum != null) {
      print('모든 필요 데이터가 있음. calculate() 호출');
      calculate();
    } else {
      print('필요 데이터 부족. calculate() 호출하지 않음');
      print('fixedIncomeSum null? ${_planInfo.fixedIncomeSum == null}');
      print(
        'fixedConsumptionSum null? ${_planInfo.fixedConsumptionSum == null}',
      );
      print('targetAmount null? ${_planInfo.targetAmount == null}');
      print(
        'dailyConsumptionSum null? ${_planInfo.dailyConsumptionSum == null}',
      );
    } // planInfo가 바뀔 때마다 자동 계산

    notifyListeners();
  }

  void updateRefData({
    List<Entry>? fixedIncomes,
    List<Entry>? fixedConsumptions,
    List<Entry>? dailyConsumptions,
    List<Entry>? variableConsumptions,
    List<Entry>? installmentIncomes,
    List<Entry>? installmentConsumptions,
    List<Entry>? additionalIncomeList,
    List<Entry>? additionalConsumptionList,
    List<Entry>? variableConsumptionList,
  }) {
    print('=== updateRefData 호출 ===');
    print('fixedIncomes: $fixedIncomes');
    print('fixedConsumptions: $fixedConsumptions');
    print('dailyConsumptions: $dailyConsumptions');

    _refDataVM.updateRefData(
      fixedIncomes: fixedIncomes,
      fixedConsumptions: fixedConsumptions,
      dailyConsumptions: dailyConsumptions,
      variableConsumptions: variableConsumptions,
      installmentIncomes: installmentIncomes,
      installmentConsumptions: installmentConsumptions,
      additionalIncomeList: additionalIncomeList,
      additionalConsumptionList: additionalConsumptionList,
      variableConsumptionList: variableConsumptionList,
    );

    // sum 계산 (refDataViewModel의 sum 메서드 사용)
    double? fixedIncomeSum = fixedIncomes != null
        ? _refDataVM.sum(fixedIncomes)
        : null;
    double? fixedConsumptionSum = fixedConsumptions != null
        ? _refDataVM.sum(fixedConsumptions)
        : null;
    double? dailyConsumptionSum = dailyConsumptions != null
        ? _refDataVM.sum(dailyConsumptions)
        : null;
    double? variableConsumptionSum = variableConsumptions != null
        ? _refDataVM.sum(variableConsumptions)
        : null;

    print('계산된 합계:');
    print('fixedIncomeSum: $fixedIncomeSum');
    print('fixedConsumptionSum: $fixedConsumptionSum');
    print('dailyConsumptionSum: $dailyConsumptionSum');
    print('variableConsumptionSum: $variableConsumptionSum');

    // 하나라도 값이 있으면 updatePlanInfo 호출
    if (fixedIncomeSum != null ||
        fixedConsumptionSum != null ||
        dailyConsumptionSum != null ||
        variableConsumptionSum != null) {
      print('updatePlanInfo 호출');
      updatePlanInfo(
        fixedIncomeSum: fixedIncomeSum,
        fixedConsumptionSum: fixedConsumptionSum,
        dailyConsumptionSum: dailyConsumptionSum,
        variableConsumptionSum: variableConsumptionSum,
      );
    } else {
      print('합계가 모두 null이므로 updatePlanInfo 호출하지 않음');
    }

    notifyListeners();
  }

  Future<void> nextStep() async {
    final steps = ChatStep.values;
    final currentIndex = steps.indexOf(_currentStep);

    print('=== nextStep() 호출됨 ===');
    print('현재 단계: $_currentStep');
    print('현재 인덱스: $currentIndex');
    print('다음 인덱스: ${currentIndex + 1}');

    if (currentIndex < steps.length - 1) {
      _currentStep = steps[currentIndex + 1];
      print('새로운 단계: $_currentStep');
      notifyListeners();

      // summary 단계로 이동했을 때 자동으로 summary 메시지 표시
      if (_currentStep == ChatStep.summary) {
        print('=== Summary 단계 진입 ===');
        print('planInfo: $_planInfo');
        print('refData: $_refData');

        final calc = calculate();
        print('계산 결과: $calc');
        print('_calculationResult: $_calculationResult');

        if (calc != null && calc.dailyNetSaving > 0) {
          print('정상적인 저축 계획');
          // 플랜 완성 메시지 제거
        } else {
          print('저축 불가능한 상황 또는 계산 실패');
          await addBotMessageWithTyping(
            '죄송합니다. 입력하신 정보로는 저축이 어려운 상황입니다.\n플랜을 다시 검토해보시겠어요?',
          );
        }
      }
    } else {
      print('마지막 단계에 도달함');
    }
  }

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
            '🔍 소통은 $_userName님의 재정 상황을 바탕으로,\n하루에 쓸 수 있는 금액과 목표 달성까지 걸리는 시간을 계산해드려요.\n\n계획만 세우는 게 아니라, 목표 달성까지 함께 가는 재정 파트너예요. 💙',
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
            '그럼 이제 $_userName님만의 목표를 향한 플랜을 \n저와 함께 하나씩 만들어볼까요? 🚀\n\n현재 상황과 목표만 알려주시면,\n가장 현실적인 계획을 제안해드릴게요! 🤝',
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
            '$_userName님은 어떤 목표로 돈을 모으고 싶으세요? 💭\n\n플랜에 이름을 붙여주세요.\n예: 🏝 세계여행 프로젝트 / 🎓 학자금 모으기',
            delay: 500,
          );
          _buttonClicked = false;
          notifyListeners();
        }
        break;

      case ChatStep.planName:
        if (response.isNotEmpty && response.length >= 2) {
          updatePlanInfo(planName: response);
          testPrint();
          notifyListeners();

          addMessage('제 플랜 이름은 "$response"이에요!', MessageType.user);

          await addBotMessageWithTyping(
            '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n원하시는 금액을 입력해주세요!''',
          );
          _currentStep = ChatStep.targetAmount; // nextStep() 대신 직접 설정
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
            final formatted = SavingPlanCalculator.formatAmount(amount);
            addMessage('목표 금액은 ${formatted}원이에요!', MessageType.user);

            updatePlanInfo(targetAmount: amount);
            testPrint();
            notifyListeners();

            await addBotMessageWithTyping('보유하고 계신 자산이 있으신가요? 😊');
            _currentStep = ChatStep.currentAssetAsk; // ← 여기!
            notifyListeners();
          } else {
            await addBotMessageWithTyping('올바른 목표 금액을 입력해주세요. (예: 1000000)');
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
            testPrint();
            notifyListeners();

            await addBotMessageWithTyping('좋습니다! 이제 월 수입을 알려주세요. 💰');
            _currentStep = ChatStep.monthlyIncome;
            notifyListeners();
          } else if (lower == '있어요' ||
              lower == '있음' ||
              lower == '있다' ||
              lower == 'yes') {
            addMessage('보유 자산이 있어요!', MessageType.user);
            notifyListeners();

            await addBotMessageWithTyping(
              '보유하고 계신 자산 금액을 입력해주세요.\n'
              '빚이 있다면 마이너스(-) 를 포함해 입력하셔도 됩니다. (예: -5000000)',
            );
            _currentStep = ChatStep.currentAsset; // 금액 입력 단계로
            notifyListeners();
          } else {
            await addBotMessageWithTyping('“있어요” 또는 “없어요”로 답해주세요 🙂');
          }
          break;
        }

      case ChatStep.currentAsset:
        {
          final lower = userMsg.toLowerCase();
          final isNone = (lower == '없어요' || lower == '없음' || lower == '없다');

          if (isNone) {
            addMessage('보유 자산 없이 진행할게요!', MessageType.user);
            updatePlanInfo(currentAsset: 0);
            testPrint();
            notifyListeners();

            await addBotMessageWithTyping('좋습니다! 이제 월 수입을 알려주세요. 💰');
            _currentStep = ChatStep.monthlyIncome;
            notifyListeners();
            break;
          }

          final amountStr = response.replaceAll(',', '').trim();
          final amount = double.tryParse(amountStr);
          if (amount != null) {
            final formatted =
                SavingPlanCalculator.formatAmount(amount.abs()) *
                (amount.isNegative ? -1 : 1);
            addMessage(
              '보유 자산은 ${amount.isNegative ? "-" : ""}${SavingPlanCalculator.formatAmount(amount.abs())}원이에요!',
              MessageType.user,
            );

            updatePlanInfo(currentAsset: amount);
            testPrint();
            notifyListeners();

            await addBotMessageWithTyping('확인했어요! 이제 월 수입을 알려주세요. 💰');
            _currentStep = ChatStep.monthlyIncome;
            notifyListeners();
          } else {
            await addBotMessageWithTyping(
              '숫자로 입력해 주세요. (예: 5000000 / -3000000)\n'
              '또는 "없어요"라고 입력하셔도 됩니다.',
            );
          }
          break;
        }

      case ChatStep.monthlyIncome:
        await addBotMessageWithTyping('"월 수입 입력하러가기" 버튼을 눌러주세요.');
        print("monthly Income");
        testPrint();
        notifyListeners(); // 즉시 UI 업데이트
        break;

      case ChatStep.monthlyFixedCost:
        // 고정 소비는 모달을 통해 입력받으므로 여기서는 처리하지 않음
        await addBotMessageWithTyping('"고정 소비 입력하러가기" 버튼을 눌러주세요.');
        print("monthly FixedCost");
        testPrint();
        notifyListeners(); // 즉시 UI 업데이트
        break;

      case ChatStep.dailySpending:
        // 하루 소비는 모달을 통해 입력받으므로 여기서는 처리하지 않음
        await addBotMessageWithTyping('"하루 소비 한도 금액 입력하러가기" 버튼을 눌러주세요.');
        print("monthly dailySpending");
        testPrint();
        notifyListeners(); // 즉시 UI 업데이트
        break;

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
        print(planInfo);
        print(refData);
        print(userName);
        print(calculationResult);
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
          testPrint();
          notifyListeners();
          addMessage(response, MessageType.user);
          await addBotMessageWithTyping('완료되었습니다! 이제 플랜을 수정하거나 확인할 수 있습니다.');
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

  SavingCalculationResult? calculate() {
    print('=== calculate() 호출 ===');
    print('계산 전 _calculationResult: $_calculationResult');
    _calculationResult = _calculationVM.calculate(); // 위임 호출
    print('계산 후 _calculationResult: $_calculationResult');
    if (_calculationResult != null) {
      print('dailyNetSaving: ${_calculationResult!.dailyNetSaving}');
    }
    // notifyListeners(); // 중복이므로 제거
    return _calculationResult;
  }

  Future<void> initializeChat() async {
    // 1) 이름 로드
    try {
      _userName = await _authRepo.getUserName();
    } catch (_) {
      _userName = '회원';
    }

    // 2) 기존 초기화 + 인삿말
    _messages.clear();
    _currentStep = ChatStep.onboarding1;
    notifyListeners();

    await addBotMessageWithTyping(
      '안녕하세요, $_userName님! 😊\n'
      '소통에 오신 걸 환영해요. 🎉\n\n'
      '소통은 단순한 가계부가 아니라\n 당신만의 재정 파트너입니다.\n\n'
      '하루 소비 계획부터 기록·피드백까지, \n목표 달성을 함께 해드려요.',
      delay: 500,
    );
  }

  Future<bool> savePlan() async {
    if (_isSaving) return false;
    _isSaving = true;
    notifyListeners();
    try {
      // _planInfo 가 이미 대화 과정에서 채워졌다고 가정
      await _planRepo.saveCurrentUserPlan(_planInfo);
      return true;
    } catch (e) {
      // 로깅/에러 메시지 필요하면 여기서 처리
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> waitForTypingToFinish() async {
    // _isTyping이 false가 될 때까지 아주 잠깐씩 대기
    while (_isTyping) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void testPrint() {
    print('planInfo: $planInfo');
    print('refData: $refData');
    print('calculationResult: $calculationResult');
  }
}

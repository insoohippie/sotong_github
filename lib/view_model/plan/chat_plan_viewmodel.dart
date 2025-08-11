import 'package:flutter/material.dart';

import '../../enums/chat_step.dart';
import '../../model/chat_message.dart';
import '../../model/entry.dart';
import '../../model/plan_info.dart';
import '../../model/ref_data.dart';
import '../../model/saving_calculation_result.dart';
import '../../services/plan_info_viewmodel.dart';
import '../../services/ref_data_viewmodel.dart';
import '../../services/saving_calculator.dart';

// 기본 회원가입 창의 viewmodel

class ChatPlanViewModel extends ChangeNotifier {
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

  // 목적 옵션들
  List<String> get purposeOptions => [
    '여행자금',
    '자취 준비',
    '부모님 선물',
    '결혼 준비',
    '학자금',
    '이직준비',
    '긴급자금',
    '기타',
  ];

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
    String? purpose,
    double? targetAmount,
    double? currentAsset,
    bool? autoService,
    double? fixedIncomeSum,
    double? fixedConsumptionSum,
    double? dailyConsumptionSum,
    double? variableConsumptionSum,
  }) {
    _planInfoVM.updatePlanInfo(
      // 위임 호출
      planName: planName,
      purpose: purpose,
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
    if (_planInfo.fixedIncomeSum != null &&
        _planInfo.fixedConsumptionSum != null &&
        _planInfo.targetAmount != null &&
        _planInfo.dailyConsumptionSum != null) {
      calculate();
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

    // 하나라도 값이 있으면 updatePlanInfo 호출
    if (fixedIncomeSum != null ||
        fixedConsumptionSum != null ||
        dailyConsumptionSum != null ||
        variableConsumptionSum != null) {
      updatePlanInfo(
        fixedIncomeSum: fixedIncomeSum,
        fixedConsumptionSum: fixedConsumptionSum,
        dailyConsumptionSum: dailyConsumptionSum,
        variableConsumptionSum: variableConsumptionSum,
      );
    }

    notifyListeners();
  }

  void nextStep() {
    final steps = ChatStep.values;
    final currentIndex = steps.indexOf(_currentStep);

    if (currentIndex < steps.length - 1) {
      _currentStep = steps[currentIndex + 1];
      notifyListeners();
    }
  }

  void handleUserResponse(String response) async {
    // 사용자 메시지 추가
    final userMsg = response.trim();
    if (userMsg.isNotEmpty) {
      addMessage(userMsg, MessageType.user);
    }

    switch (_currentStep) {
      case ChatStep.onboarding1:
        if (response == '소통에 대해 더 알아볼래요') {
          _buttonClicked = true; // 버튼 클릭 상태 설정
          notifyListeners();
          _currentStep = ChatStep.onboarding2;
          notifyListeners(); // 즉시 UI 업데이트
          await addBotMessageWithTyping(
            '🔍 소통에서 제공하는 서비스, 궁금하셨죠?\n지금부터 간단히 소개해드릴게요 😊\n\n소통은 목표 중심의 재정 관리 앱입니다.\n예를 들어,\n✈️ 여행 자금\n🏡 전세/보증금\n🎓 자격증 준비 등\n\n이루고 싶은 목표를 설정하면,\n하루에 얼마를 쓰고, 얼마를 저축해야 하는지\n구체적인 가이드를 제공합니다.\n\n특히 소통은\n📌 [ㅇㅇ]님의 재정 상황과 목표에 맞춰 하루 소비 한도를 설정하고,\n그 안에서 지출을 관리할 수 있도록 도와드려요.\n\n이 소비 한도는 단순한 제한이 아니라,\n👉 목표에 도달하기 위한 가장 현실적인 실천 도구예요.\n\n소비를 조절하고 저축을 이어가는 여정 속에서,\n소통이 언제나 곁에서 함께할게요. 💙',
            delay: 500,
          );
          _buttonClicked = false; // 메시지 완료 후 버튼 상태 리셋
          notifyListeners();
        }
        break;
      case ChatStep.onboarding2:
        if (response == '너무 신기해요!') {
          _buttonClicked = true; // 버튼 클릭 상태 설정
          notifyListeners();
          _currentStep = ChatStep.onboarding3;
          notifyListeners(); // 즉시 UI 업데이트
          await addBotMessageWithTyping(
            '그럼 이제 [ㅇㅇ]님만의 목표를 향한 플랜을\n저와 함께 하나씩 정리해볼까요? 🚀\n\n현재 상황과 목표만 알려주시면,\n가장 현실적인 플랜을 함께 만들어드릴게요! 🤝\n\n걱정 마세요.\n아주 쉽고, 재미있는 여정이 될 거예요. 🚀',
            delay: 500,
          );
          _buttonClicked = false; // 메시지 완료 후 버튼 상태 리셋
          notifyListeners();
        }
        break;
      case ChatStep.onboarding3:
        if (response == '좋아요, 시작할게요!') {
          _buttonClicked = true; // 버튼 클릭 상태 설정
          notifyListeners();
          _currentStep = ChatStep.planName;
          notifyListeners(); // 즉시 UI 업데이트
          await addBotMessageWithTyping(
            '먼저 이 플랜에 이름을 붙여볼게요!\n예: 🏝여름휴가 프로젝트 / 🎓학자금 모으기 등',
            delay: 500,
          );
          _buttonClicked = false; // 메시지 완료 후 버튼 상태 리셋
          notifyListeners();
        }
        break;

      case ChatStep.greeting:
        if (response == '좋아요! 시작할게요') {
          await addBotMessageWithTyping(
            '먼저 이 플랜에 이름을 붙여볼게요!\n예: 🏝여름휴가 프로젝트 / 🎓학자금 모으기 등',
          );
          nextStep();
        } else {
          // 잘못된 입력 시 안내 메시지
          await addBotMessageWithTyping('"네, 좋아요!" 버튼을 눌러주세요.');
        }
        break;

      case ChatStep.planName:
        if (response.isNotEmpty && response.length >= 2) {
          updatePlanInfo(planName: response);
          testPrint();
          notifyListeners();
          await addBotMessageWithTyping(
            '이 플랜의 목적은 무엇인가요?\n아래 카드 중 하나를 선택해주세요.',
          );
          _currentStep = ChatStep.purpose; // nextStep() 대신 직접 설정
          notifyListeners();
        } else {
          await addBotMessageWithTyping('플랜 이름을 2글자 이상 입력해주세요.');
        }
        break;

      case ChatStep.purpose:
        // "기타"를 선택한 경우
        if (response == '기타') {
          await addBotMessageWithTyping('직접 목적을 입력해주세요!');
          _currentStep = ChatStep.purposeCustom;
          notifyListeners();
        }
        // purposeOptions에 있는 값만 허용 (기타 제외)
        else if (purposeOptions.contains(response)) {
          updatePlanInfo(purpose: response);
          testPrint();
          notifyListeners();
          await addBotMessageWithTyping('좋아요! 이번 플랜의 목표 금액은 얼마인가요?');
          _currentStep = ChatStep.targetAmount; // nextStep() 대신 직접 설정
          notifyListeners();
        } else {
          await addBotMessageWithTyping('아래 카드 중 하나를 선택해주세요.');
        }
        break;

      case ChatStep.purposeCustom:
        if (response.isNotEmpty && response.length >= 2) {
          updatePlanInfo(purpose: response);
          testPrint();
          notifyListeners();
          await addBotMessageWithTyping('좋아요! 이번 플랜의 목표 금액은 얼마인가요?');
          _currentStep = ChatStep.targetAmount; // nextStep() 대신 직접 설정
          notifyListeners();
        } else {
          await addBotMessageWithTyping('목적을 2글자 이상 입력해주세요.');
        }
        break;

      case ChatStep.targetAmount:
        final amountStr = response.replaceAll(',', '').trim();
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          updatePlanInfo(targetAmount: amount);
          testPrint();
          notifyListeners();
          await addBotMessageWithTyping(
            '현재 가지고 계신 자산이 있으신가요?\n(예: 통장 잔고 등)\n\n�� 소통 tip! 혹시 빚이 있으시다면 \'-\'를 붙이고 금액을 입력해주세요.',
          );
          _currentStep = ChatStep.currentAsset; // nextStep() 대신 직접 설정
          notifyListeners();
        } else {
          await addBotMessageWithTyping('올바른 목표 금액을 입력해주세요. (예: 1000000)');
        }
        break;

      case ChatStep.currentAsset:
        if (response == '있어요') {
          await addBotMessageWithTyping('지금 보유 중인 금액을 입력해주세요.');
          _currentStep = ChatStep.currentAssetConfirm;
          notifyListeners();
        } else if (response == '없어요') {
          updatePlanInfo(currentAsset: 0);
          testPrint();
          notifyListeners();
          await addBotMessageWithTyping(
            '월 수입을 입력해주세요!\n수입원이 여러 개라면 합산해주시고,\n불규칙하다면 최근 3개월 평균으로 입력해주세요.',
          );
          _currentStep = ChatStep.monthlyIncome;
          notifyListeners();
        } else {
          await addBotMessageWithTyping('채팅 입력이 아닌 "있어요" 혹은 "없어요" 버튼을 눌러주세요.');
        }
        break;

      case ChatStep.currentAssetConfirm:
        final assetStr = response.replaceAll(',', '').trim();
        final assetAmount = double.tryParse(assetStr);
        if (assetAmount != null) {
          updatePlanInfo(currentAsset: assetAmount);
          testPrint();
          notifyListeners();
          if (assetAmount < 0) {
            await addBotMessageWithTyping(
              '보유한 빚은 ${assetAmount.abs().toStringAsFixed(0)}원이에요!',
            );
          } else {
            await addBotMessageWithTyping(
              '현재 보유금액은 ${assetAmount.toStringAsFixed(0)}원이에요!',
            );
          }
          await addBotMessageWithTyping(
            '월 수입을 입력해주세요!\n수입원이 여러 개라면 합산해주시고,\n불규칙하다면 최근 3개월 평균으로 입력해주세요.',
          );
          _currentStep = ChatStep.monthlyIncome; // nextStep() 대신 직접 설정
          notifyListeners();
        } else {
          await addBotMessageWithTyping(
            '올바른 보유 금액을 입력해주세요. (예: 500000 또는 -300000)',
          );
        }
        break;

      case ChatStep.monthlyIncome:
        // 월 수입은 모달을 통해 입력받으므로 여기서는 처리하지 않음
        // 이 부분에서 플로우에 무슨 문제가 있는지 알아야 함
        // 그래야 왜 Infinity 에러가 발생하는지 유추할 수 있음
        await addBotMessageWithTyping('"월 수입 입력하러가기" 버튼을 눌러주세요.');
        print("monthly Income");
        testPrint();
        notifyListeners(); // 즉시 UI 업데이트
        break;

      case ChatStep.monthlyFixedCost:
        // 고정 소비는 모달을 통해 입력받으므로 여기서는 처리하지 않음
        await addBotMessageWithTyping('"고정 소비 입력하러가기" 버튼을 눌러주세요.');
        print("monthly FixedCost");
        testPrint(); // 이 부분 실행이 안되는듯?
        notifyListeners(); // 즉시 UI 업데이트
        break;

      case ChatStep.dailySpending:
        // 하루 소비는 모달을 통해 입력받으므로 여기서는 처리하지 않음
        await addBotMessageWithTyping('"하루 소비 한도 금액 입력하러가기" 버튼을 눌러주세요.');
        print("monthly dailySpending");
        testPrint();
        notifyListeners(); // 즉시 UI 업데이트
        break;

      case ChatStep.summary:
        // 일단 modelview에서는 calculate 이뤄지지 않음
        print(planInfo);
        print(refData);
        print(calculationResult);
        if (response == '다음 단계로') {
          await addBotMessageWithTyping('마지막으로, 소통 자동등록 서비스를 활성화해드릴까요?');
          nextStep();
        } else {
          await addBotMessageWithTyping('"다음 단계로" 버튼을 눌러주세요.');
        }
        break;

      case ChatStep.autoService:
        if (response == '네! 좋아요') {
          updatePlanInfo(autoService: true);
          testPrint();
          notifyListeners();
          await addBotMessageWithTyping('완료되었습니다! 이제 플랜을 수정하거나 확인할 수 있습니다.');
          _currentStep = ChatStep.complete;
          notifyListeners();
        } else {
          await addBotMessageWithTyping('"네! 좋아요" 버튼을 눌러주세요.');
        }
        break;

      default:
        break;
    }
  }

  SavingCalculationResult? calculate() {
    _calculationResult = _calculationVM.calculate(); // 위임 호출
    // notifyListeners(); // 중복이므로 제거
    return _calculationResult;
  }

  /*
  SavingCalculationResult? calculate() {
    // 필요한 값이 모두 유효할 때만 계산
    if (_planInfo.fixedIncomeSum > 0 &&
        _planInfo.fixedConsumptionSum > 0 &&
        _planInfo.targetAmount > 0 &&
        _planInfo.dailyConsumptionSum > 0) {
      final calculator = SavingPlanCalculator(planInfo: _planInfo);
      _calculationResult = calculator.calculate();
      notifyListeners(); // 결과가 갱신될 때 UI에 알림
      return _calculationResult;
    }
    return null;
  }
   */

  Future<void> initializeChat() async {
    _messages.clear();
    _currentStep = ChatStep.onboarding1;
    notifyListeners();
    await addBotMessageWithTyping(
      '안녕하세요, [ㅇㅇ]님! 😊\n소통에 오신 걸 진심으로 환영합니다! 🎉\n\n“외롭지 않게, 당신의 하루와 함께 걷는 소통”\n– 이것이 소통의 슬로건이자, 우리의 약속입니다.\n소통은 단순한 가계부가 아닙니다.\n당신의 재정 목표에 맞춘 하루 소비 플랜을 함께 설계하고,\n지속적인 기록과 피드백으로 목표 달성을 돕는 재정 파트너예요.\n\n💡 지금은 단순히 숫자를 적는 시대가 아니라,\n돈을 어떻게 쓰고 관리할지 함께 고민하는 시대입니다.\n\n소통은 [ㅇㅇ]님이 왜 돈을 모아야 하는지,\n그리고 어떻게 실천하면 좋을지,\n당신만을 위한 맞춤형 플랜으로 안내해드립니다.',
      delay: 500,
    );
  }

  void testPrint() {
    print('planInfo: $planInfo');
    print('refData: $refData');
    print('calculationResult: $calculationResult');
  }
}

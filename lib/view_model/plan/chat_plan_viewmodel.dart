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
    print('=== updatePlanInfo 호출 ===');
    print('fixedIncomeSum: $fixedIncomeSum');
    print('fixedConsumptionSum: $fixedConsumptionSum');
    print('dailyConsumptionSum: $dailyConsumptionSum');
    print('targetAmount: $targetAmount');

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
            '그럼 이제 $_userName님만의 목표를 향한 플랜을\n저와 함께 하나씩 만들어볼까요? 🚀\n\n현재 상황과 목표만 알려주시면,\n가장 현실적인 계획을 제안해드릴게요! 🤝',
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
            '좋아요! 이번 플랜의 성격과 가장 가까운 카드를 골라주세요.\n\n이 정보는 맞춤 팁과 통계 분석에 사용돼요 📊',
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
          addMessage('"$response"을/를 위해 플랜을 세우고 싶어요!', MessageType.user);
          notifyListeners();
          await addBotMessageWithTyping(_getTargetAmountMessage(response));
          _currentStep = ChatStep.targetAmount;
          notifyListeners();
        } else {
          await addBotMessageWithTyping('아래 카드 중 하나를 선택해주세요.');
        }
        break;

      case ChatStep.purposeCustom:
        if (response.isNotEmpty && response.length >= 2) {
          updatePlanInfo(purpose: response);
          testPrint();
          addMessage('"$response"을/를 위해 플랜을 세우고 싶어요!', MessageType.user);
          notifyListeners();
          await addBotMessageWithTyping(_getTargetAmountMessage('기타'));
          _currentStep = ChatStep.targetAmount;
          notifyListeners();
        } else {
          await addBotMessageWithTyping('목적을 2글자 이상 입력해주세요.');
        }
        break;

      case ChatStep.targetAmount:
        final amountStr = response.replaceAll(',', '').trim();
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          final formatted = SavingPlanCalculator.formatAmount(amount);
          addMessage('목표 금액은 ${formatted}원이에요!', MessageType.user);

          updatePlanInfo(targetAmount: amount);
          testPrint();
          notifyListeners();
          await addBotMessageWithTyping(
            '그렇군요! 이제 ${userName}님의 월 수입이 얼마인지 알려주세요! 💰',
          );
          _currentStep = ChatStep.monthlyIncome;
          notifyListeners();
        } else {
          await addBotMessageWithTyping('올바른 목표 금액을 입력해주세요. (예: 1000000)');
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
          await addBotMessageWithTyping('마지막으로, 소통 자동등록 서비스를 활성화해드릴까요?');
          await nextStep();
        } else {
          await addBotMessageWithTyping('"다음 단계로" 버튼을 눌러주세요.');
        }
        break;

      case ChatStep.autoService:
        if (response == '네! 좋아요') {
          updatePlanInfo(autoService: true);
          testPrint();
          notifyListeners();
          addMessage(response, MessageType.user);
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
          '소통에 오신 걸 환영해요. 🎉\n'
          '소통은 단순한 가계부가 아니라 당신만의 재정 파트너입니다.\n'
          '하루 소비 계획부터 기록·피드백까지, 목표 달성을 함께 해드려요.',
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

  String _getTargetAmountMessage(String purpose) {
    switch (purpose) {
      case '여행자금':
        return '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n참고로 여행자금의 경우, 금액별 예시는 다음과 같아요.\n\n✈ 여행자금\n100만 → 🇰🇷 국내 여행 2~3회\n500만 → 🇪🇺 유럽 여행 2주\n1000만 → 🌏 워킹홀리데이 준비\n3000만 → 🌴 해외 1년살이\n\n원하시는 금액을 입력해주세요!''';

      case '자취 준비':
        return '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n참고로 자취준비의 경우, 금액별 예시는 다음과 같아요.\n\n🏠 자취준비\n100만 → 🪑 가전·가구 일부 구입\n500만 → 🛋 원룸 보증금 + 생활 필수품\n1000만 → 🏢 오피스텔 보증금 + 가전 완비\n3000만 → 🏡 전세 자취방 입주\n\n원하시는 금액을 입력해주세요!''';

      case '부모님 선물':
        return '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n참고로 부모님 선물의 경우, 금액별 예시는 다음과 같아요.\n\n🎁 부모님 선물\n100만 → 👔 명품 지갑·의류\n500만 → ⌚ 명품 시계\n1000만 → ✈ 해외 여행 경비\n3000만 → 🚗 차량 구입\n\n원하시는 금액을 입력해주세요!''';

      case '결혼 준비':
        return '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n참고로 결혼준비의 경우, 금액별 예시는 다음과 같아요.\n\n💒 결혼준비\n100만 → 💍 예물 일부 준비\n500만 → 👗 웨딩 촬영 & 예복 대여\n1000만 → 🏨 예식장 계약금\n3000만 → 🏠 신혼집 전세금\n\n원하시는 금액을 입력해주세요!''';

      case '학자금':
        return '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n참고로 학자금의 경우, 금액별 예시는 다음과 같아요.\n\n🎓 학자금\n100만 → 📚 한 학기 교재·재료비\n500만 → 🏫 1년 등록금 일부\n1000만 → 🏫 1년 등록금 + 생활비\n3000만 → 🎓 3~4년 학비 전액(학교·전형에 따라 상이)\n\n원하시는 금액을 입력해주세요!''';

      case '이직준비':
        return '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n참고로 이직준비의 경우, 금액별 예시는 다음과 같아요.\n\n💼 이직준비\n100만 → 📖 자기계발(강의, 책)\n500만 → 💻 장비·교육비 투자\n1000만 → 🛫 단기 해외 연수\n3000만 → 🏢 창업/프리랜스 초기 자금\n\n원하시는 금액을 입력해주세요!''';

      case '긴급자금':
        return '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n참고로 긴급자금의 경우, 금액별 예시는 다음과 같아요.\n\n🚨 긴급자금\n100만 → 🏥 간단한 의료비 대비\n500만 → 🛠 차량·가전 수리비 대비\n1000만 → 🏠 3~4개월 생활비\n3000만 → 📦 1년 생활비 + 비상금\n\n원하시는 금액을 입력해주세요!''';

      default:
        return '''좋아요! 이번 플랜의 목표 금액은 얼마로 할까요? 💰\n\n참고로 기타 목적의 경우, 금액별 예시는 다음과 같아요.\n\n💡 기타\n100만 → 🎉 취미·소소한 프로젝트\n500만 → 🛠 개인 스킬업·자격증 과정\n1000만 → 🏖 장기 여행 또는 교육 과정\n3000만 → 🌏 해외 장기 체류·사업 준비\n\n원하시는 금액을 입력해주세요!''';
    }
  }

  void testPrint() {
    print('planInfo: $planInfo');
    print('refData: $refData');
    print('calculationResult: $calculationResult');
  }
}

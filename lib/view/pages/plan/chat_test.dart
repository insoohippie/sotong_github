import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import './chat_widgets/amount_guide_widget.dart';
import './chat_widgets/chat_bottom_input_area.dart';
import './chat_widgets/chat_message_widget.dart';
import './chat_widgets/input_modal_widget.dart';
import './chat_widgets/summary_section_widget.dart';
import '../../../enums/chat_step.dart';
import '../../../model/chat_message.dart';
import '../../../model/entry.dart';
import '../../../services/saving_calculator.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import 'chat_widgets/typing_indicator_widget.dart';
import 'plan_edit_page.dart'; // plan 설정 page

class ChatPlanPage extends StatefulWidget {
  const ChatPlanPage({Key? key}) : super(key: key);

  @override
  State<ChatPlanPage> createState() => _ChatPlanPageState();
}

class _ChatPlanPageState extends State<ChatPlanPage>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _bottomSlideController;
  late final Animation<Offset> _bottomSlideAnimation;

  bool _showIncomeModal = false;
  bool _showFixedCostModal = false;
  bool _showDailySpendingModal = false;
  bool _isFormatting = false;
  bool _showBottomArea = true;

  @override
  void initState() {
    super.initState();

    _bottomSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bottomSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero, // 제자리로
        ).animate(
          CurvedAnimation(
            parent: _bottomSlideController,
            curve: Curves.easeOut,
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ChatPlanViewModel>(context, listen: false);
      if (viewModel.messages.isEmpty) {
        viewModel.initializeChat();
      }
    });
  }

  @override
  void dispose() {
    _bottomSlideController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_inputController.text.trim().isNotEmpty) {
      final viewModel = Provider.of<ChatPlanViewModel>(context, listen: false);
      viewModel.handleUserResponse(_inputController.text);
      _inputController.clear();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _unformatNumber(String value) {
    return value.replaceAll(',', '');
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(_unformatNumber(value));
    if (number == null) return '';
    return NumberFormat('#,###').format(number);
  }

  bool _isChatInputEnabled(ChatStep step) {
    // Only allow chat input for planName, targetAmount, currentAssetConfirm, purposeCustom (for text input)
    return step == ChatStep.planName ||
        step == ChatStep.targetAmount ||
        step == ChatStep.currentAssetConfirm ||
        step == ChatStep.purposeCustom;
  }

  double _getBottomUIMargin(ChatPlanViewModel viewModel, bool animDone) {
    final step = viewModel.currentStep;
    final showBottom = _isChatInputEnabled(step) ||
        [
          ChatStep.onboarding1,
          ChatStep.onboarding2,
          ChatStep.onboarding3,
          ChatStep.greeting,
          ChatStep.currentAsset,
          ChatStep.monthlyIncome,
          ChatStep.monthlyFixedCost,
          ChatStep.dailySpending,
          ChatStep.summary,
          ChatStep.autoService,
        ].contains(step);

    return (showBottom && animDone) ? 200.0 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Do not call _scrollToBottom here; call it inside the Consumer builder for latest context

    bool shouldWaitForAnimation(ChatStep step) {
      return step == ChatStep.onboarding1 ||
          step == ChatStep.onboarding2 ||
          step == ChatStep.onboarding3 ||
          step == ChatStep.greeting ||
          step == ChatStep.planName ||
          step == ChatStep.purpose ||
          step == ChatStep.purposeCustom ||
          step == ChatStep.currentAsset ||
          step == ChatStep.summary ||
          step == ChatStep.autoService;
    }

    void onboardingAnimDoneCallback() {
      if (mounted) {
        setState(() {
          _showBottomArea = true;
        });
        _bottomSlideController.forward(from: 0); // 슬라이드 실행
      }
    }

    // MediaQuery를 사용하여 상태바 높이 계산
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Consumer<ChatPlanViewModel>(
        builder: (context, viewModel, child) {
          WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
          );

          bool animDone = false;
          if (viewModel.messages.isNotEmpty &&
              shouldWaitForAnimation(viewModel.currentStep)) {
            final lastBotMsg = viewModel.messages.lastWhere(
                  (m) => m.type == MessageType.bot,
              orElse: () => viewModel.messages.last,
            );
            animDone = ChatMessageWidget.completedMessageIds.contains(
              lastBotMsg.id,
            );
          }

          if (viewModel.messages.isNotEmpty &&
              shouldWaitForAnimation(viewModel.currentStep)) {
            final lastBotMsg = viewModel.messages.lastWhere(
                  (m) => m.type == MessageType.bot,
              orElse: () => viewModel.messages.last,
            );
            animDone =
                lastBotMsg.type == MessageType.bot &&
                    ChatMessageWidget.completedMessageIds.contains(lastBotMsg.id);
          }

          final messages = viewModel.messages;
          final lastIsUser =
              messages.isNotEmpty && messages.last.type == MessageType.user;
          final lastIsBot =
              messages.isNotEmpty && messages.last.type == MessageType.bot;

          return Stack(
            children: [
              Column(
                children: [
                  // Header with status bar padding
                  // CustomAppBar(title: '플랜 설정',),
                  Container(
                    padding: EdgeInsets.only(
                      top: statusBarHeight + 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF0F0F0)),
                      ),
                    ),
                    child: const Text(
                      '플랜 설정',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Chat Messages - Expanded로 남은 공간 차지하되 하단 UI 높이만큼 margin 추가
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: _getBottomUIMargin(viewModel, animDone),
                      ),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // 채팅 메세지
                          ...viewModel.messages.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final message = entry.value;
                            final isLast = idx == viewModel.messages.length - 1;
                            final shouldWait = shouldWaitForAnimation(
                              viewModel.currentStep,
                            );
                            if (isLast &&
                                shouldWait &&
                                message.type == MessageType.bot) {
                              return ChatMessageWidget(
                                message: message,
                                onComplete: onboardingAnimDoneCallback,
                                onTextUpdate: _scrollToBottom,
                              );
                            } else {
                              return ChatMessageWidget(
                                message: message,
                                onTextUpdate: _scrollToBottom,
                              );
                            }
                          }).toList(),

                          // 채팅 출력 전 입력중(''') 표시
                          if (viewModel.isTyping) const TypingIndicatorWidget(),

                          // 금액 입력 가이드(목표 금액, 보유 금액)
                          if (_inputController.text.isNotEmpty &&
                              double.tryParse(
                                _unformatNumber(_inputController.text),
                              ) !=
                                  null &&
                              ((viewModel.currentStep ==
                                  ChatStep.targetAmount &&
                                  double.parse(
                                    _unformatNumber(
                                      _inputController.text,
                                    ),
                                  ) >
                                      0) ||
                                  (viewModel.currentStep ==
                                      ChatStep.currentAssetConfirm &&
                                      double.parse(
                                        _unformatNumber(
                                          _inputController.text,
                                        ),
                                      ) !=
                                          0)))
                            AmountGuideWidget(
                              amount: double.parse(
                                _unformatNumber(_inputController.text),
                              ),
                              type:
                              viewModel.currentStep == ChatStep.targetAmount
                                  ? '목표금액'
                                  : '보유금액',
                            ),

                          // 요약 차트
                          if (viewModel.currentStep == ChatStep.summary &&
                              viewModel.calculationResult != null)
                            buildSummarySection(context, viewModel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (_showBottomArea)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _bottomSlideAnimation,
                    child: ChatBottomInputArea(
                      animDone: true,
                      showIncomeModal: () =>
                          setState(() => _showIncomeModal = true),
                      showFixedCostModal: () =>
                          setState(() => _showFixedCostModal = true),
                      showDailySpendingModal: () =>
                          setState(() => _showDailySpendingModal = true),
                      inputController: _inputController,
                      isFormatting: _isFormatting,
                      onInputChanged: (value) {
                        if (viewModel.currentStep == ChatStep.targetAmount) {
                          if (_isFormatting) return;
                          final unformatted = _unformatNumber(value);
                          final formatted = _formatNumber(unformatted);
                          if (value != formatted) {
                            _isFormatting = true;
                            _inputController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                            _isFormatting = false;
                          }
                        }
                        setState(() {});
                      },
                      onSubmit: _handleSubmit,
                      lastIsBot: lastIsBot,
                      onDisappear: () {
                        _bottomSlideController.reverse();
                        setState(() => _showBottomArea = false);
                      },
                    ),
                  ),
                ),

              // Modals
              ...(viewModel.currentStep == ChatStep.monthlyIncome ||
                  viewModel.currentStep == ChatStep.monthlyFixedCost ||
                  viewModel.currentStep == ChatStep.dailySpending)
                  ? [
                InputModalWidget(
                  isOpen: _showIncomeModal,
                  onClose: () => setState(() => _showIncomeModal = false),
                  title: '월 수입 입력하기',
                  placeholder: '수입 카테고리',
                  type: EntryType.fixed,
                  onComplete: (items, total) async {
                    final viewModel = Provider.of<ChatPlanViewModel>(
                      context,
                      listen: false,
                    );
                    viewModel.updateRefData(
                      fixedIncomes: items,
                    ); // Entry 리스트를 refData에 저장
                    print("from view, 월 수입 ");
                    print(viewModel.refData);
                    final name =
                    viewModel.planInfo.planName != null &&
                        viewModel.planInfo.planName!.isNotEmpty
                        ? viewModel.planInfo.planName
                        : '회원';
                    final itemLines = items
                        .map(
                          (e) =>
                      '${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                    )
                        .join('\n');
                    await viewModel.addBotMessageWithTyping(
                      '$name님의 월 수입은 총 ${SavingPlanCalculator.formatAmount(total)}원입니다.\n아래는 월 수입처 내역입니다.\n$itemLines',
                      awaitTyping: true,
                    );
                    // await Future.delayed(const Duration(milliseconds: 400));
                    await viewModel.addBotMessageWithTyping(
                      '이제 고정소비를 입력해주세요!',
                    );
                    viewModel.nextStep(); // 즉시 다음 단계로 이동
                  },
                ),

                InputModalWidget(
                  isOpen: _showFixedCostModal,
                  onClose: () =>
                      setState(() => _showFixedCostModal = false),
                  title: '고정 소비 입력하기',
                  placeholder: '고정 지출 항목',
                  type: EntryType.fixed,
                  onComplete: (items, total) async {
                    final viewModel = Provider.of<ChatPlanViewModel>(
                      context,
                      listen: false,
                    );
                    viewModel.updateRefData(
                      fixedConsumptions: items,
                    ); // Entry 리스트를 refData에 저장
                    print("from view, 고정 소비 ");
                    print(viewModel.refData);
                    final name =
                    viewModel.planInfo.planName != null &&
                        viewModel.planInfo.planName!.isNotEmpty
                        ? viewModel.planInfo.planName
                        : '회원';
                    final itemLines = items
                        .map(
                          (e) =>
                      '${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                    )
                        .join('\n');
                    await viewModel.addBotMessageWithTyping(
                      '$name님의 고정 소비는 총 ${SavingPlanCalculator.formatAmount(total)}원입니다.\n아래는 고정소비처 내역입니다.\n$itemLines',
                      awaitTyping: true,
                    );
                    await Future.delayed(
                      const Duration(milliseconds: 400),
                    );
                    await viewModel.addBotMessageWithTyping(
                      '이제 하루 소비 한도 금액을 입력해주세요!',
                    );
                    viewModel.nextStep(); // 즉시 다음 단계로 이동
                  },
                ),

                InputModalWidget(
                  isOpen: _showDailySpendingModal,
                  onClose: () =>
                      setState(() => _showDailySpendingModal = false),
                  title: '하루 소비 한도 금액',
                  placeholder: '소비 항목',
                  type: EntryType.daily,
                  onComplete: (items, total) async {
                    final viewModel = Provider.of<ChatPlanViewModel>(
                      context,
                      listen: false,
                    );
                    viewModel.updateRefData(
                      dailyConsumptions: items,
                    ); // Entry 리스트를 refData에 저장
                    print("from view, 소비 항목 ");
                    print(viewModel.refData);
                    print(viewModel.planInfo);
                    print(viewModel.calculationResult);
                    final name =
                    viewModel.planInfo.planName != null &&
                        viewModel.planInfo.planName!.isNotEmpty
                        ? viewModel.planInfo.planName
                        : '회원';
                    final itemLines = items
                        .map(
                          (e) =>
                      '${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                    ) // 각 항목을 문자열로 포멧팅 ex) 식비 - 12,000원
                        .join('\n');
                    await viewModel.addBotMessageWithTyping(
                      '$name님의 하루 소비 한도 금액은 총 ${SavingPlanCalculator.formatAmount(total)}원입니다.\n아래는 하루소비처 내역입니다.\n$itemLines',
                      awaitTyping: true,
                    );
                    await Future.delayed(
                      const Duration(milliseconds: 400),
                    );
                    await viewModel.addBotMessageWithTyping(
                      '입력이 완료되었습니다!',
                    );
                    viewModel.nextStep(); // 즉시 다음 단계로 이동
                  },
                ),
              ]
                  : [],
            ],
          );
        },
      ),
    );
  }
}

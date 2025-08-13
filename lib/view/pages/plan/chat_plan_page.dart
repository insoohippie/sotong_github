import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_model/plan/enums/chat_step.dart';
import '../../../view_model/services/saving_calculator.dart';
import './chat_widgets/amount_guide_widget.dart';
import './chat_widgets/chat_bottom_input_area.dart';
import './chat_widgets/chat_message_widget.dart';
import './chat_widgets/input_modal_widget.dart';
import './chat_widgets/summary_section_widget.dart';
import '../../../model/chat_message.dart';
import '../../../model/entry.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import 'chat_widgets/typing_indicator_widget.dart';

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
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
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
    return step == ChatStep.planName ||
        step == ChatStep.targetAmount ||
        step == ChatStep.purposeCustom;
  }

  @override
  Widget build(BuildContext context) {
    bool shouldWaitForAnimation(ChatStep step) {
      return [
        ChatStep.onboarding1,
        ChatStep.onboarding2,
        ChatStep.onboarding3,
        ChatStep.greeting,
        ChatStep.planName,
        ChatStep.purpose,
        ChatStep.purposeCustom,
        ChatStep.targetAmount,
        ChatStep.monthlyIncome,
        ChatStep.monthlyFixedCost,
        ChatStep.dailySpending,
        ChatStep.summary,
        ChatStep.autoService,
        ChatStep.complete,
      ].contains(step);
    }

    void onboardingAnimDoneCallback() {
      if (mounted) {
        setState(() {
          _showBottomArea = true;
        });
        _bottomSlideController.forward(from: 0);
      }
    }

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

                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(bottom: 200),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
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

                          if (viewModel.isTyping) const TypingIndicatorWidget(),

                          if (_inputController.text.isNotEmpty &&
                              double.tryParse(
                                    _unformatNumber(_inputController.text),
                                  ) !=
                                  null &&
                              ((viewModel.currentStep ==
                                      ChatStep.targetAmount &&
                                  double.parse(
                                        _unformatNumber(_inputController.text),
                                      ) >
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
                      animDone: animDone,
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

              if (viewModel.currentStep == ChatStep.monthlyIncome ||
                  viewModel.currentStep == ChatStep.monthlyFixedCost ||
                  viewModel.currentStep == ChatStep.dailySpending) ...[
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
                    viewModel.updateRefData(fixedIncomes: items);
                    final name =
                        viewModel.planInfo.planName != null &&
                            viewModel.planInfo.planName!.isNotEmpty
                        ? viewModel.planInfo.planName
                        : '회원';
                    final itemLines = items
                        .map(
                          (e) =>
                              '📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                        )
                        .join('\n');
                    await viewModel.addBotMessageWithTyping(
                      '🧾 [○○]님의 월 수입은 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n\n아래는 월 수입 내역입니다.\n$itemLines\n\n혹시 잘못 기입했거나 수정이 필요하다면, 나중에 다시 변경하실 수 있어요.\n\n이제 고정소비를 입력해볼까요?\n매달 빠져나가는 필수 지출(월세, 통신비, 보험료 등)을 적어주시면,\n남는 금액을 기반으로 계획을 세울 수 있어요.',
                      awaitTyping: true,
                    );
                    viewModel.nextStep();
                  },
                ),
                InputModalWidget(
                  isOpen: _showFixedCostModal,
                  onClose: () => setState(() => _showFixedCostModal = false),
                  title: '고정 소비 입력하기',
                  placeholder: '고정 지출 항목',
                  type: EntryType.fixed,
                  onComplete: (items, total) async {
                    final viewModel = Provider.of<ChatPlanViewModel>(
                      context,
                      listen: false,
                    );
                    viewModel.updateRefData(fixedConsumptions: items);
                    final name =
                        viewModel.planInfo.planName != null &&
                            viewModel.planInfo.planName!.isNotEmpty
                        ? viewModel.planInfo.planName
                        : '회원';
                    final itemLines = items
                        .map(
                          (e) =>
                              '📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                        )
                        .join('\n');
                    await viewModel.addBotMessageWithTyping(
                      '🧾 [○○]님의 고정 소비는 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n\n아래는 고정 소비 내역입니다.\n$itemLines\n\n혹시 잘못 기입했거나 수정이 필요하다면, 나중에 다시 변경하실 수 있어요.\n\n이제 하루 소비 한도 금액을 입력해볼까요?\n하루에 사용할 수 있는 금액을 정하면, 남은 기간 동안 목표 달성을 위한 소비 가이드가 완성돼요.',
                      awaitTyping: true,
                    );
                    viewModel.nextStep();
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
                    print('=== 하루 소비 모달 onComplete 시작 ===');
                    print('items: $items');
                    print('total: $total');

                    final viewModel = Provider.of<ChatPlanViewModel>(
                      context,
                      listen: false,
                    );

                    print('updateRefData 호출 전');
                    viewModel.updateRefData(dailyConsumptions: items);
                    print('updateRefData 호출 후');

                    final name =
                        viewModel.planInfo.planName != null &&
                            viewModel.planInfo.planName!.isNotEmpty
                        ? viewModel.planInfo.planName
                        : '회원';
                    final itemLines = items
                        .map(
                          (e) =>
                              '📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                        )
                        .join('\n');

                    print('하루 소비 완료 메시지 추가 시작');
                    await viewModel.addBotMessageWithTyping(
                      '🧾 [○○]님의 하루 소비 한도 금액은 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n(30일 기준 월 약 ${SavingPlanCalculator.formatAmount(total * 30)}원)\n아래는 하루 소비 내역입니다.\n$itemLines\n\n혹시 잘못 기입했거나 수정이 필요하다면, 나중에 다시 변경하실 수 있어요.\n\n🎯 이제 플랜 계산 결과를 확인해볼까요?\n모든 내용이 맞다면 "다음 단계로" 버튼을 눌러 진행해주세요.',
                      awaitTyping: true,
                    );
                    print('하루 소비 완료 메시지 추가 완료');

                    print('nextStep() 호출 시작');
                    await viewModel.nextStep();
                    print('nextStep() 호출 완료');
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_model/plan/enums/chat_step.dart';
import '../../../view_model/services/saving_calculator.dart';
import './chat_widgets/amount_guide_widget.dart';
import './chat_widgets/chat_bottom_input_area.dart';
import './chat_widgets/chat_message_widget.dart';
import 'chat_widgets/input_modal/input_modal_widget.dart';
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
    step == ChatStep.currentAsset
    // || step == ChatStep.purposeCustom
    ;
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
        // ChatStep.purpose,
        // ChatStep.purposeCustom,
        ChatStep.currentAssetAsk,
        ChatStep.currentAsset,
        ChatStep.targetAmount,
        ChatStep.monthlyIncome,
        ChatStep.monthlyFixedCost,
        ChatStep.dailySpending,
        ChatStep.summaryIntro,
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
    final screenHeight = mediaQuery.size.height;

    final bottomPadding = screenHeight * 0.22;

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

          final bool lastIsSummary =
              viewModel.messages.isNotEmpty && viewModel.messages.last.type == MessageType.summary;
          if (viewModel.currentStep == ChatStep.summary && lastIsSummary) {
            animDone = true;


            if (!_showBottomArea) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _showBottomArea = true);
                _bottomSlideController.forward(from: 0);
              });
            }
          }

          final messages = viewModel.messages;
          final lastIsUser =
              messages.isNotEmpty && messages.last.type == MessageType.user;
          final lastIsBot =
              messages.isNotEmpty && messages.last.type == MessageType.bot;

          final ChatMessage? lastBot = messages.isNotEmpty
              ? messages.lastWhere(
                (m) => m.type == MessageType.bot,
            orElse: () => messages.last,
          )
              : null;
          final String? lastBotId =
          (lastBot != null && lastBot.type == MessageType.bot)
              ? lastBot.id
              : null;

          final step = viewModel.currentStep;
          final raw  = _inputController.text;

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
                      margin: EdgeInsets.only(bottom: bottomPadding),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...messages.asMap().entries.map((entry) {
                            final message = entry.value;

                            final shouldWait =
                            shouldWaitForAnimation(viewModel.currentStep);

                            final isLastBot = (message.type == MessageType.bot &&
                                message.id == lastBotId);

                            if (shouldWait && isLastBot) {
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

                          if (raw.isNotEmpty &&
                              double.tryParse(_unformatNumber(raw)) != null &&
                              (
                                  // 목표금액: 양수만
                                  (step == ChatStep.targetAmount &&
                                      double.parse(_unformatNumber(raw)) > 0)
                                      ||
                                      // 보유자산: 음수/0/양수 모두 허용
                                      (step == ChatStep.currentAsset)
                              )
                          )
                            AmountGuideWidget(
                              amount: double.parse(_unformatNumber(raw)),
                              type: step == ChatStep.targetAmount ? '목표금액' : '보유금액',
                            ),

                          // summary는 ChatMessageWidget 내부에서 MessageType.summary로 렌더하도록 했으면 여기 주석 유지
                          // if (viewModel.currentStep == ChatStep.summary &&
                          //     viewModel.calculationResult != null)
                          //   buildSummarySection(context, viewModel),
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
                        final step = viewModel.currentStep;

                        if (step == ChatStep.currentAsset && value == '-') {
                          setState(() {}); // UI만 갱신
                          return;
                        }

                        // targetAmount / currentAsset만 천단위 포맷
                        if (step == ChatStep.targetAmount || step == ChatStep.currentAsset) {
                          if (_isFormatting) return;

                          final unformatted = _unformatNumber(value);
                          final formatted   = _formatNumber(unformatted);

                          if (value != formatted) {
                            _isFormatting = true;
                            _inputController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
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
                    final vm = context.read<ChatPlanViewModel>();

                    vm.updateRefData(fixedIncomes: items);

                    final itemLines = items
                        .map((e) => '\n📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원')
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '월 수입은 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n\n아래는 제가 입력한 내역이에요!$itemLines',
                      MessageType.user,
                    );
                    await vm.addBotMessageWithTyping(
                      '혹시 잘못 입력했거나 수정이 필요하다면 나중에 다시 변경하실 수 있어요.\n\n👉 이제 매달 빠져나가는 돈을 입력해볼까요? 🏠',
                      awaitTyping: true,
                    );
                    vm.nextStep();
                  },
                ),
                InputModalWidget(
                  isOpen: _showFixedCostModal,
                  onClose: () => setState(() => _showFixedCostModal = false),
                  title: '고정 소비 입력하기',
                  placeholder: '고정 소비 항목',
                  type: EntryType.fixed,
                  monthlyIncome: context.read<ChatPlanViewModel>().planInfo.fixedIncomeSum ?? 0.0,
                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    vm.updateRefData(fixedConsumptions: items);

                    final itemLines = items
                        .map((e) => '\n📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원')
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '매달 빠져나가는 고정 소비는 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n\n아래는 제가 입력한 내역이에요!$itemLines',
                      MessageType.user,
                    );
                    await vm.addBotMessageWithTyping(
                      '혹시 잘못 기입했거나 수정이 필요하다면, 나중에 다시 변경하실 수 있어요.\n\n👉 이제 하루에 사용할 금액을 정해볼까요? 💳',
                      awaitTyping: true,
                    );
                    vm.nextStep();
                  },
                ),
                InputModalWidget(
                  isOpen: _showDailySpendingModal,
                  onClose: () => setState(() => _showDailySpendingModal = false),
                  title: '하루 사용 금액',
                  placeholder: '하루 소비 항목',
                  type: EntryType.daily,
                  monthlyIncome: (() {
                    final vm = context.read<ChatPlanViewModel>();
                    final double income = vm.planInfo.fixedIncomeSum ?? 0.0;
                    final double fixed  = vm.planInfo.fixedConsumptionSum ?? 0.0;
                    final double leftover = income - fixed;
                    return leftover > 0 ? leftover : 0.0;
                  }()),
                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    vm.updateRefData(dailyConsumptions: items);

                    final itemLines = items
                        .map((e) => '\n📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원')
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '하루 사용할 금액은 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n(30일 기준 월 약 ${SavingPlanCalculator.formatAmount(total * 30)}원)\n\n아래는 하루 소비 내역입니다.$itemLines',
                      MessageType.user,
                    );
                    await vm.addBotMessageWithTyping(
                      '이제 모든 입력이 끝났습니다.\n지금까지 입력해주신 내용을 바탕으로 저축 플랜을 계산해드릴게요!',
                      awaitTyping: true,
                    );
                    vm.nextStep();
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

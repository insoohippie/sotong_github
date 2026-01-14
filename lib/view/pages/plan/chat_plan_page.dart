import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:sotong_local/view/pages/plan/plan_widgets/plan_chat/amount_guide_widget.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_chat/chat_bottom_input_area.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_chat/chat_message_widget.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_chat/typing_indicator_widget.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_input_modal/input_modal_widget.dart';

import '../../../view_model/category/local_category_view_model.dart';
import '../../../view_model/plan/enums/chat_step.dart';
import '../../../view_model/services/saving_calculator.dart';
import '../../../model/plan/chat_message.dart';
import '../../../model/refData/entry.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../view_model/category/category_view_model.dart';

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
  bool _suppressNextBottomShow = false;

  int _lastMessageCount = 0;
  static const _autoScrollThreshold = 120.0;

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    final distanceFromBottom = (pos.maxScrollExtent - pos.pixels).abs();
    return distanceFromBottom <= _autoScrollThreshold;
  }

  void _maybeScrollToBottomOnNewMessage(
      List<ChatMessage> messages, bool isTyping) {
    final added = messages.length > _lastMessageCount;
    if (added && _isNearBottom()) {
      _scrollToBottom();
    }
    _lastMessageCount = messages.length;

    if (isTyping && _isNearBottom()) {
      _scrollToBottom();
    }
  }

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
      viewModel.loadRemoteRefData();
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

  String _unformatNumber(String value) => value.replaceAll(',', '');

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(_unformatNumber(value));
    if (number == null) return '';
    return NumberFormat('#,###').format(number);
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
      if (!mounted) return;
      if (_suppressNextBottomShow) {
        _suppressNextBottomShow = false;
        return;
      }
      setState(() => _showBottomArea = true);
      _bottomSlideController.forward(from: 0);
    }

    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    const double bottomBarHeight = 250.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Consumer3<ChatPlanViewModel, CategoryViewModel, LocalCategoryViewModel>(
        builder: (context, viewModel, categoryVM, localCategoryVM, child) {
          _maybeScrollToBottomOnNewMessage(
              viewModel.messages, viewModel.isTyping);

          bool animDone = false;
          if (viewModel.messages.isNotEmpty &&
              shouldWaitForAnimation(viewModel.currentStep)) {
            final lastBotMsg = viewModel.messages.lastWhere(
                  (m) => m.type == MessageType.bot,
              orElse: () => viewModel.messages.last,
            );
            animDone = lastBotMsg.type == MessageType.bot &&
                ChatMessageWidget.completedMessageIds
                    .contains(lastBotMsg.id);
          }

          final bool lastIsSummary = viewModel.messages.isNotEmpty &&
              viewModel.messages.last.type == MessageType.summary;
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
          final raw = _inputController.text;

          final dailyCats = categoryVM.referenceCategories; // B = 참고 카테고리
          final dailyEmojiMap = { for (final c in dailyCats) c.name : c.emoji };

          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: statusBarHeight),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        bottomBarHeight + 16,
                      ),
                      children: [
                        ...messages.asMap().entries.map((entry) {
                          final message = entry.value;

                          final shouldWait =
                          shouldWaitForAnimation(viewModel.currentStep);

                          final isLastBot =
                          (message.type == MessageType.bot &&
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

                        if (viewModel.isTyping)
                          const TypingIndicatorWidget(),

                        if (raw.isNotEmpty &&
                            double.tryParse(_unformatNumber(raw)) != null &&
                            (
                                (step == ChatStep.targetAmount &&
                                    double.parse(_unformatNumber(raw)) > 0) ||
                                    (step == ChatStep.currentAsset)))
                          AmountGuideWidget(
                            amount:
                            double.parse(_unformatNumber(raw)),
                            type: step == ChatStep.targetAmount
                                ? '목표금액'
                                : '보유금액',
                          ),
                      ],
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
                          setState(() {});
                          return;
                        }

                        if (step == ChatStep.targetAmount ||
                            step == ChatStep.currentAsset) {
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

              // ================== 입력 모달들 ==================
              if (viewModel.currentStep == ChatStep.monthlyIncome ||
                  viewModel.currentStep == ChatStep.monthlyFixedCost ||
                  viewModel.currentStep == ChatStep.dailySpending) ...[
                // 1) 월 수입
                InputModalWidget(
                  isOpen: _showIncomeModal,
                  onClose: () => setState(() => _showIncomeModal = false),
                  title: '월 수입 입력하기',
                  placeholder: '수입 카테고리',
                  type: EntryType.fixed,
                  customCategories: localCategoryVM.customIncomeCategories,
                  onCustomCategoryAdded: localCategoryVM.addCustomIncomeCategory,
                  onCustomCategoryRemoved: localCategoryVM.removeCustomIncomeCategory,
                  onCustomCategoryAddedWithEmoji: localCategoryVM.addCustomIncomeCategoryWithEmoji,
                  categoryEmojis: localCategoryVM.incomeCategoryEmojis,
                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();

                    final now = DateTime.now();
                    vm.updateRefData(
                      fixedIncomes: items,
                      applyDate:
                      DateTime(now.year, now.month, now.day),
                      modEndDate:
                      DateTime(now.year, now.month, now.day),
                    );

                    final itemLines = items
                        .map(
                          (e) =>
                      '\n📌 ${e.category} : ${SavingPlanCalculator.formatAmount(e.amount)}원',
                    )
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '월 수입은 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n\n아래는 제가 입력한 내역이에요!$itemLines',
                      MessageType.user,
                    );
                    await vm.waitForTypingToFinish();

                    _suppressNextBottomShow = true;

                    await vm.addBotMessageWithTyping(
                      '이제 소비를 입력해볼게요! ✏️\n'
                          '소비는 두 단계로 나누어 입력할 거예요.\n\n',
                    );

                    await vm.addBotMessageWithTyping(
                      '먼저 한 달에 한 번 나가는 고정소비부터 시작할게요.\n\n'
                          '💡 소통 tip 💡\n고정소비는 생활에 꼭 필요한 금액으로,\n'
                          '한 달에 한 번 정기적으로 지출되는 비용이에요.\n'
                          '예: 주거비, 통신비, 구독료 등\n\n'
                          '반면 식비나 교통비처럼 매일 쓰는 돈은\n'
                          '다음 단계 ‘일 변동소비’에 입력해요!',
                      awaitTyping: true,
                    );
                    vm.nextStep();
                  },
                ),

                // 2) 고정 소비
                InputModalWidget(
                  isOpen: _showFixedCostModal,
                  onClose: () =>
                      setState(() => _showFixedCostModal = false),
                  title: '고정 소비 입력하기',
                  placeholder: '고정 소비 항목',
                  type: EntryType.fixed,
                  onCategorySettingsTap: _openFixedExpenseCategorySettings,
                  customCategories: localCategoryVM.customFixedExpenseCategories,
                  onCustomCategoryAdded: localCategoryVM.addCustomFixedExpenseCategory,
                  onCustomCategoryRemoved: localCategoryVM.removeCustomFixedExpenseCategory,
                  onCustomCategoryAddedWithEmoji: localCategoryVM.addCustomFixedExpenseCategoryWithEmoji,
                  categoryEmojis: localCategoryVM.fixedExpenseCategoryEmojis,
                  monthlyIncome:
                  context.read<ChatPlanViewModel>().totalPlan.result.totalMetrics.monthlyIncomeAmount.toDouble(),
                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    final now = DateTime.now();
                    vm.updateRefData(
                      fixedConsumptions: items,
                      applyDate:
                      DateTime(now.year, now.month, now.day),
                      modEndDate:
                      DateTime(now.year, now.month, now.day),
                    );

                    final itemLines = items
                        .map(
                          (e) =>
                      '\n📌 ${e.category} : ${SavingPlanCalculator.formatAmount(e.amount)}원',
                    )
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '매달 빠져나가는 고정 소비는 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n\n아래는 제가 입력한 내역이에요!$itemLines',
                      MessageType.user,
                    );
                    await vm.addBotMessageWithTyping(
                      '좋아요! 이제 하루 단위로 사용하는 일 변동소비를 입력해볼게요. 💳\n\n'
                          '💡 소통 tip: 일 변동소비는 매일 반복되는 생활비예요.\n'
                          '예: 식비, 교통비, 카페비, 여가비 등\n\n'
                          '작은 지출이라도 꾸준히 관리하면 절약 효과가 커진답니다! ✨',
                      awaitTyping: true,
                    );
                    vm.nextStep();
                  },
                ),

                // 3) 일 변동 소비
                InputModalWidget(
                  isOpen: _showDailySpendingModal,
                  onClose: () =>
                      setState(() => _showDailySpendingModal = false),
                  title: '하루 사용 금액',
                  placeholder: '하루 소비 항목',
                  type: EntryType.daily,
                  customCategories: dailyCats.map((c) => c.name).toList(),
                  categoryEmojis: dailyEmojiMap,
                  // 새 카테고리 추가(이름+이모지) -> reference로 저장
                  onCustomCategoryAddedWithEmoji: (name, emoji) async {
                    await categoryVM.addReferenceCategory(name: name, emoji: emoji);
                  },
                  // InputModalWidget이 “텍스트만” 추가 콜백을 쓰면 이것도 필요
                  onCustomCategoryAdded: (name) async {
                    await categoryVM.addReferenceCategory(name: name, emoji: '💰');
                  },
                  // 삭제 -> archived 처리 (name -> id 찾아서)
                  onCustomCategoryRemoved: (name) async {
                    final target = dailyCats.where((c) => c.name == name).toList();
                    if (target.isEmpty) return;
                    await categoryVM.archiveCategory(target.first.id);
                  },
                  monthlyIncome: (() {
                    final vm =
                    context.read<ChatPlanViewModel>();
                    final metrics = vm.totalPlan.result.totalMetrics;
                    final double income = metrics.monthlyIncomeAmount.toDouble();
                    final double fixed = metrics.monthlyConsumeAmount.toDouble();
                    final double leftover = income - fixed;
                    return leftover > 0 ? leftover : 0.0;
                  }()),
                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    final now = DateTime.now();
                    vm.updateRefData(
                      dailyConsumptions: items,
                      applyDate:
                      DateTime(now.year, now.month, now.day),
                      modEndDate:
                      DateTime(now.year, now.month, now.day),
                    );

                    final itemLines = items
                        .map(
                          (e) =>
                      '\n📌 ${e.category} : ${SavingPlanCalculator.formatAmount(e.amount)}원',
                    )
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '하루 사용할 금액은 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n'
                          '(30일 기준 월 약 ${SavingPlanCalculator.formatAmount(total * 30)}원)\n\n'
                          '아래는 하루 소비 내역입니다.$itemLines',
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

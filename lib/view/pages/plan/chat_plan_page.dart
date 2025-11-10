import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_model/plan/enums/chat_step.dart';
import '../../../view_model/services/saving_calculator.dart';
import './chat_widgets/amount_guide_widget.dart';
import './chat_widgets/chat_bottom_input_area.dart';
import './chat_widgets/chat_message_widget.dart';
import 'chat_widgets/input_modal/input_modal_widget.dart';
import '../../../model/chat_message.dart';
import '../../../model/entry.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import 'chat_widgets/typing_indicator_widget.dart';
import '../../../view/pages/record/record_widgets/daily_category_manage_file.dart';
import '../category/category_state_manager.dart';

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

  // 카테고리 관련 상태 변수들 (CategoryTestPage에서 가져옴)
  List<String> _customIncomeCategories = [];
  List<String> _customFixedExpenseCategories = [];
  List<String> _customDailyExpenseCategories = [];

  // 카테고리별 이모지 저장
  Map<String, String> _incomeCategoryEmojis = {};
  Map<String, String> _fixedExpenseCategoryEmojis = {};
  Map<String, String> _dailyExpenseCategoryEmojis = {};

  // ====== 자동 스크롤 제어 추가 ======
  int _lastMessageCount = 0;
  static const _autoScrollThreshold = 120.0;

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    final distanceFromBottom = (pos.maxScrollExtent - pos.pixels).abs();
    return distanceFromBottom <= _autoScrollThreshold;
  }

  void _maybeScrollToBottomOnNewMessage(
    List<ChatMessage> messages,
    bool isTyping,
  ) {
    final added = messages.length > _lastMessageCount;
    if (added && _isNearBottom()) {
      _scrollToBottom();
    }
    _lastMessageCount = messages.length;

    // 타이핑 표시가 켜질 때도 바닥 근처면 내려줌(옵션)
    if (isTyping && _isNearBottom()) {
      _scrollToBottom();
    }
  }
  // =================================

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
    _loadCategoryData();
  }

  // 카테고리 데이터 로드 (CategoryTestPage에서 가져옴)
  void _loadCategoryData() {
    setState(() {
      _customIncomeCategories = List.from(
        CategoryStateManager.customIncomeCategories,
      );
      _customFixedExpenseCategories = List.from(
        CategoryStateManager.customFixedExpenseCategories,
      );
      _customDailyExpenseCategories = List.from(
        CategoryStateManager.customDailyExpenseCategories,
      );

      _incomeCategoryEmojis = Map.from(
        CategoryStateManager.incomeCategoryEmojis,
      );
      _fixedExpenseCategoryEmojis = Map.from(
        CategoryStateManager.fixedExpenseCategoryEmojis,
      );
      _dailyExpenseCategoryEmojis = Map.from(
        CategoryStateManager.dailyExpenseCategoryEmojis,
      );
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

  void _openCategorySettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DailyCategoryManagePage()));
  }

  void _openIncomeCategorySettings() {
    Navigator.of(context).pushNamed('/income_category');
  }

  void _openFixedExpenseCategorySettings() {
    Navigator.of(context).pushNamed('/fixed_expense_category');
  }

  // 카테고리 추가 콜백들 (CategoryTestPage에서 가져옴)
  void _addCustomIncomeCategory(String category) {
    setState(() {
      if (!_customIncomeCategories.contains(category)) {
        _customIncomeCategories.add(category);
        CategoryStateManager.addCustomIncomeCategory(category);
      }
    });
  }

  void _addCustomFixedExpenseCategory(String category) {
    setState(() {
      if (!_customFixedExpenseCategories.contains(category)) {
        _customFixedExpenseCategories.add(category);
        CategoryStateManager.addCustomFixedExpenseCategory(category);
      }
    });
  }

  void _addCustomDailyExpenseCategory(String category) {
    setState(() {
      if (!_customDailyExpenseCategories.contains(category)) {
        _customDailyExpenseCategories.add(category);
        CategoryStateManager.addCustomDailyExpenseCategory(category);
      }
    });
  }

  // 카테고리와 이모지를 함께 추가하는 콜백들
  void _addCustomIncomeCategoryWithEmoji(String category, String emoji) {
    setState(() {
      if (!_customIncomeCategories.contains(category)) {
        _customIncomeCategories.add(category);
        _incomeCategoryEmojis[category] = emoji;
        CategoryStateManager.addCustomIncomeCategory(category);
        CategoryStateManager.setIncomeCategoryEmoji(category, emoji);
      }
    });
  }

  void _addCustomFixedExpenseCategoryWithEmoji(String category, String emoji) {
    setState(() {
      if (!_customFixedExpenseCategories.contains(category)) {
        _customFixedExpenseCategories.add(category);
        _fixedExpenseCategoryEmojis[category] = emoji;
        CategoryStateManager.addCustomFixedExpenseCategory(category);
        CategoryStateManager.setFixedExpenseCategoryEmoji(category, emoji);
      }
    });
  }

  void _addCustomDailyExpenseCategoryWithEmoji(String category, String emoji) {
    setState(() {
      if (!_customDailyExpenseCategories.contains(category)) {
        _customDailyExpenseCategories.add(category);
        _dailyExpenseCategoryEmojis[category] = emoji;
        CategoryStateManager.addCustomDailyExpenseCategory(category);
        CategoryStateManager.setDailyExpenseCategoryEmoji(category, emoji);
      }
    });
  }

  // 카테고리 삭제 콜백들
  void _removeCustomIncomeCategory(String category) {
    setState(() {
      _customIncomeCategories.remove(category);
      _incomeCategoryEmojis.remove(category);
      CategoryStateManager.removeCustomIncomeCategory(category);
    });
  }

  void _removeCustomFixedExpenseCategory(String category) {
    setState(() {
      _customFixedExpenseCategories.remove(category);
      _fixedExpenseCategoryEmojis.remove(category);
      CategoryStateManager.removeCustomFixedExpenseCategory(category);
    });
  }

  void _removeCustomDailyExpenseCategory(String category) {
    setState(() {
      _customDailyExpenseCategories.remove(category);
      _dailyExpenseCategoryEmojis.remove(category);
      CategoryStateManager.removeCustomDailyExpenseCategory(category);
    });
  }

  String _unformatNumber(String value) => value.replaceAll(',', '');

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(_unformatNumber(value));
    if (number == null) return '';
    return NumberFormat('#,###').format(number);
  }

  bool _isChatInputEnabled(ChatStep step) {
    return step == ChatStep.planName ||
        step == ChatStep.targetAmount ||
        step == ChatStep.currentAsset;
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
          // ✅ 새 메시지/타이핑 변화에만 조건부 자동 스크롤
          _maybeScrollToBottomOnNewMessage(
            viewModel.messages,
            viewModel.isTyping,
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
              viewModel.messages.isNotEmpty &&
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
          final raw = _inputController.text;

          return Stack(
            children: [
              Column(
                children: [
                  // 상단 패딩만 남겨두기
                  Container(
                    padding: EdgeInsets.only(
                      top: statusBarHeight + 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
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

                            final shouldWait = shouldWaitForAnimation(
                              viewModel.currentStep,
                            );

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

                          if (viewModel.isTyping) const TypingIndicatorWidget(),

                          if (raw.isNotEmpty &&
                              double.tryParse(_unformatNumber(raw)) != null &&
                              (
                              // 목표금액: 양수만
                              (step == ChatStep.targetAmount &&
                                      double.parse(_unformatNumber(raw)) > 0) ||
                                  // 보유자산: 음수/0/양수 모두 허용
                                  (step == ChatStep.currentAsset)))
                            AmountGuideWidget(
                              amount: double.parse(_unformatNumber(raw)),
                              type: step == ChatStep.targetAmount
                                  ? '목표금액'
                                  : '보유금액',
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

              if (viewModel.currentStep == ChatStep.monthlyIncome ||
                  viewModel.currentStep == ChatStep.monthlyFixedCost ||
                  viewModel.currentStep == ChatStep.dailySpending) ...[
                InputModalWidget(
                  isOpen: _showIncomeModal,
                  onClose: () => setState(() => _showIncomeModal = false),
                  title: '월 수입 입력하기',
                  placeholder: '수입 카테고리',
                  type: EntryType.fixed,
                  onCategorySettingsTap: _openIncomeCategorySettings,
                  customCategories: _customIncomeCategories,
                  onCustomCategoryAdded: _addCustomIncomeCategory,
                  onCustomCategoryRemoved: _removeCustomIncomeCategory,
                  onCustomCategoryAddedWithEmoji:
                      _addCustomIncomeCategoryWithEmoji,
                  categoryEmojis: _incomeCategoryEmojis,
                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();

                    vm.updateRefData(fixedIncomes: items);

                    final itemLines = items
                        .map(
                          (e) =>
                              '\n📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                        )
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
                  onCategorySettingsTap: _openFixedExpenseCategorySettings,
                  customCategories: _customFixedExpenseCategories,
                  onCustomCategoryAdded: _addCustomFixedExpenseCategory,
                  onCustomCategoryRemoved: _removeCustomFixedExpenseCategory,
                  onCustomCategoryAddedWithEmoji:
                      _addCustomFixedExpenseCategoryWithEmoji,
                  categoryEmojis: _fixedExpenseCategoryEmojis,
                  monthlyIncome:
                      context
                          .read<ChatPlanViewModel>()
                          .planInfo
                          .fixedIncomeSum ??
                      0.0,
                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    vm.updateRefData(fixedConsumptions: items);

                    final itemLines = items
                        .map(
                          (e) =>
                              '\n📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                        )
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
                  onClose: () =>
                      setState(() => _showDailySpendingModal = false),
                  title: '하루 사용 금액',
                  placeholder: '하루 소비 항목',
                  type: EntryType.daily,
                  onCategorySettingsTap: _openCategorySettings,
                  customCategories: _customDailyExpenseCategories,
                  onCustomCategoryAdded: _addCustomDailyExpenseCategory,
                  onCustomCategoryRemoved: _removeCustomDailyExpenseCategory,
                  onCustomCategoryAddedWithEmoji:
                      _addCustomDailyExpenseCategoryWithEmoji,
                  categoryEmojis: _dailyExpenseCategoryEmojis,
                  monthlyIncome: (() {
                    final vm = context.read<ChatPlanViewModel>();
                    final double income = vm.planInfo.fixedIncomeSum ?? 0.0;
                    final double fixed = vm.planInfo.fixedConsumptionSum ?? 0.0;
                    final double leftover = income - fixed;
                    return leftover > 0 ? leftover : 0.0;
                  }()),
                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    vm.updateRefData(dailyConsumptions: items);

                    final itemLines = items
                        .map(
                          (e) =>
                              '\n📌 ${e.category} - ${SavingPlanCalculator.formatAmount(e.amount)}원',
                        )
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/view/pages/plan/plan_edit_page.dart';

import 'package:sotong_local/view/pages/plan/plan_widgets/plan_chat/amount_guide_widget.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_chat/chat_bottom_input_area.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_chat/chat_message_widget.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_input_modal/input_modal_widget.dart';

import '../../../view_model/category/plan_category_view_model.dart';
import '../../../view_model/plan/enums/chat_step.dart';
import '../../../view_model/services/saving_calculator.dart';
import '../../../model/plan/chat_message.dart';
import '../../../model/refData/entry.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../view_model/category/category_edit_view_model.dart';

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
  bool _showBottomArea = false; // true
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

  String _unformatNumber(String value) => value.replaceAll(',', '');

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(_unformatNumber(value));
    if (number == null) return '';
    return NumberFormat('#,###').format(number);
  }

  List<Entry> _normalizeEntries({
    required List<Entry> items,
    required String Function(String name) keyOf,
    required Map<String, String> emojiMap,
    required EntryType forcedType,
  }) {
    return items.asMap().entries.map((e) {
      final i = e.key;
      final it = e.value;

      final name = it.category.trim();
      final key = keyOf(name);
      final emoji = (emojiMap[name]?.trim().isNotEmpty ?? false)
          ? emojiMap[name]!.trim()
          : '💰';

      return it.copyWith(
        idx: i,
        order: i,
        category: name,
        categoryKey: key,
        emoji: emoji,
        type: forcedType,
      );
    }).toList();
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
        ChatStep.noSaveMoney,
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
      // 이미 모달이 표시되어 있으면 다시 표시하지 않음
      if (_showBottomArea) {
        return;
      }

      // 섹터 기반 로직: 섹터의 모든 메시지가 완료되어야만 모달 표시
      final viewModel = Provider.of<ChatPlanViewModel>(context, listen: false);
      final currentStep = viewModel.currentStep;

      // summary 단계는 특별 처리: 첫 번째 봇 메시지 + summary 위젯이 완료되어야 함
      if (currentStep == ChatStep.summary) {
        final sectionMessageCount = viewModel.getSectionMessageCount(
          ChatStep.summary,
        );
        if (sectionMessageCount != null) {
          // summary 섹터는 2개 고정: 첫 번째 봇 메시지 + summary 위젯
          final botMessages = viewModel.messages
              .where((m) => m.type == MessageType.bot)
              .toList();
          final sectionStartIndex = viewModel.getSectionStartIndex(
            ChatStep.summary,
          );

          if (sectionStartIndex != null) {
            final summaryBotCount = sectionMessageCount - 1;
            // 현재 섹터의 봇 메시지만 필터링 (summary 위젯 제외)
            final currentSectionBotMessages = botMessages
                .skip(sectionStartIndex)
                .take(summaryBotCount)
                .toList();

            // summary 위젯 확인
            final hasSummaryWidget = viewModel.messages.any(
                  (m) => m.type == MessageType.summary,
            );

            // 섹터의 모든 봇 메시지가 완료되었는지 확인
            final allBotMessagesComplete =
                currentSectionBotMessages.length == summaryBotCount &&
                    currentSectionBotMessages.every(
                          (msg) =>
                          ChatMessageWidget.completedMessageIds.contains(msg.id),
                    );

            // 마지막 봇 메시지가 완료되었는지 확인 (최종 메시지)
            final lastBotMessage = currentSectionBotMessages.isNotEmpty
                ? currentSectionBotMessages.last
                : null;
            final isLastBotMessageComplete =
                lastBotMessage != null &&
                    ChatMessageWidget.completedMessageIds.contains(
                      lastBotMessage.id,
                    );

            if (allBotMessagesComplete &&
                isLastBotMessageComplete &&
                hasSummaryWidget &&
                !_showBottomArea) {
              debugPrint(
                '[onboardingAnimDoneCallback] summary 섹터 완료: 메시지 개수=${currentSectionBotMessages.length}, 모든 메시지 완료=$allBotMessagesComplete, 마지막 메시지 완료=$isLastBotMessageComplete',
              );
              setState(() => _showBottomArea = true);
              _bottomSlideController.forward(from: 0);
            } else {
              debugPrint(
                '[onboardingAnimDoneCallback] summary 섹터 미완료: 메시지 개수=${currentSectionBotMessages.length}, 모든 메시지 완료=$allBotMessagesComplete, 마지막 메시지 완료=$isLastBotMessageComplete',
              );
            }
          }
        }
        // 섹터 정보가 없으면 모달 표시하지 않음 (summary 섹터는 항상 섹터 정보가 있어야 함)
        return;
      }

      final sectionMessageCount = viewModel.getSectionMessageCount(currentStep);

      if (sectionMessageCount != null) {
        // 섹터 정보가 있으면 섹터 기반 로직 적용
        final botMessages = viewModel.messages
            .where((m) => m.type == MessageType.bot)
            .toList();

        // 현재 섹터의 시작 인덱스 가져오기
        final sectionStartIndex = viewModel.getSectionStartIndex(currentStep);

        if (sectionStartIndex != null) {
          // 현재 섹터의 메시지만 필터링 (섹터 시작 인덱스부터)
          final currentSectionMessages = botMessages
              .skip(sectionStartIndex)
              .take(sectionMessageCount)
              .toList();

          // 섹터의 모든 메시지가 완료되었는지 확인
          // 정확히 섹터의 메시지 개수만큼 있어야 하고, 마지막 메시지가 완료되어야 함
          if (currentSectionMessages.length == sectionMessageCount) {
            // 마지막 메시지가 완료되었는지 먼저 확인 (가장 중요)
            final lastMessage = currentSectionMessages.last;
            final isLastMessageComplete = ChatMessageWidget.completedMessageIds
                .contains(lastMessage.id);

            // 마지막 메시지가 완료되지 않았으면 모달 표시 안 함
            if (!isLastMessageComplete) {
              debugPrint(
                '[onboardingAnimDoneCallback] 섹터: $currentStep, 마지막 메시지 미완료, 모달 표시 안 함',
              );
              return;
            }

            // 마지막 메시지가 완료되었으면, 나머지 메시지들도 모두 완료되었는지 확인
            final allMessagesComplete = currentSectionMessages.every(
                  (msg) => ChatMessageWidget.completedMessageIds.contains(msg.id),
            );

            debugPrint(
              '[onboardingAnimDoneCallback] 섹터: $currentStep, 메시지 개수: ${currentSectionMessages.length}/$sectionMessageCount, 전체 완료: $allMessagesComplete, 마지막 완료: $isLastMessageComplete',
            );

            // 모든 메시지가 완료되었고, 특히 마지막 메시지가 완료되었을 때만 모달 표시
            if (allMessagesComplete && isLastMessageComplete) {
              setState(() => _showBottomArea = true);
              _bottomSlideController.forward(from: 0);
            }
          } else {
            debugPrint(
              '[onboardingAnimDoneCallback] 섹터: $currentStep, 메시지 개수 부족: ${currentSectionMessages.length}/$sectionMessageCount, 모달 표시 안 함',
            );
          }
        } else {
          // 섹터 시작 인덱스가 없으면 기존 로직 사용
          debugPrint(
            '[onboardingAnimDoneCallback] 섹터: $currentStep, 섹터 시작 인덱스 없음, 기존 로직 사용',
          );
          if (!_showBottomArea) {
            setState(() => _showBottomArea = true);
            _bottomSlideController.forward(from: 0);
          }
        }
      } else {
        // 섹터 정보가 없으면 기존 로직 유지
        debugPrint(
          '[onboardingAnimDoneCallback] 섹터: $currentStep, 섹터 정보 없음, 기존 로직 사용',
        );
        if (!_showBottomArea) {
          setState(() => _showBottomArea = true);
          _bottomSlideController.forward(from: 0);
        }
      }
    }

    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    const double bottomBarHeight = 250.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: Consumer3<ChatPlanViewModel, CategoryEditViewModel, PlanCategoryViewModel>(
        builder: (context, viewModel, categoryVM, localCategoryVM, child) {
          _maybeScrollToBottomOnNewMessage(
            viewModel.messages,
            viewModel.isTyping,
          );

          bool animDone = false;

          if (viewModel.messages.isNotEmpty &&
              shouldWaitForAnimation(viewModel.currentStep)) {
            // 섹터 기반 로직: 섹터의 모든 메시지가 완료되어야만 animDone = true
            if (!viewModel.isTyping) {
              final botMessages = viewModel.messages
                  .where((m) => m.type == MessageType.bot)
                  .toList();

              if (botMessages.isNotEmpty) {
                final currentStep = viewModel.currentStep;
                final sectionMessageCount = viewModel.getSectionMessageCount(
                  currentStep,
                );

                // 섹터의 메시지 개수가 정의되어 있으면 섹터 기반 로직 적용
                if (sectionMessageCount != null) {
                  // 현재 섹터의 시작 인덱스 가져오기
                  final sectionStartIndex = viewModel.getSectionStartIndex(
                    currentStep,
                  );

                  if (sectionStartIndex != null) {
                    // 현재 섹터의 메시지만 필터링 (섹터 시작 인덱스부터)
                    final currentSectionMessages = botMessages
                        .skip(sectionStartIndex)
                        .take(sectionMessageCount)
                        .toList();

                    // 섹터의 모든 메시지가 완료되어야만 animDone = true
                    // 정확히 섹터의 메시지 개수만큼 있어야 하고, 마지막 메시지가 완료되어야 함
                    if (currentSectionMessages.length == sectionMessageCount) {
                      // 마지막 메시지가 완료되었는지 먼저 확인 (가장 중요)
                      final lastMessage = currentSectionMessages.last;
                      final isLastMessageComplete = ChatMessageWidget
                          .completedMessageIds
                          .contains(lastMessage.id);

                      // 마지막 메시지가 완료되지 않았으면 animDone = false
                      if (!isLastMessageComplete) {
                        animDone = false;
                        debugPrint(
                          '[animDone] 섹터: $currentStep, 마지막 메시지 미완료, animDone = false',
                        );
                      } else {
                        // 마지막 메시지가 완료되었으면, 나머지 메시지들도 모두 완료되었는지 확인
                        final allMessagesComplete = currentSectionMessages
                            .every(
                              (msg) => ChatMessageWidget.completedMessageIds
                              .contains(msg.id),
                        );

                        // 모든 메시지가 완료되었고, 특히 마지막 메시지가 완료되었을 때만 true
                        animDone = allMessagesComplete && isLastMessageComplete;

                        debugPrint(
                          '[animDone] 섹터: $currentStep, 메시지 개수: ${currentSectionMessages.length}/$sectionMessageCount, 전체 완료: $allMessagesComplete, 마지막 완료: $isLastMessageComplete, 최종: $animDone',
                        );
                      }
                    } else {
                      // 섹터의 메시지 개수보다 적으면 무조건 false
                      animDone = false;
                      debugPrint(
                        '[animDone] 섹터: $currentStep, 메시지 개수 부족: ${currentSectionMessages.length}/$sectionMessageCount, animDone = false',
                      );
                    }
                  } else {
                    // 섹터 시작 인덱스가 없으면 기존 로직 사용
                    animDone = false;
                  }
                } else {
                  // 섹터 정보가 없으면 기존 로직: 마지막 봇 메시지가 완료되었는지 확인
                  final lastBotMsg = botMessages.last;
                  final isLastBotComplete = ChatMessageWidget
                      .completedMessageIds
                      .contains(lastBotMsg.id);
                  animDone =
                      lastBotMsg.type == MessageType.bot && isLastBotComplete;
                }
              }
            }
          }

          // 타이핑 인디케이터 완전 비활성화 (코드에서 제거됨)

          // 마지막 메시지 타이핑이 완료된 후에만 ChatBottomInputArea 표시
          // onboardingAnimDoneCallback에서 이미 처리하므로 여기서는 처리하지 않음
          // (중복 표시 방지)
          // summary 섹터는 별도 처리하므로 제외
          if (shouldWaitForAnimation(viewModel.currentStep) &&
              viewModel.currentStep != ChatStep.summary) {
            // animDone이 false이고 이미 표시되어 있으면 숨김
            // 단, 메시지가 완료되었으면 모달을 유지 (onboarding2, summaryIntro 등과 동일)
            if (!animDone && _showBottomArea) {
              // 섹터 정보가 있고 메시지가 완료되었는지 확인
              final sectionMessageCount = viewModel.getSectionMessageCount(
                viewModel.currentStep,
              );
              bool shouldHideModal = true;

              if (sectionMessageCount != null) {
                final botMessages = viewModel.messages
                    .where((m) => m.type == MessageType.bot)
                    .toList();
                final sectionStartIndex = viewModel.getSectionStartIndex(
                  viewModel.currentStep,
                );
                if (sectionStartIndex != null) {
                  final currentSectionMessages = botMessages
                      .skip(sectionStartIndex)
                      .take(sectionMessageCount)
                      .toList();
                  if (currentSectionMessages.length == sectionMessageCount) {
                    final lastMessage = currentSectionMessages.last;
                    final isLastMessageComplete = ChatMessageWidget
                        .completedMessageIds
                        .contains(lastMessage.id);
                    // 메시지가 완료되었으면 모달을 숨기지 않음 (onboarding2와 동일)
                    if (isLastMessageComplete) {
                      shouldHideModal = false;
                    }
                  }
                }
              }

              if (shouldHideModal) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _showBottomArea = false);
                });
              }
            }
          }

          // summary 단계는 특별 처리: 첫 번째 봇 메시지 + summary 위젯이 완료되어야 함
          if (viewModel.currentStep == ChatStep.summary) {
            final sectionMessageCount = viewModel.getSectionMessageCount(
              ChatStep.summary,
            );
            if (sectionMessageCount != null) {
              // summary 섹터는 2개 고정: 첫 번째 봇 메시지 + summary 위젯
              final botMessages = viewModel.messages
                  .where((m) => m.type == MessageType.bot)
                  .toList();
              final sectionStartIndex = viewModel.getSectionStartIndex(
                ChatStep.summary,
              );

              if (sectionStartIndex != null) {
                final summaryBotCount = sectionMessageCount - 1;
                // 현재 섹터의 봇 메시지만 필터링 (summary 위젯 제외)
                final currentSectionBotMessages = botMessages
                    .skip(sectionStartIndex)
                    .take(summaryBotCount)
                    .toList();

                // summary 위젯 확인
                final hasSummaryWidget = viewModel.messages.any(
                      (m) => m.type == MessageType.summary,
                );

                // 섹터의 모든 봇 메시지가 완료되었는지 확인
                final allBotMessagesComplete =
                    currentSectionBotMessages.length ==
                        summaryBotCount &&
                        currentSectionBotMessages.every(
                              (msg) => ChatMessageWidget.completedMessageIds.contains(
                            msg.id,
                          ),
                        );

                // 마지막 봇 메시지가 완료되었는지 확인
                final lastBotMessage = currentSectionBotMessages.isNotEmpty
                    ? currentSectionBotMessages.last
                    : null;
                final isLastBotMessageComplete =
                    lastBotMessage != null &&
                        ChatMessageWidget.completedMessageIds.contains(
                          lastBotMessage.id,
                        );

                animDone =
                    allBotMessagesComplete &&
                        isLastBotMessageComplete &&
                        hasSummaryWidget;

                if (animDone && !_showBottomArea) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _showBottomArea = true);
                    _bottomSlideController.forward(from: 0);
                  });
                }
              }
            }
            // 섹터 정보가 없으면 animDone = false (summary 섹터는 항상 섹터 정보가 있어야 함)
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

          return Stack(
            children: [
              GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.translucent,
                child: Column(
                  children: [
                    Container(padding: EdgeInsets.only(top: statusBarHeight)),
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          bottomBarHeight + 16,
                        ),
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

                        // 타이핑 인디케이터 완전 비활성화
                        // if (shouldShowTypingIndicator)
                        //   const TypingIndicatorWidget(),
                        if (raw.isNotEmpty &&
                            double.tryParse(_unformatNumber(raw)) != null &&
                            ((step == ChatStep.targetAmount &&
                                double.parse(_unformatNumber(raw)) > 0) ||
                                (step == ChatStep.currentAsset)))
                          AmountGuideWidget(
                            amount: double.parse(_unformatNumber(raw)),
                            type: step == ChatStep.targetAmount
                                ? '목표금액'
                                : '보유금액',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      showPlanEditPage: () async {
                        final editResult = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PlanEditPage(
                              initialPlan: viewModel.totalPlan,
                              initialRefData: viewModel.refData,
                              useLocalDraft: true,
                              // requireApplyDate: false,
                            ),
                          ),
                        );
                        if (editResult != null && mounted) {
                          viewModel.applyPlanEditResult(editResult);
                          final calc = viewModel.calculate();

                          // 저축 가능 금액이 생겼으면 summary 섹션으로 이동
                          if (calc != null && calc.dailyNetSaving > 0) {
                            await viewModel.addSummarySection();
                          }
                        }
                      },
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
                  customCategories: localCategoryVM.incomeCategories,

                  onCustomCategoryAdded: localCategoryVM.addCustomIncomeCategory,
                  onCustomCategoryRemoved: localCategoryVM.removeCustomIncomeCategory,
                  onCustomCategoryAddedWithEmoji: localCategoryVM.addCustomIncomeCategoryWithEmoji,

                  categoryEmojis: localCategoryVM.incomeCategoryEmojis,

                  onCategoryOrderChanged: (newOrder) {
                    localCategoryVM.setIncomeOrder(newOrder);
                  },

                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    final local = context.read<PlanCategoryViewModel>();
                    final now = DateTime.now();

                    final normalized = _normalizeEntries(
                      items: items,
                      keyOf: local.keyOfIncome,
                      emojiMap: local.incomeCategoryEmojis,
                      forcedType: EntryType.fixed,
                    );

                    vm.updateRefData(
                      fixedIncomes: normalized,
                      applyDate: DateTime(now.year, now.month, now.day),
                      modEndDate: DateTime(now.year, now.month, now.day),
                    );

                    final itemLines = normalized
                        .map((e) => '\n${e.emoji} ${e.category} : ${SavingPlanCalculator.formatAmount(e.amount)}원')
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '월 수입은 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n\n아래는 제가 입력한 내역이에요!$itemLines',
                      MessageType.user,
                    );
                    await vm.waitForTypingToFinish();

                    _suppressNextBottomShow = true;
                    await vm.addMonthlyFixedCostSection();
                  },
                ),

                // 2) 고정 소비
                InputModalWidget(
                  isOpen: _showFixedCostModal,
                  onClose: () => setState(() => _showFixedCostModal = false),
                  title: '고정 소비 입력하기',
                  placeholder: '고정 소비 항목',
                  type: EntryType.fixed,

                  customCategories: localCategoryVM.fixedExpenseCategories,

                  onCustomCategoryAdded: localCategoryVM.addCustomFixedExpenseCategory,
                  onCustomCategoryRemoved: localCategoryVM.removeCustomFixedExpenseCategory,
                  onCustomCategoryAddedWithEmoji: localCategoryVM.addCustomFixedExpenseCategoryWithEmoji,

                  categoryEmojis: localCategoryVM.fixedExpenseCategoryEmojis,
                  onCategoryOrderChanged: (newOrder) {
                    localCategoryVM.setFixedOrder(newOrder);
                  },

                  monthlyIncome: (() {
                    final vm = context.read<ChatPlanViewModel>();
                    final income = vm.liveMonthlyIncomeFromRef;
                    return income;
                  }()),

                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    final local = context.read<PlanCategoryViewModel>();
                    final now = DateTime.now();

                    final normalized = _normalizeEntries(
                      items: items,
                      keyOf: local.keyOfFixed,
                      emojiMap: local.fixedExpenseCategoryEmojis,
                      forcedType: EntryType.fixed,
                    );

                    vm.updateRefData(
                      fixedConsumptions: normalized,
                      applyDate: DateTime(now.year, now.month, now.day),
                      modEndDate: DateTime(now.year, now.month, now.day),
                    );

                    final itemLines = normalized
                        .map((e) => '\n${e.emoji} ${e.category} : ${SavingPlanCalculator.formatAmount(e.amount)}원')
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '매달 빠져나가는 고정 소비는 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n\n아래는 제가 입력한 내역이에요!$itemLines',
                      MessageType.user,
                    );

                    await vm.addDailySpendingSection();
                  },
                ),

                // 3) 일 변동 소비
                InputModalWidget(
                  isOpen: _showDailySpendingModal,
                  onClose: () => setState(() => _showDailySpendingModal = false),
                  title: '하루 사용 금액',
                  placeholder: '하루 소비 항목',
                  type: EntryType.daily,

                  customCategories: localCategoryVM.dailyExpenseCategories,
                  categoryEmojis: localCategoryVM.dailyExpenseCategoryEmojis,

                  onCustomCategoryAddedWithEmoji: localCategoryVM.addCustomDailyExpenseCategoryWithEmoji,
                  onCustomCategoryAdded: localCategoryVM.addCustomDailyExpenseCategory,
                  onCustomCategoryRemoved: localCategoryVM.removeCustomDailyExpenseCategory,
                  onCategoryOrderChanged: (newOrder) {
                    localCategoryVM.setDailyOrder(newOrder);
                  },

                  monthlyIncome: (() {
                    final vm = context.read<ChatPlanViewModel>();
                    final leftover = vm.liveDailyBudgetLimitFromRef;
                    return leftover;
                  }()),
                  targetAmount: context.read<ChatPlanViewModel>().totalPlan.targetAmount
                      ?.toDouble(),
                  currentAsset: context.read<ChatPlanViewModel>().totalPlan.currentAsset
                      .toDouble(),
                  dailyPreviewCalculator: (entries) {
                    final vm = context.read<ChatPlanViewModel>();
                    final now = DateTime.now();
                    return vm.previewDailyEntries(
                      entries,
                      applyDate: DateTime(now.year, now.month, now.day),
                    );
                  },

                  onComplete: (items, total) async {
                    final vm = context.read<ChatPlanViewModel>();
                    final local = context.read<PlanCategoryViewModel>();
                    final now = DateTime.now();

                    final normalized = _normalizeEntries(
                      items: items,
                      keyOf: local.keyOfDaily,
                      emojiMap: local.dailyExpenseCategoryEmojis,
                      forcedType: EntryType.daily,
                    );

                    vm.updateRefData(
                      dailyConsumptions: normalized,
                      applyDate: DateTime(now.year, now.month, now.day),
                      modEndDate: DateTime(now.year, now.month, now.day),
                    );

                    final calc = vm.calculate();
                    final hasNoSaving = calc == null || calc.dailyNetSaving <= 0;
                    if (hasNoSaving) {
                      await vm.addNoSaveMoneySection();
                      return;
                    }

                    final itemLines = normalized
                        .map((e) => '\n${e.emoji} ${e.category} : ${SavingPlanCalculator.formatAmount(e.amount)}원')
                        .join('');

                    await vm.waitForTypingToFinish();
                    vm.addMessage(
                      '하루 사용할 금액은 총 ${SavingPlanCalculator.formatAmount(total)}원이에요.\n'
                          '(30일 기준 월 약 ${SavingPlanCalculator.formatAmount(total * 30)}원)\n\n'
                          '아래는 하루 소비 내역입니다.$itemLines',
                      MessageType.user,
                    );

                    await vm.addSummarySection();
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




import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sotong/component/buttons/custom_button.dart';
import 'package:sotong/component/theme/app_colors.dart';
import 'package:sotong/model/refData/entry.dart';
import 'package:sotong/view_model/home/home_view_model.dart';
import 'package:sotong/view_model/services/saving_calculator.dart';

class _IntroSpanPart {
  const _IntroSpanPart(this.text, {this.emphasize = false});

  final String text;
  final bool emphasize;
}

class _IntroTypedBlock {
  const _IntroTypedBlock(this.parts);

  final List<_IntroSpanPart> parts;

  String get plainText => parts.map((part) => part.text).join();
}

List<_IntroTypedBlock> _buildPageThreeBlocks({
  required String dailyConsume,
  required String goalPeriod,
  required List<Entry> dailyConsumeEntries,
}) {
  final blocks = <_IntroTypedBlock>[
    _IntroTypedBlock([
      _IntroSpanPart('📊 현재 홈 화면에 보이는 그래프는,\n'),
      _IntroSpanPart('오늘 자정 00시', emphasize: true),
      _IntroSpanPart(' 기준으로 '),
      _IntroSpanPart('매초마다', emphasize: true),
      _IntroSpanPart('\n'),
      _IntroSpanPart(' 저축된 금액과 '),
      _IntroSpanPart('보유금액까지'),
      _IntroSpanPart(' 반영한 것으로부터 시작해요.'),
    ]),
    _IntroTypedBlock([
      _IntroSpanPart('💳 오늘부터 하루에 사용할 금액 '),
      _IntroSpanPart(dailyConsume, emphasize: true),
    ]),
  ];

  if (dailyConsumeEntries.isEmpty) {
    blocks.add(
      const _IntroTypedBlock([
        _IntroSpanPart('📝 입력하신 일 소비 카테고리가 없어요.'),
      ]),
    );
  } else {
    for (var i = 0; i < dailyConsumeEntries.length; i++) {
      final entry = dailyConsumeEntries[i];
      final category =
          entry.category.trim().isEmpty ? '카테고리' : entry.category.trim();
      final emoji = entry.emoji.trim().isEmpty ? '💰' : entry.emoji.trim();
      blocks.add(
        _IntroTypedBlock([
          _IntroSpanPart('${i + 1}. $emoji $category: '),
          _IntroSpanPart(
            '${SavingPlanCalculator.formatAmount(entry.amount)}원',
            emphasize: true,
          ),
        ]),
      );
    }
  }

  blocks.add(
    _IntroTypedBlock([
      const _IntroSpanPart('이대로 사용해서 '),
      _IntroSpanPart(goalPeriod, emphasize: true),
      const _IntroSpanPart('\n'),
      const _IntroSpanPart('정진해봐요! 🎯💪'),
    ]),
  );

  return blocks;
}

/// 플랜 생성 후 홈 첫 진입 시 표시하는 3페이지 플랜 요약 안내창.
Future<void> showHomePlanIntroDialog(
  BuildContext context, {
  required HomeViewModel vm,
  required VoidCallback onFinished,
}) {
  final userName = vm.name.trim().isEmpty ? '회원' : vm.name.trim();
  final planName = vm.planTitle.trim().isEmpty ? '플랜' : vm.planTitle.trim();
  final targetAmount = vm.planTargetAmountText;
  final currentAsset = vm.planCurrentAssetText;
  final remainingTarget = vm.planRemainingTargetText;
  final dailySaving = vm.planDailyNetSavingText;
  final dailyConsume = vm.planDailyNetConsumeText;
  final monthlyIncome = vm.planMonthlyIncomeText;
  final monthlyFixedConsume = vm.planMonthlyFixedConsumeText;
  final dailyVariableConsume = vm.planDailyVariableConsumeText;
  final goalPeriod = vm.planGoalPeriodText;
  final dailyConsumeEntries = vm.planDailyConsumeEntries;

  final pages = <List<_IntroTypedBlock>>[
    [
      _IntroTypedBlock([
        _IntroSpanPart('👋 $userName님, 안녕하세요!'),
      ]),
      _IntroTypedBlock([
        _IntroSpanPart('📋 \''),
        _IntroSpanPart(planName, emphasize: true),
        _IntroSpanPart('\' 플랜을 요약해드릴게요.'),
      ]),
      _IntroTypedBlock([
        _IntroSpanPart('🎯 목표금액: '),
        _IntroSpanPart(targetAmount, emphasize: true),
        _IntroSpanPart('\n💰 보유금액: '),
        _IntroSpanPart(currentAsset, emphasize: true),
        _IntroSpanPart('\n📌 총 모아야 하는 금액: '),
        _IntroSpanPart(remainingTarget, emphasize: true),
      ]),
    ],
    [
      _IntroTypedBlock([
        _IntroSpanPart('$userName님이 입력하신 재정정보에 따르면,\n'),
        _IntroSpanPart('하루 '),
        _IntroSpanPart(dailySaving, emphasize: true),
        _IntroSpanPart('이 저축돼요.'),
      ]),
      _IntroTypedBlock([
        _IntroSpanPart('📝 입력한 재정정보'),
      ]),
      _IntroTypedBlock([
        _IntroSpanPart('💵 월 수입: '),
        _IntroSpanPart(monthlyIncome, emphasize: true),
      ]),
      _IntroTypedBlock([
        _IntroSpanPart('🏠 월 고정소비: '),
        _IntroSpanPart(monthlyFixedConsume, emphasize: true),
      ]),
      _IntroTypedBlock([
        _IntroSpanPart('🛍️ 일 변동소비: '),
        _IntroSpanPart(dailyVariableConsume, emphasize: true),
      ]),
    ],
    _buildPageThreeBlocks(
      dailyConsume: dailyConsume,
      goalPeriod: goalPeriod,
      dailyConsumeEntries: dailyConsumeEntries,
    ),
  ];

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _HomePlanIntroDialog(
        pages: pages,
        onFinished: () {
          Navigator.of(dialogContext).pop();
          onFinished();
        },
      );
    },
  );
}

class _HomePlanIntroDialog extends StatefulWidget {
  const _HomePlanIntroDialog({
    required this.pages,
    required this.onFinished,
  });

  final List<List<_IntroTypedBlock>> pages;
  final VoidCallback onFinished;

  @override
  State<_HomePlanIntroDialog> createState() => _HomePlanIntroDialogState();
}

class _HomePlanIntroDialogState extends State<_HomePlanIntroDialog>
    with TickerProviderStateMixin {
  static const _typingInterval = Duration(milliseconds: 35);
  static const _blockPause = Duration(milliseconds: 280);
  static const _dialogWidth = 320.0;
  static const _blockGap = 12.0;

  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _cursorController;

  int _pageIndex = 0;
  final List<_IntroTypedBlock> _completedBlocks = [];
  int _activeBlockIndex = 0;
  int _activeTypedChars = 0;
  bool _pageTypingComplete = false;
  Timer? _typingTimer;
  final ScrollController _scrollController = ScrollController();
  List<double>? _pageMessageHeights;

  List<_IntroTypedBlock> get _currentPageBlocks => widget.pages[_pageIndex];

  bool get _isLastPage => _pageIndex >= widget.pages.length - 1;

  double get _currentMessageHeight =>
      _pageMessageHeights?[_pageIndex] ?? 120.0;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..addListener(_onCursorTick);
    _cursorController.repeat(reverse: true);
    _scaleController.forward();
    _startTypingCurrentBlock();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    _cursorController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onCursorTick() {
    if (!mounted || _pageTypingComplete) return;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageMessageHeights ??= _computePageMessageHeights(context);
  }

  List<double> _computePageMessageHeights(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxDialogHeight = (screenHeight * 0.72).clamp(260.0, 400.0);
    const chromeHeight = 24.0 + 22.0 + 10.0 + 12.0 + 14.0 + 48.0;
    final maxMessageHeight = maxDialogHeight - chromeHeight;
    final contentWidth = _dialogWidth - 44;

    return widget.pages.map((pageBlocks) {
      var pageHeight = 0.0;
      for (var i = 0; i < pageBlocks.length; i++) {
        if (i > 0) pageHeight += _blockGap;
        pageHeight += _measureBlockHeight(
          context,
          pageBlocks[i],
          contentWidth,
          textScaler,
        );
      }
      return math.min(pageHeight, maxMessageHeight);
    }).toList();
  }

  double _measureBlockHeight(
    BuildContext context,
    _IntroTypedBlock block,
    double maxWidth,
    TextScaler textScaler,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: _spansForBlock(
          context,
          block,
          block.plainText.runes.length,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: null,
    )..layout(maxWidth: maxWidth);

    return textPainter.height;
  }

  Widget _buildTypingMessageArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _completedBlocks.length; i++) ...[
          if (i > 0) const SizedBox(height: _blockGap),
          _buildBlockText(
            context,
            _completedBlocks[i],
            _completedBlocks[i].plainText.runes.length,
          ),
        ],
        if (!_pageTypingComplete &&
            _activeBlockIndex < _currentPageBlocks.length) ...[
          if (_completedBlocks.isNotEmpty) const SizedBox(height: _blockGap),
          _buildBlockText(
            context,
            _currentPageBlocks[_activeBlockIndex],
            _activeTypedChars,
            showCursor: true,
          ),
        ],
      ],
    );
  }

  TextStyle _baseStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Pretendard Variable',
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: isDark ? AppColors.darkText : Colors.black87,
    );
  }

  TextStyle _emphasisStyle(BuildContext context) {
    return _baseStyle(context).copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );
  }

  List<InlineSpan> _spansForBlock(
    BuildContext context,
    _IntroTypedBlock block,
    int typedChars, {
    bool showCursor = false,
  }) {
    var remaining = typedChars;
    final spans = <InlineSpan>[];

    for (final part in block.parts) {
      if (remaining <= 0) break;

      final runes = part.text.runes.toList();
      final take = math.min(remaining, runes.length);
      if (take <= 0) continue;

      final visible = String.fromCharCodes(runes.take(take));
      spans.add(
        TextSpan(
          text: visible,
          style: part.emphasize
              ? _emphasisStyle(context)
              : _baseStyle(context),
        ),
      );
      remaining -= take;
    }

    if (showCursor && typedChars < block.plainText.runes.length) {
      spans.add(
        TextSpan(
          text: '|',
          style: _baseStyle(context).copyWith(
            color: AppColors.primary.withValues(
              alpha: 0.35 + _cursorController.value * 0.65,
            ),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return spans;
  }

  Widget _buildBlockText(
    BuildContext context,
    _IntroTypedBlock block,
    int typedChars, {
    bool showCursor = false,
  }) {
    return Text.rich(
      TextSpan(
        children: _spansForBlock(
          context,
          block,
          typedChars,
          showCursor: showCursor,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  void _resetPageTyping() {
    _typingTimer?.cancel();
    _completedBlocks.clear();
    _activeBlockIndex = 0;
    _activeTypedChars = 0;
    _pageTypingComplete = false;
  }

  void _startTypingCurrentBlock() {
    if (_activeBlockIndex >= _currentPageBlocks.length) {
      setState(() => _pageTypingComplete = true);
      _cursorController.stop();
      return;
    }

    final block = _currentPageBlocks[_activeBlockIndex];
    final totalChars = block.plainText.runes.length;
    _activeTypedChars = totalChars == 0 ? 0 : 1;

    if (_activeTypedChars >= totalChars) {
      _finishCurrentBlock(block);
      return;
    }

    setState(() {});
    _scrollToBottom();
    if (_activeTypedChars > 0) {
      HapticFeedback.selectionClick();
    }

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(_typingInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_activeTypedChars >= totalChars) {
        timer.cancel();
        _finishCurrentBlock(block);
        return;
      }

      setState(() => _activeTypedChars++);
      HapticFeedback.selectionClick();
      if (_activeTypedChars % 6 == 0) {
        _scrollToBottom();
      }
    });
  }

  void _finishCurrentBlock(_IntroTypedBlock block) {
    setState(() {
      _completedBlocks.add(block);
      _activeTypedChars = 0;
      _activeBlockIndex++;
    });
    _scrollToBottom();

    if (_activeBlockIndex >= _currentPageBlocks.length) {
      setState(() => _pageTypingComplete = true);
      _cursorController.stop();
      return;
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(_blockPause, () {
      if (!mounted) return;
      _startTypingCurrentBlock();
    });
  }

  void _onPrimaryButtonPressed() {
    if (!_pageTypingComplete) return;

    if (_isLastPage) {
      widget.onFinished();
      return;
    }

    setState(() {
      _pageIndex++;
      _resetPageTyping();
    });
    _scrollController.jumpTo(0);
    if (!_cursorController.isAnimating) {
      _cursorController.repeat(reverse: true);
    }
    _startTypingCurrentBlock();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkSurface : Colors.white;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxDialogHeight = (screenHeight * 0.72).clamp(260.0, 400.0);
    final horizontalInset = ((screenWidth - _dialogWidth) / 2)
        .clamp(16.0, screenWidth / 2)
        .toDouble();
    final messageHeight = _currentMessageHeight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _dialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: messageHeight,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _buildTypingMessageArea(context),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_pageIndex + 1} / ${widget.pages.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkText.withValues(alpha: 0.7)
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 14),
                CustomButton(
                  text: _isLastPage ? '네 이해했어요!' : '다음',
                  height: 48,
                  padding: EdgeInsets.zero,
                  fontSize: 15,
                  enabled: _pageTypingComplete,
                  onPressed: _onPrimaryButtonPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/refData/entry.dart';
import 'package:sotong_local/model/saving_calculation_result.dart';

import '../../../../../component/buttons/small_rounded_button.dart';
import '../../../../../component/texts/caption_with_dot.dart';
import '../../../../../component/texts/header_text.dart';
import '../../../../../component/theme/app_spacing.dart';
import '../../../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';

import 'footer/footer_daily.dart';
import 'footer/footer_default.dart';
import 'input_item_row.dart';

class InputModalWidget extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String title;
  final Function(List<Entry>, double) onComplete;
  final bool isEdit; // true when editing existing data
  final String placeholder;
  final String hintText;

  /// ✅ 여기로 "기본4개+커스텀" 합쳐진 리스트를 넣어주면 됨 (VM getter)
  final List<String>? customCategories;

  final Function(String)? onCustomCategoryAdded;
  final Function(String)? onCustomCategoryRemoved;

  final Function(String, String)? onCustomCategoryAddedWithEmoji;
  final Map<String, String>? categoryEmojis;

  /// EntryType.daily | EntryType.fixed (수입/고정소비는 fixed 사용)
  final EntryType type;
  final List<Entry>? initialEntries;

  /// 비교 기준(한도). 일일: (가용예산), 고정: (월수입합)
  final double? monthlyIncome;

  /// ✅ 바텀시트에서 드래그로 바뀐 카테고리 순서를 바깥(VM)에 저장하기 위한 콜백
  /// newOrder: "현재 바텀시트에서 보여주는 categories의 최종 순서"
  final void Function(List<String> newOrder)? onCategoryOrderChanged;
  final SavingCalculationResult? Function(List<Entry> entries)?
  dailyPreviewCalculator;
  final double? targetAmount;
  final double currentAsset;

  const InputModalWidget({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.title,
    required this.onComplete,
    required this.type,
    this.isEdit = false,
    this.placeholder = '수입 카테고리',
    this.hintText = '예: 월급, 아르바이트, 용돈 등',
    this.initialEntries,
    this.monthlyIncome,
    this.customCategories,
    this.onCustomCategoryAdded,
    this.onCustomCategoryRemoved,
    this.onCustomCategoryAddedWithEmoji,
    this.categoryEmojis,
    this.onCategoryOrderChanged,
    this.dailyPreviewCalculator,
    this.targetAmount,
    this.currentAsset = 0,
  }) : super(key: key);

  @override
  State<InputModalWidget> createState() => _InputModalWidgetState();
}

class _InputModalWidgetState extends State<InputModalWidget>
    with SingleTickerProviderStateMixin {
  // ----- 애니메이션 컨트롤 -----
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _scrimFade;
  static const _kSlideMs = 500;

  bool _logicalOpen = false;

  // ----- 데이터 -----
  List<Entry> items = [];
  String error = '';
  SavingCalculationResult? _dailyPreviewResult;
  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, TextEditingController> _categoryControllers = {};

  late KeyboardVisibilityController _keyboardVisibilityController;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kSlideMs),
      reverseDuration: const Duration(milliseconds: _kSlideMs),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scrimFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _logicalOpen = widget.isOpen;
    if (_logicalOpen) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
    }

    _keyboardVisibilityController = KeyboardVisibilityController();
    _initKeyboardVisibility();
    _initItems(widget.initialEntries);
    _dailyPreviewResult = _computeDailyPreviewResult();
  }

  @override
  void didUpdateWidget(covariant InputModalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isOpen != widget.isOpen) {
      _logicalOpen = widget.isOpen;
      if (_logicalOpen) {
        _ctrl.forward();
      } else {
        _ctrl.reverse().whenComplete(() {
          if (mounted) widget.onClose();
        });
      }
    }

    if (oldWidget.monthlyIncome != widget.monthlyIncome) {
      setState(() {});
    }

    if (oldWidget.dailyPreviewCalculator != widget.dailyPreviewCalculator ||
        oldWidget.targetAmount != widget.targetAmount ||
        oldWidget.currentAsset != widget.currentAsset) {
      setState(() {
        _dailyPreviewResult = _computeDailyPreviewResult();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final c in _amountControllers.values) c.dispose();
    for (final c in _categoryControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _initKeyboardVisibility() async {
    _isKeyboardVisible = await _keyboardVisibilityController.isVisible;
    if (mounted) setState(() {});
    _keyboardVisibilityController.onChange.listen((visible) {
      if (mounted) setState(() => _isKeyboardVisible = visible);
    });
  }

  ItemKind _resolveKind() {
    if (widget.type == EntryType.daily) return ItemKind.daily;
    if (widget.title.contains('월 수입')) return ItemKind.income;
    return ItemKind.fixed;
  }

  bool _isOverBudget() {
    final kind = _resolveKind();
    final double limit = widget.monthlyIncome ?? 0.0;

    final total = getTotalAmount();

    if (limit <= 0.0) return false;
    if (kind == ItemKind.income) return false;
    if (kind == ItemKind.daily) return (getTotalAmount() * 30.0) > limit;
    return total >= limit;
  }

  void _initItems(List<Entry>? initial) {
    final kind = _resolveKind();
    final int minCount = (kind == ItemKind.daily) ? 1 : 3;

    if (initial != null && initial.isNotEmpty) {
      items = List<Entry>.from(initial);
      for (final item in items) {
        _initializeControllers(item.idx, item.category, item.amount);
      }

      while (items.length < minCount) {
        final seedIdx = DateTime.now().millisecondsSinceEpoch + items.length;
        final seed = Entry(
          idx: seedIdx,
          order: items.length,
          amount: 0.0,
          categoryKey: '',
          category: '',
          emoji: '💰',
          type: widget.type,
        );
        items.add(seed);
        _initializeControllers(seed.idx, seed.category, seed.amount);
      }
    } else {
      items = List.generate(minCount, (i) {
        final idx = DateTime.now().millisecondsSinceEpoch + i;
        return Entry(
          idx: idx,
          order: i,
          amount: 0.0,
          categoryKey: '',
          category: '',
          emoji: '💰',
          type: widget.type,
        );
      });

      for (final item in items) {
        _initializeControllers(item.idx, item.category, item.amount);
      }
    }
  }

  void _initializeControllers(int idx, String category, double amount) {
    _categoryControllers[idx] = TextEditingController(text: category);
    _amountControllers[idx] = TextEditingController(
      text: amount > 0 ? _formatNumber(amount.toStringAsFixed(0)) : '',
    );
  }

  String _unformatNumber(String value) => value.replaceAll(',', '');

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final n = int.tryParse(_unformatNumber(value));
    if (n == null) return '';
    return NumberFormat('#,###').format(n);
  }

  double getTotalAmount() =>
      items.fold<double>(0.0, (sum, item) => sum + item.amount);

  SavingCalculationResult? _computeDailyPreviewResult() {
    if (_resolveKind() != ItemKind.daily ||
        widget.dailyPreviewCalculator == null) {
      return null;
    }
    final previewEntries = items
        .map((item) => item.copyWith())
        .toList(growable: false);
    return widget.dailyPreviewCalculator!(previewEntries);
  }

  void addItem() {
    final newIdx = DateTime.now().millisecondsSinceEpoch + items.length;
    setState(() {
      items.add(
        Entry(
          idx: newIdx,
          order: items.length,
          amount: 0.0,
          categoryKey: '',
          category: '',
          emoji: '💰',
          type: widget.type,
        ),
      );
      _initializeControllers(newIdx, '', 0.0);
      if (error.isNotEmpty) error = '';
      _dailyPreviewResult = _computeDailyPreviewResult();
    });
  }

  // 불변 Entry: copyWith로 교체
  void updateItem(int idx, String field, dynamic value) {
    final i = items.indexWhere((e) => e.idx == idx);
    if (i == -1) return;

    final current = items[i];

    if (field == 'category') {
      final nextName = (value as String);
      final nextTrim = nextName.trim();

      final emojiMap = widget.categoryEmojis ?? const <String, String>{};
      final pickedEmoji = emojiMap[nextTrim];

      final nextEmoji = (pickedEmoji != null && pickedEmoji.trim().isNotEmpty)
          ? pickedEmoji.trim()
          : '💰';

      items[i] = current.copyWith(
        category: nextName,
        emoji: nextEmoji,
        categoryKey: current.categoryKey,
      );
    } else if (field == 'amount') {
      final nextAmount = (value as num).toDouble();
      items[i] = current.copyWith(amount: nextAmount);
    }

    setState(() {
      if (error.isNotEmpty) error = '';
      _dailyPreviewResult = _computeDailyPreviewResult();
    });
  }

  void updateItemCategoryWithEmoji(int idx, String category, String emoji) {
    final i = items.indexWhere((e) => e.idx == idx);
    if (i == -1) return;

    final current = items[i];

    items[i] = current.copyWith(
      category: category,
      emoji: emoji.trim().isNotEmpty ? emoji.trim() : '💰',
      categoryKey: current.categoryKey,
    );

    setState(() {
      if (error.isNotEmpty) error = '';
      _dailyPreviewResult = _computeDailyPreviewResult();
    });
  }

  void removeItem(int idx) {
    setState(() {
      items.removeWhere((e) => e.idx == idx);

      items = [
        for (int k = 0; k < items.length; k++) items[k].copyWith(order: k),
      ];

      _categoryControllers[idx]?.dispose();
      _amountControllers[idx]?.dispose();
      _categoryControllers.remove(idx);
      _amountControllers.remove(idx);
      if (error.isNotEmpty) error = '';
      _dailyPreviewResult = _computeDailyPreviewResult();
    });
  }

  Future<void> _closeAfterSubmit() async {
    if (_ctrl.status == AnimationStatus.dismissed ||
        _ctrl.status == AnimationStatus.reverse) {
      return;
    }
    await _ctrl.reverse();
    if (mounted) widget.onClose();
  }

  Future<void> handleComplete() async {
    final valid = items
        .where((e) => e.category.trim().isNotEmpty && e.amount > 0.0)
        .toList();

    final hasEmptyCategory =
    items.any((e) => e.amount > 0.0 && e.category.trim().isEmpty);

    final hasZeroAmountWithCategory =
    items.any((e) => e.amount == 0.0 && e.category.trim().isNotEmpty);

    if (hasEmptyCategory) {
      setState(() => error = '카테고리명을 정확히 입력해주세요.');
      return;
    }

    if (hasZeroAmountWithCategory) {
      setState(() => error = '금액은 0원보다 커야 해요.');
      return;
    }

    if (valid.isEmpty) {
      setState(() => error = '최소 하나의 항목을 입력해주세요.');
      return;
    }

    // 키보드 내리기 + 시트 내려가기 동시에 시작 (순차 대기 없음)
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onComplete(valid, getTotalAmount());
    debugPrint(valid.map((e) => '${e.category}=${e.emoji}').join(' | '));
    await _closeAfterSubmit();
    setState(() => error = '');
  }

  Widget buildContent() {
    final kind = _resolveKind();
    final over = _isOverBudget();

    final selectedNames = items
        .map((e) => e.category.trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    // 힌트(프리셋과 무관, 그냥 kind 기준)
    final String hint = (kind == ItemKind.daily)
        ? '예: 12,000원'
        : (kind == ItemKind.income)
        ? '예: 1,000,000원'
        : '예: 450,000원';

    final horizontalPad = PaddingResponsive16_40Vw.horizontal(
      context,
      PaddingResponsive16_40Vw.fractionModal06,
    );
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: AppSpacing.screenPadding,
      ),
      child: Column(
        children: [
          if (error.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
              ),
            ),
          ...items.map((item) {
            return InputItemRow(
              kind: kind,
              item: item,
              categoryController: _categoryControllers[item.idx]!,
              amountController: _amountControllers[item.idx]!,
              onUpdate: updateItem,
              onRemove: removeItem,

              categories: widget.customCategories,
              onCategoryAdded: widget.onCustomCategoryAdded,
              onCategoryRemoved: widget.onCustomCategoryRemoved,
              onCategoryAddedWithEmoji: widget.onCustomCategoryAddedWithEmoji,
              categoryEmojis: widget.categoryEmojis,
              onCategoryOrderChanged: widget.onCategoryOrderChanged,

              amountHint: hint,
              showMonthlyHint: kind == ItemKind.daily,
              isOverBudget: over,
              alreadySelectedNames: selectedNames,

              onCategorySelectedWithEmoji: (idx, name, emoji) {
                updateItemCategoryWithEmoji(idx, name, emoji);
              },
            );
          }).toList(),
          SmallRoundedButton(
            text: '항목 추가',
            onPressed: addItem,
            icon: Icons.add,
            backgroundColor: Colors.white,
            textColor: AppColors.subText,
          ),
        ],
      ),
    );
  }

  Widget buildDetailBox() {
    String titleText = '일 변동소비 예산을\n입력해주세요';
    String captionText = '하루 지출을 입력하면 월(30일) 변동예산을 자동으로 계산해요.';
    final kind = _resolveKind();
    if (kind == ItemKind.income) {
      titleText = '월 수입을 입력해주세요';
      captionText = '매달 들어오는 수입을 항목별로 입력해요.';
    } else if (kind == ItemKind.fixed) {
      titleText = '고정 소비를 입력해주세요';
      captionText = '매달 고정적으로 지출되는 비용만 입력해요.';
    }

    return Visibility(
      visible: !_isKeyboardVisible,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: PaddingResponsive16_40Vw.horizontal(
                context,
                PaddingResponsive16_40Vw.fractionModal06,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderText(text: titleText),
                const SizedBox(height: 10),
                CaptionWithDot(text: captionText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFooter() {
    final kind = _resolveKind();
    final over = _isOverBudget();
    final double limit = widget.monthlyIncome ?? 0.0;

    debugPrint(
      '[FOOTER_BUILD] '
          'title=${widget.title}, '
          'kind=$kind, '
          'limit=$limit, '
          'total=${getTotalAmount()}, '
          'over=$over',
    );


    if (kind == ItemKind.daily) {
      return FooterDaily(
        total: getTotalAmount(),
        onComplete: handleComplete,
        isOverBudget: over,
        monthlyIncome: limit,
        isEdit: widget.isEdit,
        previewResult: _dailyPreviewResult,
        targetAmount: widget.targetAmount,
        currentAsset: widget.currentAsset,
      );
    } else {
      return FooterDefault(
        total: getTotalAmount(),
        onComplete: handleComplete,
        isOverBudget: over,
        monthlyIncome: limit,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _ctrl.status == AnimationStatus.dismissed,
      child: Stack(
        children: [
          FadeTransition(
            opacity: _scrimFade,
            child: GestureDetector(
              onTap: () =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.black54),
            ),
          ),
          Positioned.fill(
            child: SlideTransition(
              position: _slide,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  heightFactor: 0.96,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.98, end: 1.0),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                        bottom: Radius.zero,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              buildDetailBox(),
                              if (!_isKeyboardVisible)
                                const SizedBox(height: 8),
                              Expanded(child: buildContent()),
                              buildFooter(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

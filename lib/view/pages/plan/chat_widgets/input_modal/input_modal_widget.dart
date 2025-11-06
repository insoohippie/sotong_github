import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/refData/entry.dart';

import '../../../../../component/buttons/small_rounded_button.dart';
import '../../../../../component/texts/caption_with_dot.dart';
import '../../../../../component/texts/header_text.dart';
import '../../../../../component/theme/app_spacing.dart';

import 'footer_daily.dart';
import 'footer_default.dart';
import 'category_utils.dart';
import 'input_item_row.dart';

class InputModalWidget extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String title;
  final Function(List<Entry>, double) onComplete;
  final String placeholder;
  final String hintText;
  /// EntryType.daily | EntryType.fixed (수입/고정소비는 fixed 사용)
  final EntryType type;
  final List<Entry>? initialEntries;
  /// 비교 기준(한도). 일일: (가용예산), 고정: (월수입합)
  final double? monthlyIncome;
  /// 수정 모드(예산 초과 경고/흔들림/비활성화 억제)
  final bool isEditMode;

  const InputModalWidget({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.title,
    required this.onComplete,
    required this.type,
    this.placeholder = '수입 카테고리',
    this.hintText = '예: 월급, 아르바이트, 용돈 등',
    this.initialEntries,
    this.monthlyIncome,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  State<InputModalWidget> createState() => _InputModalWidgetState();
}

class _InputModalWidgetState extends State<InputModalWidget>
    with SingleTickerProviderStateMixin {
  // ----- 애니메이션 컨트롤 -----
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide; // 아래서 위로/위에서 아래로
  late final Animation<double> _scrimFade;
  static const _kSlideMs = 500; // 닫힘이 확실히 보이도록 500ms
  static const _kScrimMs = 220;

  bool _logicalOpen = false; // 논리적 열림(내부 상태)

  // ----- 데이터 -----
  List<Entry> items = [];
  String error = '';
  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, TextEditingController> _categoryControllers = {};

  late KeyboardVisibilityController _keyboardVisibilityController;
  bool _isKeyboardVisible = false;

  // 화면 높이 비율 기반 간격 유틸: ratio * height, min/max로 클램프
  double _vh(BuildContext context, double ratio, {double min = 0, double max = double.infinity}) {
    final h = MediaQuery.of(context).size.height;
    final v = h * ratio;
    return v.clamp(min, max);
  }

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kSlideMs),
      reverseDuration: const Duration(milliseconds: _kSlideMs),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1), // 아래서 시작
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scrimFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _logicalOpen = widget.isOpen;
    if (_logicalOpen) {
      // 첫 프레임 이후 forward 해야 제대로 보임
      SchedulerBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
    }

    _keyboardVisibilityController = KeyboardVisibilityController();
    _initKeyboardVisibility();
    _initItems(widget.initialEntries);
  }

  @override
  void didUpdateWidget(covariant InputModalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 외부 isOpen 변경 → 내부 애니로 동기화
    if (oldWidget.isOpen != widget.isOpen) {
      _logicalOpen = widget.isOpen;
      if (_logicalOpen) {
        _ctrl.forward();
      } else {
        // 외부가 강제 닫기한 경우에도 부드럽게
        _ctrl.reverse().whenComplete(() {
          if (mounted) widget.onClose();
        });
      }
    }

    if (oldWidget.monthlyIncome != widget.monthlyIncome) {
      setState(() {});
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
    if (widget.isEditMode) return false;
    final kind = _resolveKind();
    final double limit = widget.monthlyIncome ?? 0.0;
    if (limit <= 0.0) return false;
    if (kind == ItemKind.income) return false;
    if (kind == ItemKind.daily) return (getTotalAmount() * 30.0) > limit;
    return getTotalAmount() > limit;
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
        final seed = Entry(
          idx: DateTime.now().millisecondsSinceEpoch + items.length,
          amount: 0.0,
          category: '',
          type: widget.type,
        );
        items.add(seed);
        _initializeControllers(seed.idx, seed.category, seed.amount);
      }
    } else {
      items = List.generate(minCount, (i) {
        return Entry(
          idx: DateTime.now().millisecondsSinceEpoch + i,
          amount: 0.0,
          category: '',
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

  void addItem() {
    final newIdx = DateTime.now().millisecondsSinceEpoch + items.length;
    setState(() {
      items.add(Entry(idx: newIdx, amount: 0.0, category: '', type: widget.type));
      _initializeControllers(newIdx, '', 0.0);
      if (error.isNotEmpty) error = '';
    });
  }

  void updateItem(int idx, String field, dynamic value) {
    final i = items.indexWhere((e) => e.idx == idx);
    if (i == -1) return;
    if (field == 'category') {
      items[i].category = value as String;
    } else if (field == 'amount') {
      items[i].amount = (value as num).toDouble();
    }
    setState(() {
      if (error.isNotEmpty) error = '';
    });
  }

  void removeItem(int idx) {
    setState(() {
      items.removeWhere((e) => e.idx == idx);
      _categoryControllers[idx]?.dispose();
      _amountControllers[idx]?.dispose();
      _categoryControllers.remove(idx);
      _amountControllers.remove(idx);
      if (error.isNotEmpty) error = '';
    });
  }

  Future<void> _closeWithAnimation() async {
    if (_ctrl.status == AnimationStatus.dismissed ||
        _ctrl.status == AnimationStatus.reverse) {
      return;
    }
    await _ctrl.reverse(); // ↓ 슬라이드 다운 + 스크림 페이드아웃
    if (mounted) widget.onClose(); // 여기서 부모가 isOpen=false로 바꿔주세요.
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

    widget.onComplete(valid, getTotalAmount());
    await _closeWithAnimation(); // 닫힘 애니 후 onClose 호출
    setState(() => error = '');
  }

  Widget buildContent() {
    final kind = _resolveKind();
    final over = _isOverBudget();

    // 본문 위·아래 마진도 비율 기반으로 조절 (가벼운 예시)
    final contentTopGap = _vh(context, 0.01, min: 6, max: 12);
    final contentBottomGap = _vh(context, 0.012, min: 8, max: 16);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.screenPadding + contentTopGap,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding + contentBottomGap,
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
              child: const Text(
                '카테고리/금액을 확인해주세요.',
                style: TextStyle(color: Color(0xFFDC2626), fontSize: 14),
              ),
            ),
          ...items.map((item) {
            late final List<CatPreset> presets;
            late final String hint;

            if (kind == ItemKind.daily) {
              presets = dailyPresets;
              hint = '예: 12,000원';
            } else if (kind == ItemKind.income) {
              presets = incomePresets;
              hint = '예: 1,000,000원';
            } else {
              presets = fixedPresets;
              hint = '예: 450,000원';
            }

            return InputItemRow(
              kind: kind,
              item: item,
              categoryController: _categoryControllers[item.idx]!,
              amountController: _amountControllers[item.idx]!,
              onUpdate: updateItem,
              onRemove: removeItem,
              presets: presets,
              amountHint: hint,
              showMonthlyHint: kind == ItemKind.daily,
              isOverBudget: over,
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
      captionText = '매달 반복적으로 들어오는 수입을 항목별로 입력해요.';
    } else if (kind == ItemKind.fixed) {
      titleText = '고정 소비를 입력해주세요';
      captionText = '매달 빠짐없이 자동으로 지출되는 비용만 입력해요.';
    }

    // 상단 여백: 화면 높이의 % (min ~ max px 사이)
    final topGap = _vh(context, 0.08, min: 48, max: 120);
    // 제목 아래 간격: 1.2% (6~14px)
    final underTitleGap = _vh(context, 0.01, min: 6, max: 14);

    return Visibility(
      visible: !_isKeyboardVisible,
      child: Column(
        children: [
          SizedBox(height: topGap),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderText(text: titleText),
                SizedBox(height: underTitleGap),
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

    if (kind == ItemKind.daily) {
      return FooterDaily(
        total: getTotalAmount(),
        onComplete: handleComplete,
        isOverBudget: over,
        monthlyIncome: limit,
        isEdit: widget.isEditMode,
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
          // 스크림
          FadeTransition(
            opacity: _scrimFade,
            child: GestureDetector(
              child: Container(color: Colors.black54),
            ),
          ),
          // 모달
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
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            buildDetailBox(),
                            if (!_isKeyboardVisible)
                              SizedBox(height: _vh(context, 0.01, min: 6, max: 12)),
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
        ],
      ),
    );
  }
}

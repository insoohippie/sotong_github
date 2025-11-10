import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/entry.dart';

import '../../../../component/buttons/small_rounded_button.dart';
import '../../../../component/texts/caption_with_dot.dart';
import '../../../../component/texts/header_text.dart';
import '../../../../component/theme/app_spacing.dart';

import '../plan/chat_widgets/input_modal/footer_daily.dart';
import '../plan/chat_widgets/input_modal/footer_default.dart';
import '../plan/chat_widgets/input_modal/category_utils.dart';
import '../plan/chat_widgets/input_modal/input_item_row.dart';

/// 일 변동소비 입력 모달 전용 페이지 (원본 InputModalWidget 기반)
class DailyExpenseModalPage extends StatefulWidget {
  final String title;
  final Function(List<Entry>, double)? onComplete;
  final String placeholder;
  final String hintText;
  final VoidCallback? onCategorySettingsTap;
  final EntryType type;
  final List<Entry>? initialEntries;
  final double? monthlyIncome;

  const DailyExpenseModalPage({
    Key? key,
    this.title = '일 변동소비 예산을 입력해주세요',
    this.onComplete,
    this.placeholder = '수입 카테고리',
    this.hintText = '예: 월급, 아르바이트, 용돈 등',
    this.onCategorySettingsTap,
    this.type = EntryType.daily,
    this.initialEntries,
    this.monthlyIncome,
  }) : super(key: key);

  @override
  State<DailyExpenseModalPage> createState() => _DailyExpenseModalPageState();
}

class _DailyExpenseModalPageState extends State<DailyExpenseModalPage>
    with SingleTickerProviderStateMixin {
  // ----- 애니메이션 컨트롤 -----
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide; // 아래서 위로/위에서 아래로
  late final Animation<double> _scrimFade;
  static const _kSlideMs = 500; // 닫힘이 확실히 보이도록 500ms

  // ----- 데이터 -----
  List<Entry> items = [];
  String error = '';
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
      begin: const Offset(0, 1), // 아래서 시작
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scrimFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    // 첫 프레임 이후 forward 해야 제대로 보임
    SchedulerBinding.instance.addPostFrameCallback((_) => _ctrl.forward());

    _keyboardVisibilityController = KeyboardVisibilityController();
    _initKeyboardVisibility();
    _initItems(widget.initialEntries);
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
      items.add(
        Entry(idx: newIdx, amount: 0.0, category: '', type: widget.type),
      );
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
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> handleComplete() async {
    final valid = items
        .where((e) => e.category.trim().isNotEmpty && e.amount > 0.0)
        .toList();

    final hasEmptyCategory = items.any(
      (e) => e.amount > 0.0 && e.category.trim().isEmpty,
    );

    final hasZeroAmountWithCategory = items.any(
      (e) => e.amount == 0.0 && e.category.trim().isNotEmpty,
    );

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

    if (widget.onComplete != null) {
      widget.onComplete!(valid, getTotalAmount());
    }

    Navigator.of(context).pop({'entries': valid, 'total': getTotalAmount()});
    setState(() => error = '');
  }

  Widget buildContent() {
    final kind = _resolveKind();
    final over = _isOverBudget();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
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
              onCategorySettingsTap: widget.onCategorySettingsTap,
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

    return Visibility(
      visible: !_isKeyboardVisible,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
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

    if (kind == ItemKind.daily) {
      return FooterDaily(
        total: getTotalAmount(),
        onComplete: handleComplete,
        isOverBudget: over,
        monthlyIncome: limit,
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
    // 부모는 항상 위젯을 트리에 유지하고 isOpen만 바꿔주면 됩니다.
    return IgnorePointer(
      ignoring: _ctrl.status == AnimationStatus.dismissed,
      child: Stack(
        children: [
          // 스크림
          FadeTransition(
            opacity: _scrimFade,
            child: GestureDetector(
              onTap: _closeWithAnimation, // 탭으로 닫기(애니 후 onClose)
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
                            if (!_isKeyboardVisible) const SizedBox(height: 8),
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

/// 일 변동소비 입력 모달 페이지를 열고 결과를 받는 함수
Future<Map<String, dynamic>?> openDailyExpenseModalPage(
  BuildContext context, {
  String? title,
  List<Entry>? initialEntries,
  double? monthlyIncome,
  VoidCallback? onCategorySettingsTap,
  EntryType type = EntryType.daily,
}) async {
  final result = await Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      builder: (context) => DailyExpenseModalPage(
        title: title ?? '일 변동소비 예산을 입력해주세요',
        initialEntries: initialEntries,
        monthlyIncome: monthlyIncome,
        onCategorySettingsTap: onCategorySettingsTap,
        type: type,
      ),
    ),
  );
  return result;
}

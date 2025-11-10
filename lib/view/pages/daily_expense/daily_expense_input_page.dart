import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/buttons/small_rounded_button.dart';
import 'package:sotong_local/component/texts/caption_with_dot.dart';
import 'package:sotong_local/component/texts/header_text.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/theme/app_spacing.dart';
import 'package:sotong_local/model/entry.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/input_modal/category_utils.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/input_modal/input_item_row.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/input_modal/footer_daily.dart';

/// 일 변동소비 입력 전용 페이지
class DailyExpenseInputPage extends StatefulWidget {
  final List<Entry>? initialEntries;
  final double? monthlyIncome;
  final VoidCallback? onCategorySettingsTap;
  final Function(List<Entry>, double)? onComplete;

  const DailyExpenseInputPage({
    Key? key,
    this.initialEntries,
    this.monthlyIncome,
    this.onCategorySettingsTap,
    this.onComplete,
  }) : super(key: key);

  @override
  State<DailyExpenseInputPage> createState() => _DailyExpenseInputPageState();
}

class _DailyExpenseInputPageState extends State<DailyExpenseInputPage> {
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
    _keyboardVisibilityController = KeyboardVisibilityController();
    _initKeyboardVisibility();
    _initItems(widget.initialEntries);
  }

  @override
  void dispose() {
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

  bool _isOverBudget() {
    final double limit = widget.monthlyIncome ?? 0.0;
    if (limit <= 0.0) return false;
    return (getTotalAmount() * 30.0) > limit;
  }

  void _initItems(List<Entry>? initial) {
    final int minCount = 1;

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
          type: EntryType.daily,
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
          type: EntryType.daily,
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
        Entry(idx: newIdx, amount: 0.0, category: '', type: EntryType.daily),
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
  }

  Widget buildContent() {
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
            return InputItemRow(
              kind: ItemKind.daily,
              item: item,
              categoryController: _categoryControllers[item.idx]!,
              amountController: _amountControllers[item.idx]!,
              onUpdate: updateItem,
              onRemove: removeItem,
              presets: dailyPresets,
              onCategorySettingsTap: widget.onCategorySettingsTap,
              amountHint: '예: 12,000원',
              showMonthlyHint: true,
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
    return Visibility(
      visible: !_isKeyboardVisible,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderText(text: '일 변동소비 예산을\n입력해주세요'),
                const SizedBox(height: 10),
                CaptionWithDot(text: '하루 지출을 입력하면 월(30일) 변동예산을 자동으로 계산해요.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFooter() {
    final over = _isOverBudget();
    final double limit = widget.monthlyIncome ?? 0.0;

    return FooterDaily(
      total: getTotalAmount(),
      onComplete: handleComplete,
      isOverBudget: over,
      monthlyIncome: limit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '일 변동소비 입력',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          buildDetailBox(),
          if (!_isKeyboardVisible) const SizedBox(height: 8),
          Expanded(child: buildContent()),
          buildFooter(),
        ],
      ),
    );
  }
}

/// 일 변동소비 입력 페이지를 열고 결과를 받는 함수
Future<Map<String, dynamic>?> openDailyExpenseInputPage(
  BuildContext context, {
  List<Entry>? initialEntries,
  double? monthlyIncome,
  VoidCallback? onCategorySettingsTap,
}) async {
  final result = await Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      builder: (context) => DailyExpenseInputPage(
        initialEntries: initialEntries,
        monthlyIncome: monthlyIncome,
        onCategorySettingsTap: onCategorySettingsTap,
      ),
    ),
  );
  return result;
}

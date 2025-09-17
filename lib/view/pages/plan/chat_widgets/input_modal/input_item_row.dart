// input_item_row.dart
import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/entry.dart';
import 'category_utils.dart';

enum ItemKind { daily, income, fixed }

class InputItemRow extends StatelessWidget {
  final ItemKind kind;
  final Entry item;
  final TextEditingController categoryController;
  final TextEditingController amountController;
  final void Function(int idx, String field, dynamic value) onUpdate;
  final void Function(int idx) onRemove;
  final List<CatPreset> presets;

  /// 기본 힌트(카테고리 매칭 안되면 사용)
  final String? amountHint;
  final bool showMonthlyHint;

  const InputItemRow({
    Key? key,
    required this.kind,
    required this.item,
    required this.categoryController,
    required this.amountController,
    required this.onUpdate,
    required this.onRemove,
    required this.presets,
    this.amountHint,
    this.showMonthlyHint = true,
  }) : super(key: key);

  // ──────────────────────────────────────────────────────────────
  // 카테고리별 예시 힌트 맵
  // ──────────────────────────────────────────────────────────────
  Map<String, String> get _incomeHints => const {
    '급여': '2,500,000원',
    '부업·아르바이트': '300,000원',
    '금융소득': '50,000원',
  };

  Map<String, String> get _fixedHints => const {
    '주거비': '600,000원',
    '통신비': '100,000원',
    '보험료': '150,000원',
  };

  Map<String, String> get _dailyHints => const {
    '식비': '15,000원',
    '교통비': '1,500원',
    '쇼핑': '10,000원',
  };

  String _un(String v) => v.replaceAll(',', '');
  String _comma(String v) {
    if (v.isEmpty) return '';
    final n = int.tryParse(_un(v));
    if (n == null) return '';
    return n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  /// 현재 카테고리 텍스트로 동적 힌트 계산
  String _dynamicAmountHint() {
    final cat = categoryController.text.trim();
    final map = switch (kind) {
      ItemKind.income => _incomeHints,
      ItemKind.fixed  => _fixedHints,
      ItemKind.daily  => _dailyHints,
    };
    if (cat.isNotEmpty && map.containsKey(cat)) {
      return '예: ${map[cat]}' ; // "예: 2,500,000원"
    }
    return amountHint ?? '예: 1,000,000';
  }

  @override
  Widget build(BuildContext context) {
    final isDaily = kind == ItemKind.daily;
    final raw = _un(amountController.text);
    final double value = double.tryParse(raw) ?? 0;
    final int monthly = isDaily ? (value * 30).round() : 0;

    return Dismissible(
      key: ValueKey('row_${item.idx}'),
      direction: DismissDirection.endToStart,
      background: _swipeBg(Alignment.centerRight),
      onDismissed: (_) => onRemove(item.idx),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 카테고리
                Expanded(
                  flex: 2,
                  child: CategoryPill(
                    text: categoryController.text,
                    presets: presets,
                    onTap: () => openCategorySheet(
                      context,
                      categoryController,
                          (val) => onUpdate(item.idx, 'category', val),
                      presets: presets,
                    ),
                    onClear: () {
                      categoryController.clear();
                      onUpdate(item.idx, 'category', '');
                    },
                    height: 60,
                  ),
                ),
                const SizedBox(width: 10),

                // 금액 (← 힌트가 카테고리에 따라 자동 변함)
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    controller: amountController,
                    hintText: _dynamicAmountHint(),
                    keyboardType: TextInputType.number,
                    borderRadius: 12,
                    height: 60,
                    onChanged: (v) {
                      final un = _un(v);
                      final amt = double.tryParse(un) ?? 0;
                      onUpdate(item.idx, 'amount', amt);

                      final formatted = _comma(un);
                      if (formatted != v) {
                        amountController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            // daily면 월환산 안내문
            if (isDaily && showMonthlyHint && value > 0)
              const SizedBox(height: 6),
            if (isDaily && showMonthlyHint && value > 0)
              Row(
                children: [
                  const Text(
                    '30일 기준, 한 달에 ',
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  Text(
                    '${_comma(monthly.toString())}원',
                    style: const TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    ' 이에요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _swipeBg(AlignmentGeometry align) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
    );
  }
}
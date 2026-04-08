import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/refData/entry.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_input_modal/plan_category_pill.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_input_modal/plan_category_sheet.dart';

enum ItemKind { daily, income, fixed }

class InputItemRow extends StatelessWidget {
  final ItemKind kind;
  final Entry item;

  final TextEditingController categoryController;
  final TextEditingController amountController;

  final void Function(int idx, String field, dynamic value) onUpdate;
  final void Function(int idx) onRemove;

  // ---- 카테고리 관련 ----
  /// ✅ 여기엔 "기본4개+커스텀"이 합쳐진 리스트가 들어오면 됨 (VM에서 보장)
  final List<String>? categories;

  final Function(String)? onCategoryAdded;
  final Function(String)? onCategoryRemoved;

  final Function(String name, String emoji)? onCategoryAddedWithEmoji;

  /// ✅ category -> emoji (기본+커스텀 merge된 맵을 넘겨줘야 함)
  final Map<String, String>? categoryEmojis;

  final Set<String> alreadySelectedNames;

  final void Function(List<String> newOrder)? onCategoryOrderChanged;

  // ---- 금액/표시 관련 ----
  final String? amountHint;
  final bool showMonthlyHint;
  final bool isOverBudget;

  const InputItemRow({
    Key? key,
    required this.kind,
    required this.item,
    required this.categoryController,
    required this.amountController,
    required this.onUpdate,
    required this.onRemove,
    required this.alreadySelectedNames,
    this.categories,
    this.onCategoryAdded,
    this.onCategoryRemoved,
    this.onCategoryAddedWithEmoji,
    this.categoryEmojis,
    this.onCategoryOrderChanged,
    this.amountHint,
    this.showMonthlyHint = true,
    this.isOverBudget = false,
  }) : super(key: key);

  // ---------- 카테고리별 기본 힌트 ----------
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

  // ---------- 숫자 포맷 ----------
  String _un(String v) => v.replaceAll(',', '');
  String _comma(String v) {
    if (v.isEmpty) return '';
    final n = int.tryParse(_un(v));
    if (n == null) return '';
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
    );
  }

  String _dynamicAmountHint() {
    final cat = categoryController.text.trim();
    final map = switch (kind) {
      ItemKind.income => _incomeHints,
      ItemKind.fixed => _fixedHints,
      ItemKind.daily => _dailyHints,
    };

    if (cat.isNotEmpty && map.containsKey(cat)) {
      return '예: ${map[cat]}';
    }
    return amountHint ?? '예: 1,000,000원';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDaily = kind == ItemKind.daily;

    final raw = _un(amountController.text);
    final double value = double.tryParse(raw) ?? 0.0;
    final int monthly = isDaily ? (value * 30).round() : 0;

    // ✅ “입력이 있는 행”만 붉게
    final bool hasInput =
        categoryController.text.trim().isNotEmpty || value > 0.0;

    final Color? fieldBg =
    (isOverBudget && hasInput) ? const Color(0xFFFFF1F1) : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Dismissible(
            key: ValueKey('row_${item.idx}'),
            direction: DismissDirection.endToStart,
            background: _swipeBg(Alignment.centerRight),
            onDismissed: (_) => onRemove(item.idx),
            child: Row(
              children: [
                // ✅ 카테고리 Pill
                Expanded(
                  flex: 2,
                  child: _buildCategoryPill(context),
                ),
                const SizedBox(width: 10),

                // 금액 입력
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    controller: amountController,
                    hintText: _dynamicAmountHint(),
                    keyboardType: TextInputType.number,
                    borderRadius: 12,
                    height: 60,
                    backgroundColor: fieldBg,
                    onChanged: (v) {
                      final un = _un(v);
                      final amt = double.tryParse(un) ?? 0.0;
                      onUpdate(item.idx, 'amount', amt);

                      final formatted = _comma(un);
                      if (formatted != v) {
                        amountController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // 일일 → 월환산 안내문
          if (isDaily && showMonthlyHint && value > 0.0) ...[
            const SizedBox(height: 6),
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
        ],
      ),
    );
  }

  /// 카테고리 Pill + 바텀시트 오픈 로직
  Widget _buildCategoryPill(BuildContext context) {
    final allNames = (categories ?? const <String>[]).toList(growable: false);
    final emojiMap = categoryEmojis ?? const <String, String>{};

    final selectedName = categoryController.text.trim();

    // ✅ Entry에 저장된 emoji를 가장 우선 사용
    final entryEmoji = item.emoji.trim();

    final selectedEmoji = selectedName.isEmpty
        ? (entryEmoji.isNotEmpty ? entryEmoji : '💰')
        : (entryEmoji.isNotEmpty
        ? entryEmoji
        : (emojiMap[selectedName]?.trim().isNotEmpty ?? false)
        ? emojiMap[selectedName]!.trim()
        : '💰');

    final bool hasInput = selectedName.isNotEmpty ||
        (double.tryParse(_un(amountController.text)) ?? 0.0) > 0.0;

    return PlanCategoryPill(
      text: categoryController.text,
      emoji: selectedEmoji,
      onTap: () {
        debugPrint(
          '[CategorySheet] kind=$kind categories=${allNames.length} ${allNames.take(10).toList()}',
        );

        openPlanCategorySheet(
          context,
          categoryController,
              (val) => onUpdate(item.idx, 'category', val),
          categories: allNames,
          categoryEmojis: emojiMap,
          alreadySelectedNames: alreadySelectedNames,
          currentSelectedName: selectedName,

          onSelectedWithEmoji: (name, emoji) {
            onCategoryAddedWithEmoji?.call(name, emoji);
          },

          onCategoryAdded: (name, emoji) {
            if (onCategoryAddedWithEmoji != null) {
              onCategoryAddedWithEmoji!(name, emoji);
            } else {
              onCategoryAdded?.call(name);
            }
          },

          onCategoryRemoved: onCategoryRemoved,
        );
      },
      onClear: () => onRemove(item.idx),
      highlight: isOverBudget && hasInput,
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

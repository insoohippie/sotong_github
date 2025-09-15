import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/entry.dart';

import '../../../../../component/texts/multi_color_text.dart';
import 'category_utils.dart';

class InputItemDaily extends StatelessWidget {
  final Entry item;
  final TextEditingController categoryController;
  final TextEditingController amountController;
  final void Function(int idx, String field, dynamic value) onUpdate;
  final void Function(int idx) onRemove;
  final int index;

  const InputItemDaily({
    Key? key,
    required this.item,
    required this.categoryController,
    required this.amountController,
    required this.onUpdate,
    required this.onRemove,
    required this.index,
  }) : super(key: key);

  String _unformatNumber(String value) => value.replaceAll(',', '');

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final n = int.tryParse(_unformatNumber(value));
    if (n == null) return '';
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String rawDaily = _unformatNumber(amountController.text);
    final double daily = double.tryParse(rawDaily) ?? 0;
    final int monthly = (daily * 30).round();

    return Container(
      key: ValueKey('item_container_${item.idx}'),
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ▼ 여기만 스와이프 가능
          Dismissible(
            key: ValueKey('dismiss_row_${item.idx}'),
            direction: DismissDirection.endToStart,
            // 한쪽만 원하면 이렇게
            onDismissed: (_) => onRemove(item.idx),
            background: const SizedBox.shrink(),
            secondaryBackground: _buildSwipeBg(
              align: Alignment.centerRight,
              icon: Icons.delete_outline,
              padding: const EdgeInsets.only(right: 16),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CategoryPill(
                    text: categoryController.text,
                    onTap: () =>
                        openCategorySheet(
                          context,
                          item.idx,
                          categoryController,
                              (val) => onUpdate(item.idx, 'category', val),
                        ),
                    onClear: () {
                      categoryController.clear();
                      onUpdate(item.idx, 'category', '');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    controller: amountController,
                    hintText: '(예: 10,000)',
                    keyboardType: TextInputType.number,
                    borderRadius: 10,
                    height: 60,
                    onChanged: (value) {
                      final un = _unformatNumber(value);
                      final amt = double.tryParse(un) ?? 0;
                      onUpdate(item.idx, 'amount', amt);

                      final formatted = _formatNumber(un);
                      if (formatted != value) {
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

          // ▼ 안내문은 고정 (스와이프 영향 없음)
          if (daily > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: MultiColorText(
                baseStyle: const TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
                parts: [
                  const TextPart('30일 기준, 한 달에 ', Color(0xFF8E8E93)),
                  TextPart(
                    '${_formatNumber(monthly.toString())}원',
                    AppColors.primary,
                    bold: true,
                  ),
                  const TextPart(' 이에요.', Color(0xFF8E8E93)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 스와이프 배경
  Widget _buildSwipeBg({
    required Alignment align,
    required IconData icon,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      alignment: align,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
    );
  }

}

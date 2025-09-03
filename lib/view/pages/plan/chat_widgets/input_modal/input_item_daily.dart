import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/entry.dart';

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
    return n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  @override
  Widget build(BuildContext context) {
    final String rawDaily = _unformatNumber(amountController.text);
    final double daily = double.tryParse(rawDaily) ?? 0;
    final int monthly = (daily * 30).round();

    return Container(
      key: ValueKey('item_container_${item.idx}'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 본문
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubText(
                  text: '소비 항목 ${index + 1}', // 👈 번호 표시
                  fontWeight: FontWeight.bold,
                  color: AppColors.subText,
                ),
                const SizedBox(height: 3),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CategoryPill(
                        text: categoryController.text,
                        onTap: () => openCategorySheet(
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
                        height: 50,
                        onChanged: (value) {
                          final un = _unformatNumber(value);
                          final amt = double.tryParse(un) ?? 0;
                          onUpdate(item.idx, 'amount', amt);

                          final formatted = _formatNumber(un);
                          if (formatted != value) {
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

                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SubText(
                      text: '한 달 ${_formatNumber(monthly.toString())}원 소비',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 우상단 삭제 버튼
          Positioned(
            right: 0,
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onRemove(item.idx),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF6B7280),
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

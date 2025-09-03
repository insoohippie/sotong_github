import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/entry.dart';

class InputItemBasic extends StatelessWidget {
  final Entry item;
  final TextEditingController categoryController;
  final TextEditingController amountController;
  final String placeholder;
  final Function(int, String, dynamic) onUpdate;
  final Function(int) onRemove;
  final int index;

  const InputItemBasic({
    Key? key,
    required this.item,
    required this.categoryController,
    required this.amountController,
    required this.placeholder,
    required this.onUpdate,
    required this.onRemove,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hintsForIncome = ['급여', '아르바이트', '용돈'];
    final hintsForFixed = ['월세', '통신비', '구독 서비스'];

    String? categoryHint;
    if (placeholder.contains('수입')) {
      if (index < hintsForIncome.length) {
        categoryHint = '${hintsForIncome[index]}';
      }
    } else if (placeholder.contains('소비 카테고리') || placeholder.contains('고정 소비')) {
      // 네가 써둔 '소비 카테고리' 비교를 유지하면서, 고정 소비 문구도 함께 대응
      if (index < hintsForFixed.length) {
        categoryHint = '${hintsForFixed[index]}';
      }
    }

    String _formatWithComma(String value) {
      if (value.isEmpty) return '';
      final n = int.tryParse(value);
      if (n == null) return '';
      final s = n.toString();
      return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    }


    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 본문
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubText(
                  text: '$placeholder ${index+1}',
                  fontWeight: FontWeight.bold,
                  color: AppColors.subText,
                ),
                const SizedBox(height: 3),
                CustomTextField(
                  controller: categoryController,
                  hintText: categoryHint ?? placeholder,
                  borderRadius: 8,
                  height: 50,
                  onChanged: (v) => onUpdate(item.idx, 'category', v),
                ),
                const SizedBox(height: 6),
                const SubText(
                  text: '금액',
                  fontWeight: FontWeight.bold,
                  color: AppColors.subText,
                ),
                const SizedBox(height: 3),
                CustomTextField(
                  controller: amountController,
                  hintText: '(예: 1,000,000)',
                  keyboardType: TextInputType.number,
                  borderRadius: 8,
                  height: 50,
                  onChanged: (v) {
                    final un = v.replaceAll(',', '');
                    final amt = double.tryParse(un) ?? 0;
                    onUpdate(item.idx, 'amount', amt);
                    final formatted = _formatWithComma(un);
                    if (formatted != v) {
                      amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

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

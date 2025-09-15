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
  final int index; // 사용은 안 하지만 기존 시그니처 유지

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

  String _formatWithComma(String value) {
    if (value.isEmpty) return '';
    final n = int.tryParse(value);
    if (n == null) return '';
    final s = n.toString();
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  @override
  Widget build(BuildContext context) {
    // 힌트 문구는 기존 로직 유지
    final hintsForIncome = ['급여', '아르바이트', '용돈'];
    final hintsForFixed = ['월세', '통신비', '구독 서비스'];
    String? categoryHint;

    if (placeholder.contains('수입')) {
      if (index < hintsForIncome.length) categoryHint = hintsForIncome[index];
    } else if (placeholder.contains('소비 카테고리') || placeholder.contains('고정 소비')) {
      if (index < hintsForFixed.length) categoryHint = hintsForFixed[index];
    }

    return Dismissible(
      key: ValueKey('basic_${item.idx}'),
      direction: DismissDirection.endToStart,
      background: _buildSwipeBg(Alignment.centerRight),
      onDismissed: (_) => onRemove(item.idx),
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // // 상단 라벨(TextField 위) — 유지
              // const SubText(
              //   text: '카테고리',
              //   fontWeight: FontWeight.bold,
              //   color: AppColors.subText,
              // ),
              // const SizedBox(height: 3),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: categoryController,
                  hintText: categoryHint ?? '카테고리',
                  borderRadius: 8,
                  height: 60,
                  onChanged: (v) => onUpdate(item.idx, 'category', v),
                ),
              ),
              const SizedBox(width: 10),
              // const SubText(
              //   text: '금액',
              //   fontWeight: FontWeight.bold,
              //   color: AppColors.subText,
              // ),
              // const SizedBox(height: 3),
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: amountController,
                  hintText: '(예: 1,000,000)',
                  keyboardType: TextInputType.number,
                  borderRadius: 8,
                  height: 60,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBg(AlignmentGeometry align) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment:
        align == Alignment.centerLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: const [
          Icon(Icons.delete_outline, color: Colors.redAccent),
        ],
      ),
    );
  }
}

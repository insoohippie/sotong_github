import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'custom_number_field.dart';
import 'custom_text_field.dart';

/// 소비 입력 레이아웃 컴포넌트
///
/// 1행: 카테고리(왼쪽 flex 2) + 금액(오른쪽 flex 3)
/// 2행: 노트 (전체 너비)
///
/// 홈 소비 기록(SpendingInputEntry) / 수정 모달 등에서 동일 배치로 사용.
class SpendingEntryRow extends StatelessWidget {
  /// 카테고리 표시 텍스트. null이면 "입력"
  final String? categoryLabel;

  /// 카테고리 영역 탭 시 콜백
  final VoidCallback onCategoryTap;

  /// 금액 입력 컨트롤러
  final TextEditingController amountController;

  /// 금액 필드 placeholder (기본: '예) 10,000')
  final String amountHint;

  /// 금액 필드 suffix (기본: '₩')
  final String amountSuffix;

  /// 금액 변경 시 콜백
  final ValueChanged<String>? onAmountChanged;

  /// 노트 입력 컨트롤러
  final TextEditingController noteController;

  /// 노트 필드 placeholder (기본: '노트 작성 (20자 이내)')
  final String noteHint;

  /// 노트 최대 글자 수 (기본: 20)
  final int noteMaxLength;

  /// 노트 변경 시 콜백
  final ValueChanged<String>? onNoteChanged;

  /// 필드 높이 (기본: 60)
  final double fieldHeight;

  /// true면 모든 필드 배경을 회색만 사용 (소비 기록하기 스타일, 입력 시에도 연파랑 X)
  final bool greyBackgroundOnly;

  const SpendingEntryRow({
    super.key,
    required this.categoryLabel,
    required this.onCategoryTap,
    required this.amountController,
    required this.noteController,
    this.amountHint = '예) 10,000',
    this.amountSuffix = '원',
    this.onAmountChanged,
    this.noteHint = '노트 작성 (20자 이내)',
    this.noteMaxLength = 20,
    this.onNoteChanged,
    this.fieldHeight = 60,
    this.greyBackgroundOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1행: 카테고리 + 금액
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onCategoryTap,
                child: Container(
                  height: fieldHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.greyBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color:
                            categoryLabel != null && categoryLabel!.isNotEmpty
                            ? AppColors.primary
                            : AppColors.subText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        categoryLabel != null && categoryLabel!.isNotEmpty
                            ? categoryLabel!
                            : '입력',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              categoryLabel != null && categoryLabel!.isNotEmpty
                              ? Colors.black
                              : AppColors.subText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: CustomNumberField(
                controller: amountController,
                hintText: amountHint,
                backgroundColor: greyBackgroundOnly
                    ? AppColors.greyBackground
                    : null,
                borderRadius: 12,
                height: fieldHeight,
                suffix: amountSuffix,
                onChanged: onAmountChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 2행: 노트
        CustomTextField(
          controller: noteController,
          hintText: noteHint,
          height: fieldHeight,
          backgroundColor: greyBackgroundOnly ? AppColors.greyBackground : null,
          onChanged: (text) {
            if (text.length > noteMaxLength) {
              noteController.text = text.substring(0, noteMaxLength);
              noteController.selection = TextSelection.fromPosition(
                TextPosition(offset: noteController.text.length),
              );
            }
            onNoteChanged?.call(noteController.text);
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

import '../../../../../component/buttons/custom_button.dart';
import '../../../../../component/theme/app_spacing.dart';

class FooterDaily extends StatelessWidget {
  final double total;
  final VoidCallback onComplete;

  const FooterDaily({
    Key? key,
    required this.total,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthly = (total * 30).toInt();
    final targetDate = DateTime(2026, 5, 23); // TODO: 계산 로직 적용
    final targetText = DateFormat('yyyy년 M월 d일').format(targetDate);

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ParagraphText(text: '${NumberFormat('#,###').format(total.toInt())}원', fontWeight: FontWeight.bold),
                        const SubText(text: '일일 총합', fontWeight: FontWeight.bold),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 2, height: 36, color: AppColors.greyBackground),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ParagraphText(text: '${NumberFormat('#,###').format(monthly)}원', fontWeight: FontWeight.bold),
                        const SubText(text: '월별 총합(30일 기준)', fontWeight: FontWeight.bold),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),

          // const SizedBox(height: 10),
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.symmetric(vertical: 10),
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFEFF6FF),
          //     borderRadius: BorderRadius.circular(20),
          //     border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
          //       const SizedBox(width: 6),
          //       SubText(
          //         text: '목표 도달일: $targetText 예정입니다.',
          //         fontWeight: FontWeight.bold,
          //         color: AppColors.primary,
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          CustomButton(text: '완료', onPressed: onComplete)
        ],
      ),
    );
  }

}

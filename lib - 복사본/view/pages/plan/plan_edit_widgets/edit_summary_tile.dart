import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../component/texts/paragraph_text.dart';
import '../../../../component/texts/subtext.dart';
import '../../../../component/theme/app_colors.dart';

class EditSummaryTile extends StatelessWidget {
  final String label;
  final double total;
  final VoidCallback onEdit;
  final String? unit;       // 기본 '원'
  final String? subtitle;   // 선택 설명 텍스트

  const EditSummaryTile({
    Key? key,
    required this.label,
    required this.total,
    required this.onEdit,
    this.unit,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat('#,###').format(total.toInt());

    return Padding(
      // MinimalField와 동일: 위아래 6px 패딩
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라벨(SubText)
          SubText(
            text: label,
            fontWeight: FontWeight.bold,
            color: AppColors.subText,
          ),
          // MinimalField와 동일: 라벨 아래 8px 간격
          const SizedBox(height: 8),

          // 본문 컨테이너(높이 60, 좌우 패딩 20, 모서리 12)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ParagraphText(
                  text: '$formattedTotal${unit ?? '원'}',
                  color: Colors.black,
                ),
                TextButton(
                  onPressed: onEdit,
                  child: const Text(
                    '세부 수정',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Divider(height: 2, color:AppColors.greyBackground, )

        ],
      ),
    );
  }
}

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
          const SizedBox(height: 8),

          // ✅ 컨테이너 전체 탭 → onEdit 실행
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onEdit,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ParagraphText(
                      text: '$formattedTotal${unit ?? '원'}',
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 5, color: AppColors.greyBackground),
        ],
      ),
    );
  }
}
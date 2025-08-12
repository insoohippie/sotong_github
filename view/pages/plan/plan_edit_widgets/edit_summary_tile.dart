import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../component/texts/paragraph_text.dart';
import '../../../../component/texts/subtext.dart';
import '../../../../component/theme/app_colors.dart';

class EditSummaryTile extends StatelessWidget {
  final String label;
  final double total;
  final VoidCallback onEdit;
  final String? unit; // 기본 '원'
  final String? subtitle; // 선택 설명 텍스트
  final bool tappable; // 타일 전체 탭 가능 여부

  const EditSummaryTile({
    Key? key,
    required this.label,
    required this.total,
    required this.onEdit,
    this.unit,
    this.subtitle,
    this.tappable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat('#,###').format(total.toInt());

    final content = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubText(text: label, fontWeight: FontWeight.w600), // 컨테이너 밖으로
                ParagraphText(
                  text: '$formattedTotal${unit ?? '원'}',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ],
            ),
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
    );

    return tappable
        ? InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onEdit,
            child: content,
          )
        : content;
  }
}

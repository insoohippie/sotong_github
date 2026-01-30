import 'package:flutter/material.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_text_styles.dart';

class CategoryPlanProgressBox extends StatelessWidget {
  final int dailyLimitSum;
  final DateTime? reachDate;

  const CategoryPlanProgressBox({
    super.key,
    required this.dailyLimitSum,
    required this.reachDate,
  });

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    )}원';
  }

  @override
  Widget build(BuildContext context) {
    if (dailyLimitSum <= 0 || reachDate == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('일일 한도 합계 ', style: AppTextStyles.subtext.copyWith(color: AppColors.text)),
              Text(
                _formatAmount(dailyLimitSum),
                style: AppTextStyles.paragraph.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${reachDate!.year}년 ${reachDate!.month}월 ${reachDate!.day}일 도달예정',
            textAlign: TextAlign.center,
            style: AppTextStyles.paragraph.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

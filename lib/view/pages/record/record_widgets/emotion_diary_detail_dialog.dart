import 'package:flutter/material.dart';
import 'package:sotong_local/model/emotion_spending_diary.dart';
import 'package:lottie/lottie.dart';

import '../../../../component/theme/app_colors.dart';

class EmotionDiaryDetailDialog extends StatelessWidget {
  final EmotionSpendingDiary diary;
  final DateTime selectedDate;

  const EmotionDiaryDetailDialog({
    super.key,
    required this.diary,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDate.month}월 ${selectedDate.day}일',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 감정 애니메이션
            Container(
              width: 80,
              height: 80,
              child: Lottie.asset(
                'assets/animations/${diary.emotionAnimation}',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),

            // 감정 텍스트
            Text(
              diary.emotion,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // 소비 정보
            _buildInfoRow(
              '소비 금액',
              '${diary.spendingAmount.toStringAsFixed(0)}원',
            ),
            const SizedBox(height: 12),
            _buildInfoRow('소비 내용', diary.spendingDescription),
            if (diary.memo.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow('메모', diary.memo),
            ],
            const SizedBox(height: 24),

            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '닫기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

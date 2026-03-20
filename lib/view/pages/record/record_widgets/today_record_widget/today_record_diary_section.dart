import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../view_model/record/today_spending_view_model.dart';

class TodayRecordDiarySection extends StatelessWidget {
  final TodaySpendingViewModel vm;
  final VoidCallback onEdit;

  const TodayRecordDiarySection({
    super.key,
    required this.vm,
    required this.onEdit,
  });

  static String _emotionToLottie(String emotion) {
    switch (emotion) {
      case '기쁨':
        return 'assets/animations/Great.json';
      case '슬픔':
        return 'assets/animations/Sad.json';
      case '화남':
        return 'assets/animations/Angry.json';
      case '짜증':
        return 'assets/animations/Annoyed.json';
      case '평온':
        return 'assets/animations/Calm.json';
      case '스트레스':
        return 'assets/animations/Stress.json';
      default:
        return 'assets/animations/Great.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '오늘의 감정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.edit,
                          color: Color(0xFF9E9E9E), size: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Lottie.asset(
                      _emotionToLottie(vm.emotion),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vm.emotion.isEmpty ? '😊 감정 미기록' : '😊 ${vm.emotion}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '소비일지',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Text(
                vm.comment.isEmpty ? '오늘의 소비일지가 없어요.' : vm.comment,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
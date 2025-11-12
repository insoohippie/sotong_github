import 'package:flutter/material.dart';
import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

class PeriodSuccessPage extends StatelessWidget {
  const PeriodSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: '', onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 달력 아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 첫 번째 텍스트 블록
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard Variable',
                          color: Colors.black,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(text: '1,000,000원을\n'),
                          TextSpan(text: '기간에 반영했어요!'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 두 번째 텍스트 블록
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard Variable',
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: '추가 입금액으로\n'),
                          TextSpan(text: '목표금액 달성이 '),
                          TextSpan(
                            text: '30일',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          TextSpan(text: ' 앞당겨졌어요!'),
                        ],
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),

            // 네비게이션 바에 고정된 확인 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              decoration: const BoxDecoration(color: Colors.white),
              child: Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  child: const Text('확인했어요'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

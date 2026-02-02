import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../model/setting/past_plan_snapshot.dart';
import '../../../repository/past_plan_repository.dart';

class CelebrationPlanSuccessPage extends StatefulWidget {
  final String? planName;
  final int? daysTaken;

  /// 전달되면 이 스냅샷을 지난 플랜으로 저장 (설정 > 지난 플랜 돌아보기에서 확인 가능)
  final PastPlanSnapshot? snapshot;

  const CelebrationPlanSuccessPage({
    super.key,
    this.planName,
    this.daysTaken,
    this.snapshot,
  });

  @override
  State<CelebrationPlanSuccessPage> createState() =>
      _CelebrationPlanSuccessPageState();
}

class _CelebrationPlanSuccessPageState
    extends State<CelebrationPlanSuccessPage> {
  @override
  void initState() {
    super.initState();
    if (widget.snapshot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PastPlanRepository().add(widget.snapshot!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPlanName = widget.planName ?? '플랜';
    final displayDays = widget.daysTaken ?? 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 150,
                    height: 159,
                    child: Lottie.asset(
                      'assets/animations/confetti-bird.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 150,
                          height: 159,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.celebration,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '성공적으로 $displayDays일 만에\n$displayPlanName 플랜을 완성했어요!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: CustomButton(
                  text: '나의 기록 돌아보기',
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/total_plan');
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../model/setting/past_plan_snapshot.dart';
import '../../../repository/past_plan_repository.dart';
import '../../../view_model/home/home_view_model.dart';

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

  Future<void> _goHome() async {
    await context.read<HomeViewModel>().dismissPlanCelebration();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home_tab_navigator',
      (_) => false,
      arguments: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final celebrationMessage = context.watch<HomeViewModel>().planCelebrationMessage;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: BackOnlyAppBar(onBack: _goHome),
        body: Column(
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
                  celebrationMessage,
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
    );
  }
}

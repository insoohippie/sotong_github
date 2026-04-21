import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

class UnsuccessPlanQuitPage extends StatelessWidget {
  const UnsuccessPlanQuitPage({super.key, this.onCreatePlan});

  final VoidCallback? onCreatePlan;

  double _authHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 320) return 16;
    if (width <= 360) return 18;
    if (width <= 390) return 20;
    if (width <= 430) return 24;
    if (width < 768) return 28;
    return 40;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _authHorizontalPadding(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const BackOnlyAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: const _WelcomeTexts(),
                  ),
                  const Spacer(),
                  CustomButton(
                    text: '플랜 만들기',
                    onPressed: onCreatePlan ?? () {},
                  ),
                  const SizedBox(height: AppSpacing.bottomSpacing),
                ],
              ),
            ),
            const Positioned.fill(
              child: Center(child: _CheckSettingAnimation()),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeTexts extends StatelessWidget {
  const _WelcomeTexts();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        _WelcomeTitle(),
        SizedBox(height: 24),
        Text(
          '다시 만나서 반가워요.\n플랜을 아직 완성하지 않으셨네요,\n이어서 만들어볼까요?',
          style: TextStyle(
            fontSize: 17,
            height: 1.25,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _WelcomeTitle extends StatelessWidget {
  const _WelcomeTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 46 / 2,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: '안녕하세요, '),
          TextSpan(
            text: '회원님!',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _CheckSettingAnimation extends StatelessWidget {
  const _CheckSettingAnimation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Lottie.asset(
        'assets/animations/Verify.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

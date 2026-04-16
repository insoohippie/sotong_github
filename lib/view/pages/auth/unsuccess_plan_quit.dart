import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../repository/auth_repository.dart';

class UnsuccessPlanQuitPage extends StatelessWidget {
  const UnsuccessPlanQuitPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: FutureBuilder<String>(
                      future: context.read<AuthRepository>().getUserName(),
                      builder: (context, snapshot) {
                        final userName =
                        (snapshot.data?.trim().isNotEmpty ?? false)
                            ? snapshot.data!.trim()
                            : '회원';

                        return _WelcomeTexts(userName: userName);
                      },
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    text: '플랜 만들기',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/plan_chat');
                    },
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
  const _WelcomeTexts({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _WelcomeTitle(userName: userName),
        const SizedBox(height: 24),
        const Text(
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
  const _WelcomeTitle({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 46 / 2,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
        children: [
          const TextSpan(text: '안녕하세요, '),
          TextSpan(
            text: '$userName님!',
            style: const TextStyle(color: AppColors.primary),
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
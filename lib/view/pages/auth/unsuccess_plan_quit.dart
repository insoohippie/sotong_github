import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../repository/auth_repository.dart';

class UnsuccessPlanQuitPage extends StatelessWidget {
  const UnsuccessPlanQuitPage({super.key});

  double _authHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 320) return 16;
    if (width <= 360) return 18;
    if (width <= 390) return 20;
    if (width <= 430) return 24;
    if (width < 768) return 28;
    return 40;
  }

  void _goLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _authHorizontalPadding(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goLogin(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => _goLogin(context),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                        Navigator.of(context)
                            .pushReplacementNamed('/plan_chat');
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
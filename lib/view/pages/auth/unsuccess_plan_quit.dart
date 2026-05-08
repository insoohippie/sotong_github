import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';
import '../../../component/theme/padding/vertical_section_spacing_ref_height_600.dart';
import '../../../repository/auth_repository.dart';

const _kUnsuccessSectionMins = <double>[12, 100];

class UnsuccessPlanQuitPage extends StatelessWidget {
  const UnsuccessPlanQuitPage({super.key});

  void _goLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = PaddingResponsive16_40Vw.horizontal(
      context,
      PaddingResponsive16_40Vw.fractionScreen075,
    );
    final sectionGaps = SectionGapRefHeight600.scaledMinsFromContext(
      context,
      minGaps: _kUnsuccessSectionMins,
    );

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: sectionGaps[0]),
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
                  },
                ),
              ),
              SizedBox(height: sectionGaps[1]),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CheckSettingAnimation(),
                ],
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: CustomButton(
                  padding: EdgeInsets.zero,
                  text: '플랜 만들기',
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/plan_chat');
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

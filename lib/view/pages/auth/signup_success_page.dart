import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';
import '../../../component/theme/padding/vertical_section_spacing_ref_height_600.dart';
import '../../../view_model/auth/signup_view_model.dart';

const _kSignupSuccessSectionMins = <double>[12, 100];

class SignupSuccessPage extends StatelessWidget {
  const SignupSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    final nickname = vm.signUpInfo?.nickname.trim().isNotEmpty == true
        ? vm.signUpInfo!.nickname.trim()
        : '사용자';

    final viewWidth = MediaQuery.sizeOf(context).width;
    final successHeaderBase = viewWidth < 360
        ? AppTextStyles.header.copyWith(fontSize: 24)
        : AppTextStyles.header;

    final horizontalPadding = PaddingResponsive16_40Vw.horizontal(
      context,
      PaddingResponsive16_40Vw.fractionScreen075,
    );

    final sectionGaps = SectionGapRefHeight600.scaledMinsFromContext(
      context,
      minGaps: _kSignupSuccessSectionMins,
    );

    final List<TextPart> messageHeaderParts = [
      TextPart(nickname, AppColors.primary),
      TextPart('님,\n', AppColors.text),
      TextPart('회원가입을 축하드려요!', AppColors.text),
    ];

    final List<TextPart> messageParagraphParts = [
      TextPart('소비통제를 위한 나만의 계획,\n', AppColors.text),
      TextPart('소통 플랜', AppColors.primary, bold: true),
      TextPart('을 만들러 가볼까요?\n플랜은 소통이가 도와줘요!', AppColors.text),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: kToolbarHeight,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: sectionGaps[0]),
                  MultiColorText(
                    baseStyle: successHeaderBase,
                    parts: messageHeaderParts,
                  ),
                  const SizedBox(height: 24),
                  MultiColorText(
                    baseStyle: AppTextStyles.paragraph.copyWith(fontSize: 18),
                    parts: messageParagraphParts,
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGaps[1]),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SignupVerifyLottie(),
              ],
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: CustomButton(
                padding: EdgeInsets.zero,
                text: '좋아요!',
                onPressed: () async {
                  Navigator.pushNamed(context, '/plan_chat');
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

class _SignupVerifyLottie extends StatelessWidget {
  const _SignupVerifyLottie();

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
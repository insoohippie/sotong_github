import 'package:flutter/material.dart';
import '../../../component/appbars/back_only_app_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../view_model/auth/signup_view_model.dart';

class SignupSuccessPage extends StatelessWidget {
  const SignupSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final userName = vm.signUpInfo?.name ?? '사용자';

    final List<TextPart> messageHeaderParts = [
      TextPart('$userName', AppColors.primary),
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
      appBar: BackOnlyAppBar(
        onBack: () {
          if (vm.currentStep == SignupStep.email) {
            Navigator.pop(context);
          } else {
            vm.previousStep();
          }
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    MultiColorText(
                      baseStyle: AppTextStyles.header,
                      parts: messageHeaderParts,
                    ),
                    const SizedBox(height: 24),
                    MultiColorText(
                      baseStyle: AppTextStyles.paragraph.copyWith(fontSize: 18),
                      parts: messageParagraphParts,
                    ),
                    Center(
                      child: SizedBox(
                        height: 300,
                        child: Lottie.asset('assets/animations/Verify.json'),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            CustomButton(
              text: '좋아요!',
              onPressed: () async {
                Navigator.pushNamed(context, '/plan_chat');
              },
            ),
            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }
}

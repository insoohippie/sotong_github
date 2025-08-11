import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../view_model/auth/signup_view_model.dart';

class PlanSuccessPage extends StatelessWidget {
  const PlanSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final userName = vm.signUpInfo?.name ?? '사용자';

    final List<TextPart> messageHeaderParts = [
      TextPart('$userName', AppColors.primary, bold: true),
      TextPart('님을 위한\n플랜이 생성되었어요! 🎉', AppColors.text),
    ];

    final List<TextPart> messageParagraphParts1 = [
      TextPart('2025년 ', AppColors.text), // 시작 년도
      TextPart('1월 1일', AppColors.primary), // 시작 일자
      TextPart('부터\n2025년 ', AppColors.text),
      TextPart('6월 30일', AppColors.primary), // 끝나는 일자
      TextPart('까지\n\n', AppColors.text),
      TextPart('하루 소비한도 금액은\n', AppColors.text, bold: true),
      TextPart('7000원', AppColors.primary, bold: true), //하루 소비한도 금액
      TextPart('입니다.', AppColors.text, bold: true),
    ];

    final List<TextPart> messageParagraphParts2 = [
      TextPart('2025년 6월 30일에\n', AppColors.text),
      TextPart('87만원', AppColors.primary), // 시작 일자
      TextPart('이 모여요!', AppColors.text),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: '', onBack: () => Navigator.pop(context)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MultiColorText(
                      baseStyle: AppTextStyles.header,
                      parts: messageHeaderParts,
                    ),
                    const SizedBox(height: 24),
                    RoundedInfoContainer(
                      child: Row(
                        children: [
                          Expanded(
                            child: MultiColorText(
                              baseStyle: AppTextStyles.paragraph,
                              parts: messageParagraphParts1,
                            ),
                          ),
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    RoundedInfoContainer(
                      child: Row(
                        children: [
                          Expanded(
                            child: MultiColorText(
                              baseStyle: AppTextStyles.paragraph,
                              parts: messageParagraphParts2,
                            ),
                          ),
                          const Icon(
                            Icons.savings_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomButton(
              text: '다음',
              onPressed: () {
                Navigator.pushNamed(context, '/home_tab_navigator');
              },
            ),
            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }
}

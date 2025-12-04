import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/texts/header_text.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../view_model/auth/login_view_model.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';

class EmailLoginPage extends StatelessWidget {
  const EmailLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MultiColorText(
                      baseStyle: AppTextStyles.header,
                      parts: const [
                        TextPart('재미있게 ', Colors.black),
                        TextPart('소통', AppColors.primary),
                        TextPart('하며\n',Colors.black),
                        TextPart('소', AppColors.primary),
                        TextPart('비 ', Colors.black),
                        TextPart('통', AppColors.primary),
                        TextPart('제 하자!', Colors.black),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: AppSpacing.fieldSpacing),
                    CustomTextField(
                      controller: vm.emailController,
                      hintText: '이메일 입력',
                      onChanged: (_) => vm.notifyListeners(),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: vm.passwordController,
                      hintText: '비밀번호 입력',
                      onChanged: (_) => vm.notifyListeners(),
                      obscureText: true,
                    ),
                                               const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 에러 메시지 (왼쪽 정렬)
                        if (vm.errorMessage != null)
                          Text(
                            '• ${vm.errorMessage}',
                            style: AppTextStyles.errorText,
                          )
                        else
                          const SizedBox(), // 에러 없을 때 공간 유지
                        // 회원가입 버튼 (오른쪽 정렬)
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0062FF),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // 로그인 버튼 + 로딩 인디케이터
            vm.isLoading
                ? const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : CustomButton(
                    text: '로그인',
                    onPressed: () async {
                      final success = await vm
                          .login(); // ← ViewModel에서 true/false 리턴

                      if (success) {
                        await context.read<ChatPlanViewModel>().loadRemoteRefData();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            '/home_tab_navigator',
                          );
                        }
                      }
                      // 실패 시 에러 메시지는 ViewModel에서 처리되고 화면에 표시됨
                    },
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

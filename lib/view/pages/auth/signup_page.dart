import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/wrappers/keyboard_dismiss_scope.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/texts/header_text.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';
import '../../../view_model/auth/signup_view_model.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final vm = context.read<SignupViewModel>();
      vm.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    final horizontalPadding = PaddingResponsive16_40Vw.horizontal(
      context,
      PaddingResponsive16_40Vw.fractionScreen075,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
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
        child: KeyboardDismissScope(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ).copyWith(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vm.currentStep == SignupStep.email)
                        _buildIdField(vm),
                      if (vm.currentStep == SignupStep.password)
                        _buildPasswordField(vm),
                      if (vm.currentStep == SignupStep.userInfo)
                        _buildNicknameField(vm),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.bottomSpacing,
            horizontalPadding,
            AppSpacing.bottomSpacing,
          ),
          child: CustomButton(
            padding: EdgeInsets.zero,
            text: vm.currentStep == SignupStep.userInfo ? '회원가입 완료' : '다음',
            enabled: vm.isCurrentStepValid && !vm.isLoading,
            onPressed: () async {
              if (vm.currentStep == SignupStep.userInfo && vm.canSubmit) {
                final success = await vm.submit();

                if (success && context.mounted) {
                  Navigator.pushNamed(context, '/signup_success');
                }
              } else {
                await vm.nextStep();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIdField(SignupViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: '아이디를 입력하세요'),
        SizedBox(height: AppSpacing.fieldSpacing),
        CustomTextField(
          controller: vm.emailController,
          hintText: 'ex. sotong_123',
          keyboardType: TextInputType.text,
          onChanged: (_) => vm.notifyListeners(),
        ),
        SizedBox(height: AppSpacing.itemSpacing),
        if (vm.emailError != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '• ${vm.emailError}',
              style: AppTextStyles.errorText,
            ),
          )
        else if (vm.isEmailChecked)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '• 사용 가능한 아이디입니다',
              style: AppTextStyles.infoText,
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField(SignupViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: '비밀번호를 설정해주세요'),
        SizedBox(height: AppSpacing.fieldSpacing),
        CustomTextField(
          controller: vm.passwordController,
          hintText: '6자 이상 입력',
          obscureText: !vm.isPasswordVisible,
          onChanged: (_) => vm.notifyListeners(),
          suffix: IconButton(
            icon: Icon(
              vm.isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: vm.togglePasswordVisibility,
          ),
        ),
        SizedBox(height: AppSpacing.itemSpacing),
        if (!vm.isPasswordValid && vm.passwordController.text.isNotEmpty)
          ...vm.passwordErrors.map(
                (msg) => Text(
              '• $msg',
              style: AppTextStyles.errorText,
            ),
          ),
        SizedBox(height: AppSpacing.fieldSpacing),
        CustomTextField(
          controller: vm.passwordConfirmController,
          hintText: '비밀번호 다시 입력',
          obscureText: !vm.isPasswordConfirmVisible,
          onChanged: (_) => vm.notifyListeners(),
          suffix: IconButton(
            icon: Icon(
              vm.isPasswordConfirmVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: vm.togglePasswordConfirmVisibility,
          ),
        ),
        SizedBox(height: AppSpacing.itemSpacing),
        if (vm.passwordConfirmError != null)
          Text(
            '• ${vm.passwordConfirmError}',
            style: AppTextStyles.errorText,
          )
        else if (vm.passwordConfirmController.text.isNotEmpty &&
            vm.isPasswordConfirmValid)
          Text(
            '• 비밀번호가 일치합니다',
            style: AppTextStyles.infoText,
          ),
      ],
    );
  }

  Widget _buildNicknameField(SignupViewModel vm) {
    final nicknameError = vm.validateNickname(vm.nicknameController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: '닉네임을 입력하세요'),
        SizedBox(height: AppSpacing.fieldSpacing),
        CustomTextField(
          controller: vm.nicknameController,
          hintText: 'ex. 소통이',
          keyboardType: TextInputType.text,
          onChanged: (_) => vm.notifyListeners(),
        ),
        SizedBox(height: AppSpacing.itemSpacing),
        if (nicknameError != null && vm.nicknameController.text.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '• $nicknameError',
              style: AppTextStyles.errorText,
            ),
          ),
      ],
    );
  }
}
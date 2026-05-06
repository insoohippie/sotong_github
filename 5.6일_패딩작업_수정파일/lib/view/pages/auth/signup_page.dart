import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../component/appbars/back_only_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/texts/header_text.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/view/pages/auth/signup_success_page.dart';

import '../../../component/inputs/custom_text_field.dart';
import '../../../component/inputs/dual_option_selector.dart';
import '../../../component/inputs/wheel_date_picker.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../view_model/auth/signup_view_model.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';

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
    final horizontalPadding =
        PaddingResponsive16_40Vw.horizontal(
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ).copyWith(bottom: 120),
                child: Column(
                  children: [
                    if (vm.currentStep == SignupStep.email)
                      _buildIdField(vm),
                    if (vm.currentStep == SignupStep.password)
                      _buildPasswordField(vm),
                    if (vm.currentStep == SignupStep.userInfo)
                      _buildUserInfoField(context, vm),
                  ],
                ),
              ),
            ),
          ],
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
            enabled: vm.isCurrentStepValid,
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
            child: Text('• ${vm.emailError}', style: AppTextStyles.errorText),
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
          hintText: '8자리 이상 숫자, 특수문자, 대문자',
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
                (msg) => Text('• $msg', style: AppTextStyles.errorText),
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

  Widget _buildUserInfoField(BuildContext context, SignupViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: '아래 정보만 입력하면'),
        HeaderText(text: '회원가입 완료!'),
        SizedBox(height: AppSpacing.sectionSpacing),

        ParagraphText(text: '이름'),
        SizedBox(height: AppSpacing.itemSpacing),
        CustomTextField(
          controller: vm.nameController,
          hintText: '이름 입력',
          onChanged: (_) => vm.notifyListeners(),
        ),

        SizedBox(height: AppSpacing.fieldSpacing),

        ParagraphText(text: '생년월일'),
        SizedBox(height: AppSpacing.itemSpacing),
        WheelDateSelector(
          selectedDate: vm.birthdayController.text,
          hintText: '생년월일을 선택하세요',
          onDateSelected: (value) {
            vm.setBirthdayFromCupertino(value);
          },
        ),

        SizedBox(height: AppSpacing.fieldSpacing),

        ParagraphText(text: '성별'),
        SizedBox(height: AppSpacing.itemSpacing),
        DualOptionSelector(
          selectedOption: vm.gender,
          option1: '남자',
          option2: '여자',
          onSelected: vm.setGender,
        ),
      ],
    );
  }
}
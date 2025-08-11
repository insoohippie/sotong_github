import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_model/plan/enums/chat_step.dart';
import './purpose_selector_widget.dart';
import '../../../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../../component/buttons/custom_button.dart';
import '../../../../component/buttons/custom_dual_button.dart';
import '../../../../component/inputs/custom_text_field.dart';

class ChatBottomInputArea extends StatelessWidget {
  final bool animDone;
  final VoidCallback showIncomeModal;
  final VoidCallback showFixedCostModal;
  final VoidCallback showDailySpendingModal;
  final TextEditingController inputController;
  final bool isFormatting;
  final void Function(String) onInputChanged;
  final VoidCallback onSubmit;
  final VoidCallback onDisappear;
  final bool lastIsBot;

  const ChatBottomInputArea({
    super.key,
    required this.animDone,
    required this.showIncomeModal,
    required this.showFixedCostModal,
    required this.showDailySpendingModal,
    required this.inputController,
    required this.isFormatting,
    required this.onInputChanged,
    required this.onSubmit,
    required this.lastIsBot,
    required this.onDisappear,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatPlanViewModel>();
    final currentStep = viewModel.currentStep;

    final isTextInputStep =
        animDone &&
        !viewModel.isTyping &&
        _isChatInputEnabled(currentStep) &&
        currentStep != ChatStep.onboarding1 &&
        currentStep != ChatStep.onboarding2 &&
        currentStep != ChatStep.onboarding3;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isTextInputStep && animDone && !viewModel.buttonClicked)
            switch (currentStep) {
              ChatStep.onboarding1 => CustomButton(
                text: '소통에 대해 더 알아볼래요',
                onPressed: () {
                  viewModel.handleUserResponse('소통에 대해 더 알아볼래요');
                  onDisappear();
                },
              ),
              ChatStep.onboarding2 => CustomButton(
                text: '너무 신기해요!',
                onPressed: () {
                  viewModel.handleUserResponse('너무 신기해요!');
                  onDisappear();
                },
              ),
              ChatStep.onboarding3 => CustomButton(
                text: '좋아요, 시작할게요!',
                onPressed: () {
                  viewModel.handleUserResponse('좋아요, 시작할게요!');
                  onDisappear();
                },
              ),
              _ => const SizedBox.shrink(),
            },

          if (currentStep == ChatStep.greeting && animDone)
            CustomButton(
              text: '좋아요! 시작할게요',
              onPressed: () {
                viewModel.handleUserResponse('좋아요! 시작할게요');
                onDisappear();
              },
            ),

          if (currentStep == ChatStep.currentAsset && animDone)
            CustomDualButton(
              leftLabel: '없어요',
              rightLabel: '있어요',
              onLeftPressed: () {
                viewModel.handleUserResponse('없어요');
                onDisappear();
              },
              onRightPressed: () {
                viewModel.handleUserResponse('있어요');
                onDisappear();
              },
            ),

          if (currentStep == ChatStep.monthlyIncome)
            CustomButton(
              text: '월 수입 입력하러가기',
              onPressed: () {
                showIncomeModal();
                onDisappear();
              },
            ),

          if (currentStep == ChatStep.monthlyFixedCost)
            CustomButton(
              text: '고정 소비 입력하러가기',
              onPressed: () {
                showFixedCostModal();
                onDisappear();
              },
            ),

          if (currentStep == ChatStep.dailySpending)
            CustomButton(
              text: '하루 소비 한도 금액 입력하러가기',
              onPressed: () {
                showDailySpendingModal();
                onDisappear();
              },
            ),

          if (currentStep == ChatStep.summary && animDone)
            CustomButton(
              text: '다음 단계로',
              onPressed: () {
                viewModel.handleUserResponse('다음 단계로');
                onDisappear();
              },
            ),

          if (currentStep == ChatStep.autoService && animDone)
            CustomButton(
              text: '네! 좋아요',
              onPressed: () {
                viewModel.handleUserResponse('네! 좋아요');
                onDisappear();
              },
            ),

          if (currentStep == ChatStep.complete && animDone)
            CustomButton(
              text: '홈으로 이동',
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home_tab_navigator',
                  (route) => false,
                );
              },
            ),

          if (currentStep == ChatStep.purpose && animDone)
            PurposeSelectorWidget(
              options: viewModel.purposeOptions,
              onSelect: (value) {
                viewModel.handleUserResponse(value);
                onDisappear();
              },
            ),

          if (isTextInputStep)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: CustomTextField(
                    controller: inputController,
                    hintText: currentStep == ChatStep.planName
                        ? '플랜 이름을 입력하세요'
                        : currentStep == ChatStep.targetAmount
                        ? '목표 금액을 입력하세요'
                        : currentStep == ChatStep.currentAssetConfirm
                        ? '보유 금액을 입력하세요'
                        : currentStep == ChatStep.purposeCustom
                        ? '목적을 입력하세요'
                        : '메시지를 입력하세요',
                    keyboardType: currentStep == ChatStep.targetAmount
                        ? TextInputType.number
                        : TextInputType.text,
                    onChanged: onInputChanged,
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: _getButtonText(currentStep, inputController.text),
                  onPressed:
                      isTextInputStep &&
                          _isValidInput(currentStep, inputController.text)
                      ? () {
                          onDisappear();
                          onSubmit();
                        }
                      : () {},
                  enabled:
                      isTextInputStep &&
                      _isValidInput(currentStep, inputController.text),
                ),
              ],
            ),
        ],
      ),
    );
  }

  bool _isChatInputEnabled(ChatStep step) {
    return [
      ChatStep.planName,
      ChatStep.targetAmount,
      ChatStep.currentAssetConfirm,
      ChatStep.purposeCustom,
    ].contains(step);
  }

  String _getButtonText(ChatStep step, String inputText) {
    final isEmpty = inputText.trim().isEmpty;
    if (isEmpty) {
      return step == ChatStep.planName
          ? '플랜 이름을 입력해주세요!'
          : step == ChatStep.targetAmount
          ? '목표 금액을 입력해주세요!'
          : step == ChatStep.currentAssetConfirm
          ? '보유 금액을 입력해주세요!'
          : step == ChatStep.purposeCustom
          ? '목적을 입력해주세요!'
          : '입력해주세요!';
    }
    return step == ChatStep.planName
        ? '이 이름으로 플랜 만들래요!'
        : step == ChatStep.targetAmount
        ? '제 목표 금액이에요!'
        : step == ChatStep.currentAssetConfirm
        ? '현재 자산은 이만큼이에요!'
        : step == ChatStep.purposeCustom
        ? '이 목적으로 설정할게요!'
        : '입력 완료!';
  }

  bool _isValidInput(ChatStep step, String inputText) {
    final trimmedText = inputText.trim();

    if (trimmedText.isEmpty) return false;

    switch (step) {
      case ChatStep.planName:
      case ChatStep.purposeCustom:
        return trimmedText.length >= 2;
      case ChatStep.targetAmount:
        final amountStr = trimmedText.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        return amount != null && amount > 0;
      case ChatStep.currentAssetConfirm:
        final assetStr = trimmedText.replaceAll(',', '');
        final assetAmount = double.tryParse(assetStr);
        return assetAmount != null;
      default:
        return true;
    }
  }
}

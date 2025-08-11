import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './purpose_selector_widget.dart';
import '../../../../../enums/chat_step.dart';
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
                        : '메시지를 입력하세요',
                    keyboardType: currentStep == ChatStep.targetAmount
                        ? TextInputType.number
                        : TextInputType.text,
                    onChanged: onInputChanged,
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: currentStep == ChatStep.planName
                      ? '이 이름으로 플랜 만들래요!'
                      : currentStep == ChatStep.targetAmount
                      ? '제 목표 금액이에요!'
                      : currentStep == ChatStep.currentAssetConfirm
                      ? '현재 자산은 이만큼이에요!'
                      : '입력 완료!',
                  onPressed: isTextInputStep
                      ? () {
                          onDisappear();
                          onSubmit();
                        }
                      : () {},
                  enabled: isTextInputStep,
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
    ].contains(step);
  }
}

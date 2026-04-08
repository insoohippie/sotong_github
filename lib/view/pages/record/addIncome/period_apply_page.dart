import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../component/theme/app_colors.dart';
import '../../../../../component/theme/app_spacing.dart';
import '../../../../../view_model/record/record_add_income_view_model.dart';
import '../../../../record_flow_navigation.dart';

class PeriodApplyPage extends StatefulWidget {
  const PeriodApplyPage({super.key});

  @override
  State<PeriodApplyPage> createState() => _PeriodApplyPageState();
}

class _PeriodApplyPageState extends State<PeriodApplyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RecordAddIncomeViewModel>();
      vm.applyIncomeToPeriod();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordAddIncomeViewModel>();
    final amount = vm.appliedAmountText;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sectionSpacing2),
              if (vm.isApplyingPeriod) ...[
                const Spacer(),
                _buildLoading(),
                const Spacer(),
              ] else if (vm.applyPeriodError != null) ...[
                const Spacer(),
                _buildError(vm.applyPeriodError!),
                const Spacer(),
                _buildErrorButtons(vm),
              ] else ...[
                const Spacer(),
                _buildResult(amount, vm.daysReducedText),
                const Spacer(),
                _buildConfirmButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        const Text(
          '기간에 반영하는 중이에요...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorButtons(RecordAddIncomeViewModel vm) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              vm.applyPeriodError = null;
              vm.applyIncomeToPeriod();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('다시 시도하기'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildResult(String amount, String daysReducedText) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.calendar_today,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing2),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
            children: [
              TextSpan(text: '$amount을 '),
              const TextSpan(
                text: '기간에 반영했어요!',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: '추가 입금액으로 목표금액 달성이 '),
              TextSpan(
                text: daysReducedText,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' 앞당겨졌어요!'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          final raw = ModalRoute.of(context)?.settings.arguments;
          final returnToPending =
              raw is Map && raw['returnToPending'] == true;
          finishRecordFlowToHomeOrPending(
            context,
            returnToPending: returnToPending,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('확인했어요'),
      ),
    );
  }
}
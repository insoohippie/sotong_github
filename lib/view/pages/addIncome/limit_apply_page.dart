import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../component/theme/app_colors.dart';
import '../../../../../component/theme/app_spacing.dart';
import '../../../view_model/addIncome/add_income_view_model.dart';

class LimitApplyPage extends StatefulWidget {
  const LimitApplyPage({super.key});

  @override
  State<LimitApplyPage> createState() => _LimitApplyPageState();
}

class _LimitApplyPageState extends State<LimitApplyPage> {
  @override
  void initState() {
    super.initState();

    // 화면 들어오자마자 한도 반영 로직 실행
    Future.microtask(() {
      final vm = context.read<AddIncomeViewModel>();
      vm.applyIncomeToLimit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddIncomeViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: vm.isApplyingLimit
              ? _buildLoading()
              : _buildResult(context, vm),
        ),
      ),
    );
  }

  /// 로딩 화면 (한도 계산/반영 중)
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
          '소비 한도를 계산하고 있어요',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '잠시만 기다려 주세요',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 완료 화면 (한도 반영 결과)
  Widget _buildResult(BuildContext context, AddIncomeViewModel vm) {
    // 에러가 있다면 에러 출력
    if (vm.applyLimitError != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            vm.applyLimitError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('돌아가기'),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.sectionSpacing2),

        // 지갑 아이콘
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: AppSpacing.sectionSpacing2),

        // 메인 메시지
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
              fontFamily: 'Pretendard Variable',
            ),
            children: [
              TextSpan(text: '${vm.appliedAmountText}을 '),
              TextSpan(
                text: '소비한도에 반영했어요!',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sectionSpacing),

        // 세부 메시지
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.4,
              fontFamily: 'Pretendard Variable',
            ),
            children: [
              const TextSpan(text: '기존 플랜의 하루 소비한도가 '),
              TextSpan(
                text: vm.oldDailyLimitText,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '에서 '),
              TextSpan(
                text: vm.newDailyLimitText,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '으로 변경되었어요!'),
            ],
          ),
        ),

        const Spacer(),

        // 확인 버튼
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                    (route) => false,
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
                fontFamily: 'Pretendard Variable',
              ),
            ),
            child: const Text('확인했어요'),
          ),
        ),
      ],
    );
  }
}

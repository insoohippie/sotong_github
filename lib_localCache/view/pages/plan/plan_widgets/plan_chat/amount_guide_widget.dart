import 'package:flutter/material.dart';

import '../../../../../component/theme/app_colors.dart';
import '../../../../../view_model/services/saving_calculator.dart';

class AmountGuideWidget extends StatelessWidget {
  final double amount;
  final String type;

  const AmountGuideWidget({
    super.key,
    required this.amount,
    required this.type,
  });

  String _formatAmountGuide(double amount, String type) {
    if (amount > 0) {
      if (type == '목표금액') {
        return '$type은 ${SavingPlanCalculator.formatAmount(amount)}원이에요!';
      } else if (type == '보유금액') {
        return '${SavingPlanCalculator.formatAmount(amount)}원을 보유하고 있어요.';
      }
    } else if (amount < 0) {
      if (type == '보유금액') {
        return '${SavingPlanCalculator.formatAmount(amount.abs())}원의 부채가 있어요.';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final guideText = _formatAmountGuide(amount, type);
    if (guideText.isEmpty) return const SizedBox.shrink();

    final isDebt = type == '보유금액' && amount < 0;

    final backgroundColor = isDebt
        ? AppColors.redBackground
        : AppColors.lightBlue;
    final textColor = isDebt ? AppColors.redText : AppColors.primary;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          guideText,
          style: TextStyle(fontSize: 14, color: textColor),
        ),
      ),
    );
  }
}

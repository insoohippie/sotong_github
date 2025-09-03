// calculator => 비즈니스 로직
// (중략)

// 세은님이 새로 짜시는 계산 로직 calculator 로 수정해야함! 지금은 28, 30, 31일을 고려 안한 초기의 계산 로직

import '../../model/plan_info.dart';
import '../../model/saving_calculation_result.dart';

class SavingPlanCalculator {
  final PlanInfo planInfo;

  SavingPlanCalculator({required this.planInfo});

  double get monthlyIncome => planInfo.fixedIncomeSum!;
  double get monthlyFixedCost => planInfo.fixedConsumptionSum!;
  double get targetAmount => planInfo.targetAmount!;
  double get currentAsset => planInfo.currentAsset; // non-nullable, default 0.0
  double get dailySpendingLimit => planInfo.dailyConsumptionSum!;
  DateTime get planStartDate => planInfo.startDate ?? DateTime.now();

  SavingCalculationResult calculate() {
    print('=== SavingPlanCalculator.calculate() 시작 ===');
    print('monthlyIncome: $monthlyIncome');
    print('monthlyFixedCost: $monthlyFixedCost');
    print('targetAmount: $targetAmount');
    print('currentAsset: $currentAsset');
    print('dailySpendingLimit: $dailySpendingLimit');
    print('planStartDate: $planStartDate');

    // 1) 고정소비만 뺀 ‘일일 가용액’
    final monthlySavingBeforeVariable = monthlyIncome - monthlyFixedCost; // (수입-고정)
    final dailySaving = monthlySavingBeforeVariable / 30;

    // 2) 변동소비(일일 한도 × 30일)
    final variableMonthly = dailySpendingLimit * 30;

    // 3) 최종 월 저축(수입 - 고정 - 변동)  ← UI에서 ‘저축’에 쓰일 값
    final monthlySaving = monthlySavingBeforeVariable - variableMonthly; // ✅ 수정

    // 4) 일 순저축 = (수입-고정)/30 - 일일한도  == monthlySaving/30
    final dailyNetSaving = dailySaving - dailySpendingLimit;

    // 5) 일일 한도가 ‘일일 가용액’을 얼마만큼 쓰는지 비율 (0~1로 클램프)
    double savingRatio =
    dailySaving == 0 ? 0.0 : 1 - (dailySpendingLimit / dailySaving);
    if (savingRatio.isNaN) savingRatio = 0.0;
    savingRatio = savingRatio.clamp(0.0, 1.0);

    // 6) 목표까지 필요한 금액(보유자산 반영)
    final requiredSaving = targetAmount - currentAsset;

    // 7) 기간/도달일 계산 (저축 불가면 0/NULL)
    final savingPerSecond =
    dailyNetSaving == 0 ? 0.0 : dailyNetSaving / 86400;
    final daysToGoal =
    dailyNetSaving == 0 ? 0.0 : requiredSaving / dailyNetSaving;
    final totalSeconds =
    dailyNetSaving == 0 ? 0.0 : daysToGoal * 86400;
    final goalDateTime = dailyNetSaving == 0
        ? null
        : planStartDate.add(Duration(seconds: totalSeconds.toInt()));

    print('계산 결과:');
    print('monthlySavingBeforeVariable: $monthlySavingBeforeVariable');
    print('variableMonthly: $variableMonthly');
    print('monthlySaving(=net): $monthlySaving');
    print('dailySaving: $dailySaving');
    print('dailyNetSaving: $dailyNetSaving');
    print('requiredSaving: $requiredSaving');
    print('daysToGoal: $daysToGoal');

    return SavingCalculationResult(
      monthlySaving: monthlySaving,      // ✅ 이제 ‘수입-고정-변동’ 값
      dailySaving: dailySaving,          // 수입-고정 기준 일일 가용액
      savingRatio: savingRatio,          // 0~1
      dailyNetSaving: dailyNetSaving,    // (수입-고정)/30 - 일일한도
      requiredSaving: requiredSaving,    // 목표-보유자산
      daysToGoal: daysToGoal,
      totalSeconds: totalSeconds,
      goalDateTime: goalDateTime,
      savingPerSecond: savingPerSecond,
    );
  }

  static String formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}

// calculator => 비즈니스 로직
// 소통 서비스에서 비즈니스 로직이란 무엇일까..?
// => 저장될 필요는 없지만, 자주 실행 되는 값과 메서드가 service 영역에 들어가야할듯
// 그러므로, SavingCalculationResult는 DB에는 저장될 필요 없는 값들이 되겠다
// saving_calculator는 function 위주

// calculator의 역할과 사용되는 곳 분석해서 어떻게 제거할 것인지 정리

import '../model/plan_info.dart';
import '../model/saving_calculation_result.dart';

class SavingPlanCalculator {
  final PlanInfo planInfo;

  SavingPlanCalculator({required this.planInfo});

  double get monthlyIncome => planInfo.fixedIncomeSum!;

  double get monthlyFixedCost => planInfo.fixedConsumptionSum!;

  double get targetAmount => planInfo.targetAmount!;

  double get currentAsset => planInfo.currentAsset!;

  double get dailySpendingLimit => planInfo.dailyConsumptionSum!;

  DateTime get planStartDate => planInfo.startDate!;

  SavingCalculationResult calculate() {
    final monthlySaving = monthlyIncome - monthlyFixedCost; // 월 저축 가능 금액
    final dailySaving = monthlySaving / 30; // 일 저축 가능 금액
    final savingRatio = dailySaving == 0
        ? 0.0
        : 1 - (dailySpendingLimit / dailySaving);

    final dailyNetSaving = dailySaving - dailySpendingLimit; // 순수 저축 금액(-daily)
    final requiredSaving = targetAmount - currentAsset; // 모아야 되는 금액
    final savingPerSecond = dailyNetSaving == 0
        ? 0.0
        : dailyNetSaving / 86400; // dailyNetSaving이 0이면 0

    final daysToGoal = dailyNetSaving == 0
        ? 0.0
        : requiredSaving / dailyNetSaving;
    final totalSeconds = dailyNetSaving == 0 ? 0.0 : daysToGoal * 86400;
    final goalDateTime = dailyNetSaving == 0
        ? null
        : planStartDate.add(Duration(seconds: totalSeconds.toInt()));

    return SavingCalculationResult(
      monthlySaving: monthlySaving,
      dailySaving: dailySaving,
      savingRatio: savingRatio,
      dailyNetSaving: dailyNetSaving,
      requiredSaving: requiredSaving,
      daysToGoal: daysToGoal,
      totalSeconds: totalSeconds,
      goalDateTime: goalDateTime,
      savingPerSecond: savingPerSecond,
    );
  }

  static String formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// 이걸 전부 비즈니스 로직의 결과로 치면 안될거같다...
// DB구조와도 잘 맞지 않음
// 굳이 반복되는 값을 불필요한 연산 반복 할 필요가 없다(혹은 사용도 낮은 값의 연산)
// => 저장될 필요는 없지만, 자주 실행 되는 것이 service 영역에 들어가야할듯
// 그러므로, SavingCalculationResult는 DB에는 저장될 필요 없는 값들이 되겠다

class SavingCalculationResult {
  final double monthlySaving; // = fixedIncomeAmount, Info&Ref
  final double dailySaving; // Ref
  final double savingRatio; // Info
  final double dailyNetSaving; // Ref
  final double requiredSaving; //

  final double daysToGoal;
  final double totalSeconds;
  final DateTime? goalDateTime;
  final double savingPerSecond;

  SavingCalculationResult({
    this.monthlySaving = 0,
    this.dailySaving = 0,
    this.savingRatio = 0,
    this.dailyNetSaving = 0,
    this.requiredSaving = 0,
    this.daysToGoal = 0,
    this.totalSeconds = 0,
    this.goalDateTime,
    this.savingPerSecond = 0,
  });

  @override
  String toString() {
    return '''
    SavingCalculationResult(
      monthlySaving: ${monthlySaving.toStringAsFixed(2)}원,
      dailySaving: ${dailySaving.toStringAsFixed(2)}원,
      savingRatio: ${(savingRatio * 100).toStringAsFixed(2)}%,
      dailyNetSaving: ${dailyNetSaving.toStringAsFixed(2)}원,
      requiredSaving: ${requiredSaving.toStringAsFixed(2)}원,
      daysToGoal: ${daysToGoal.toStringAsFixed(1)}일,
      totalSeconds: ${totalSeconds.toStringAsFixed(2)}초,
      goalDateTime: $goalDateTime,
      savingPerSecond: ${savingPerSecond.toStringAsFixed(6)}원/초
    )
    ''';
  }
}

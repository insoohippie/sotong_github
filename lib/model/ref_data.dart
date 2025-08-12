import 'package:cloud_firestore/cloud_firestore.dart';
import 'entry.dart';

/*
UI 계산 목적이거나 유저 행동에 따라 바뀌는 동적 정보 => ViewModel
UI에 맞춘 데이터 구조화 – 책임이 ViewModel 쪽에 더 가까움
 */
class RefData {
  String planID;
  List<Entry> fixedIncomes; // 월 고정 수입
  List<Entry> fixedConsumptions; // 월 고정 소비
  List<Entry> dailyConsumptions; // 일일 한도
  List<Entry> variableConsumptions; // 변동 소비

  List<Entry> installmentIncomes; // 할부 수입
  List<Entry> installmentConsumptions; // 할부 소비
  List<Entry> additionalIncomeList; // 추가 수입
  List<Entry> additionalConsumptionList; // 추가 소비
  List<Entry> variableConsumptionList; // 변동 소비 상세 리스트

  RefData({
    this.planID = '',
    this.fixedIncomes = const [],
    this.fixedConsumptions = const [],
    this.dailyConsumptions = const [],
    this.variableConsumptions = const [],
    this.installmentIncomes = const [],
    this.installmentConsumptions = const [],
    this.additionalIncomeList = const [],
    this.additionalConsumptionList = const [],
    this.variableConsumptionList = const [],
  });

  // Date 포함 필터링은 비즈니스 로직으로 옮기는게 적절함

  int getInstallmentConsumptionAmount(DateTime date, DateTime endDate) {
    int total = 0;

    for (var entry in installmentConsumptions) {
      if (entry.dateTime == null) continue;
      if (entry.dateTime!.isAfter(date) ||
          entry.dateTime!.isAtSameMomentAs(date)) {
        final days = endDate.difference(entry.dateTime!).inDays;
        if (days > 0) {
          total += (entry.amount / days).floor();
        }
      }
    }

    return total;
  }

  int getInstallmentIncomeAmount(DateTime date, DateTime endDate) {
    int total = 0;

    for (var entry in additionalIncomeList) {
      if (entry.dateTime == null) continue;
      if (entry.dateTime!.isAfter(date) ||
          entry.dateTime!.isAtSameMomentAs(date)) {
        final days = endDate.difference(entry.dateTime!).inDays;
        if (days > 0) {
          total += (entry.amount / days).floor();
        }
      }
    }

    return total;
  }

  String toString() {
    return '''
RefData(
  planID: $planID,
  fixedIncomes: ${fixedIncomes.length}개, 총합: ${_sum(fixedIncomes)}원,
  fixedConsumptions: ${fixedConsumptions.length}개, 총합: ${_sum(fixedConsumptions)}원,
  dailyConsumptions: ${dailyConsumptions.length}개, 총합: ${_sum(dailyConsumptions)}원,
  variableConsumptions: ${variableConsumptions.length}개, 총합: ${_sum(variableConsumptions)}원,
  installmentIncomes: ${installmentIncomes.length}개, 총합: ${_sum(installmentIncomes)}원,
  installmentConsumptions: ${installmentConsumptions.length}개, 총합: ${_sum(installmentConsumptions)}원,
  additionalIncomeList: ${additionalIncomeList.length}개, 총합: ${_sum(additionalIncomeList)}원,
  additionalConsumptionList: ${additionalConsumptionList.length}개, 총합: ${_sum(additionalConsumptionList)}원,
  variableConsumptionList: ${variableConsumptionList.length}개, 총합: ${_sum(variableConsumptionList)}원
)
''';
  }

  double _sum(List<Entry> list) {
    return list.fold(0.0, (sum, e) => sum + e.amount);
  }
}

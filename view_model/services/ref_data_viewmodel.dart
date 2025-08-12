



import '../../model/entry.dart';
import '../../model/ref_data.dart';

class RefDataViewModel {
  final RefData refData;

  RefDataViewModel(this.refData);


  void updateRefData({
    List<Entry>? fixedIncomes,
    List<Entry>? fixedConsumptions,
    List<Entry>? dailyConsumptions,
    List<Entry>? variableConsumptions,
    List<Entry>? installmentIncomes,
    List<Entry>? installmentConsumptions,
    List<Entry>? additionalIncomeList,
    List<Entry>? additionalConsumptionList,
    List<Entry>? variableConsumptionList,
  }) {
    if (fixedIncomes != null) refData.fixedIncomes = fixedIncomes;
    if (fixedConsumptions != null) refData.fixedConsumptions = fixedConsumptions;
    if (dailyConsumptions != null) refData.dailyConsumptions = dailyConsumptions;
    if (variableConsumptions != null) refData.variableConsumptions = variableConsumptions;
    if (installmentIncomes != null) refData.installmentIncomes = installmentIncomes;
    if (installmentConsumptions != null) refData.installmentConsumptions = installmentConsumptions;
    if (additionalIncomeList != null) refData.additionalIncomeList = additionalIncomeList;
    if (additionalConsumptionList != null) refData.additionalConsumptionList = additionalConsumptionList;
    if (variableConsumptionList != null) refData.variableConsumptionList = variableConsumptionList;
  }

  // toMap 메서드
  Map<String, dynamic> fixedIncomesToMap() => {
    'fixedIncomes': refData.fixedIncomes.map((e) => e.toMap()).toList(),
  };

  Map<String, dynamic> fixedConsumptionsToMap() => {
    'fixedConsumptions': refData.fixedConsumptions.map((e) => e.toMap()).toList(),
  };

  Map<String, dynamic> dailyConsumptionsToMap() => {
    'dailyConsumptions': refData.dailyConsumptions.map((e) => e.toMap()).toList(),
  };

  Map<String, dynamic> variableConsumptionsToMap() => {
    'variableConsumptions': refData.variableConsumptions.map((e) => e.toMap()).toList(),
  };

  Map<String, dynamic> installmentIncomesToMap() => {
    'installmentIncomes': refData.installmentIncomes.map((e) => e.toMap()).toList(),
  };

  Map<String, dynamic> installmentConsumptionsToMap() => {
    'installmentConsumptions': refData.installmentConsumptions.map((e) => e.toMap()).toList(),
  };

  Map<String, dynamic> additionalIncomeListToMap() => {
    'additionalIncomeList': refData.additionalIncomeList.map((e) => e.toMap()).toList(),
  };

  Map<String, dynamic> additionalConsumptionListToMap() => {
    'additionalConsumptionList': refData.additionalConsumptionList.map((e) => e.toMap()).toList(),
  };

  Map<String, dynamic> variableConsumptionListToMap() => {
    'variableConsumptionList': refData.variableConsumptionList.map((e) => e.toMap()).toList(),
  };

  // fromMap 메서드 (static)
  static List<Entry> fromFixedIncomesMap(Map<String, dynamic> map) {
    return (map['fixedIncomes'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ??
        [];
  }

  static List<Entry> fromFixedConsumptionsMap(Map<String, dynamic> map) {
    return (map['fixedConsumptions'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ??
        [];
  }

  static List<Entry> fromDailyConsumptionsMap(Map<String, dynamic> map) {
    return (map['dailyConsumptions'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ??
        [];
  }

  static List<Entry> fromVariableConsumptionsMap(Map<String, dynamic> map) {
    return (map['variableConsumptions'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ??
        [];
  }

  static List<Entry> fromInstallmentIncomesMap(Map<String, dynamic> map) {
    return (map['installmentIncomes'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ?? [];
  }

  static List<Entry> fromInstallmentConsumptionsMap(Map<String, dynamic> map) {
    return (map['installmentConsumptions'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ??
        [];
  }

  static List<Entry> fromAdditionalIncomeListMap(Map<String, dynamic> map) {
    return (map['additionalIncomeList'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ??
        [];
  }

  static List<Entry> fromAdditionalConsumptionListMap(Map<String, dynamic> map) {
    return (map['additionalConsumptionList'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ??
        [];
  }

  static List<Entry> fromVariableConsumptionListMap(Map<String, dynamic> map) {
    return (map['variableConsumptionList'] as List<dynamic>?)
        ?.map((e) => Entry.fromMap(e as Map<String, dynamic>))
        .toList() ??
        [];
  }

  // Date 포함 필터링은 비즈니스 로직으로 옮기는게 적절함
  int getInstallmentConsumptionAmount(DateTime date, DateTime endDate) {
    int total = 0;
    for (var entry in refData.installmentConsumptions) {
      if (entry.dateTime == null) continue;
      if (entry.dateTime!.isAfter(date) || entry.dateTime!.isAtSameMomentAs(date)) {
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
    for (var entry in refData.additionalIncomeList) {
      if (entry.dateTime == null) continue;
      if (entry.dateTime!.isAfter(date) || entry.dateTime!.isAtSameMomentAs(date)) {
        final days = endDate.difference(entry.dateTime!).inDays;
        if (days > 0) {
          total += (entry.amount / days).floor();
        }
      }
    }
    return total;
  }

  // Update methods for each Entry list
  // 아래 함수들은 더 이상 refData의 리스트를 직접 수정하지 않고, ChatPlanViewModel의 updateRefData를 호출해야 함
  // 단, RefDataViewModel은 ChatPlanViewModel에 대한 참조가 없으므로, 이 함수들은 ChatPlanViewModel에서 직접 구현하거나, 필요시 콜백을 주입하는 방식으로 구조를 바꿔야 함
  // 아래는 기존 함수들을 주석 처리 또는 삭제하는 것이 맞음
  // void updateFixedIncomeEntries(List<Entry> entries) {
  //   refData.fixedIncomes = entries;
  // }

  // void updateFixedConsumptionEntries(List<Entry> entries) {
  //   refData.fixedConsumptions = entries;
  // }

  // void updateDailyConsumptionEntries(List<Entry> entries) {
  //   refData.dailyConsumptions = entries;
  // }

  // void updateVariableConsumptionEntries(List<Entry> entries) {
  //   refData.variableConsumptions = entries;
  // }

  // void updateInstallmentIncomeEntries(List<Entry> entries) {
  //   refData.installmentIncomes = entries;
  // }

  // void updateInstallmentConsumptionEntries(List<Entry> entries) {
  //   refData.installmentConsumptions = entries;
  // }

  // void updateAdditionalIncomeListEntries(List<Entry> entries) {
  //   refData.additionalIncomeList = entries;
  // }

  // void updateAdditionalConsumptionListEntries(List<Entry> entries) {
  //   refData.additionalConsumptionList = entries;
  // }

  // void updateVariableConsumptionListEntries(List<Entry> entries) {
  //   refData.variableConsumptionList = entries;
  // }

  // Entry 리스트 합계 구하는 메서드
  double sum(List<Entry> entries) => entries.fold(0, (sum, e) => sum + e.amount);
} 
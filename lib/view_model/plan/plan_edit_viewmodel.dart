import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/entry.dart';
import '../../model/plan_info.dart';
import '../../model/ref_data.dart';
import '../services/plan_info_viewmodel.dart';

class PlanEditViewModel extends ChangeNotifier {
  late TextEditingController planNameController;
  late TextEditingController targetAmountController;
  late TextEditingController currentAssetController;

  late PlanInfo planInfo;
  late PlanInfoViewModel planInfoVM;
  late RefData refData;

  // Getters for calculated values
  double get monthlyIncome =>
      refData.fixedIncomes.fold(0, (sum, i) => sum + i.amount);

  double get monthlyFixedCost =>
      refData.fixedConsumptions.fold(0, (sum, i) => sum + i.amount);

  double get dailySpendingLimit =>
      refData.dailyConsumptions.fold(0, (sum, i) => sum + i.amount);

  // Constructor that automatically initializes with PlanInfo
  PlanEditViewModel(PlanInfo initialPlan, {RefData? initialRefData}) {
    _initializeWithPlan(initialPlan, initialRefData: initialRefData);
  }

  // Initialize with initial plan data
  void _initializeWithPlan(PlanInfo initialPlan, {RefData? initialRefData}) {
    planInfo = initialPlan;
    planInfoVM = PlanInfoViewModel(planInfo);
    refData = initialRefData ?? RefData();

    planNameController = TextEditingController(text: initialPlan.planName);

    final formatter = NumberFormat('#,###');
    targetAmountController = TextEditingController(
      text: formatter.format((initialPlan.targetAmount ?? 0).toInt()),
    );
    currentAssetController = TextEditingController(
      text: formatter.format((initialPlan.currentAsset ?? 0).toInt()),
    );

    notifyListeners();
  }

  // Entry 리스트 업데이트
  void updateFixedIncomeEntries(List<Entry> entries) {
    refData.fixedIncomes = entries;
    planInfo.fixedIncomeSum = monthlyIncome;
    notifyListeners();
  }

  void updateFixedCostEntries(List<Entry> entries) {
    refData.fixedConsumptions = entries;
    planInfo.fixedConsumptionSum = monthlyFixedCost;
    notifyListeners();
  }

  void updateDailyCostEntries(List<Entry> entries) {
    refData.dailyConsumptions = entries;
    planInfo.dailyConsumptionSum = dailySpendingLimit;
    notifyListeners();
  }

  // Create updated PlanInfo
  PlanInfo createUpdatedPlan(PlanInfo originalPlan) {
    print('createUpdatedPlan 호출됨');
    print('현재 planNameController.text: ${planNameController.text}');
    print('현재 targetAmountController.text: ${targetAmountController.text}');
    print('현재 currentAssetController.text: ${currentAssetController.text}');

    // planInfo 객체를 직접 업데이트
    planInfo.planName = planNameController.text;
    planInfo.targetAmount =
        double.tryParse(targetAmountController.text.replaceAll(',', '')) ?? 0;
    planInfo.currentAsset =
        double.tryParse(currentAssetController.text.replaceAll(',', '')) ?? 0;

    // RefData도 함께 업데이트
    planInfo.fixedIncomeSum = monthlyIncome;
    planInfo.fixedConsumptionSum = monthlyFixedCost;
    planInfo.dailyConsumptionSum = dailySpendingLimit;

    print('업데이트된 planInfo:');
    print('- planName: ${planInfo.planName}');
    print('- targetAmount: ${planInfo.targetAmount}');
    print('- currentAsset: ${planInfo.currentAsset}');

    return planInfo;
  }

  // Get updated RefData
  RefData getUpdatedRefData() {
    return refData;
  }

  // Validate form
  bool isValidForm() {
    return planNameController.text.isNotEmpty &&
        double.tryParse(targetAmountController.text.replaceAll(',', '')) !=
            null &&
        double.tryParse(currentAssetController.text.replaceAll(',', '')) !=
            null;
  }

  // Get validation error message
  String? getValidationError() {
    if (planNameController.text.isEmpty) {
      return '플랜 이름을 입력해주세요';
    }
    final targetParsed = double.tryParse(
      targetAmountController.text.replaceAll(',', ''),
    );
    if (targetParsed == null) {
      return '목표 금액을 올바르게 입력해주세요';
    }
    final assetParsed = double.tryParse(
      currentAssetController.text.replaceAll(',', ''),
    );
    if (assetParsed == null) {
      return '보유 자산을 올바르게 입력해주세요';
    }
    return null;
  }

  String? applyEdits() {
    // 1) 검증
    final err = getValidationError();
    if (err != null) return err;

    // 2) 업데이트
    planInfo.planName = planNameController.text;
    planInfo.targetAmount =
        double.tryParse(targetAmountController.text.replaceAll(',', '')) ?? 0;
    planInfo.currentAsset =
        double.tryParse(currentAssetController.text.replaceAll(',', '')) ?? 0;

    planInfo.fixedIncomeSum = monthlyIncome;
    planInfo.fixedConsumptionSum = monthlyFixedCost;
    planInfo.dailyConsumptionSum = dailySpendingLimit;

    // null 이면 성공
    return null;
  }

  @override
  void dispose() {
    planNameController.dispose();
    targetAmountController.dispose();
    currentAssetController.dispose();
    super.dispose();
  }
}

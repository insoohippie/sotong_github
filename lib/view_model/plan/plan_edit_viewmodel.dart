import 'package:flutter/material.dart';

import '../../model/entry.dart';
import '../../model/plan_info.dart';
import '../../model/ref_data.dart';
import '../../services/plan_info_viewmodel.dart';

// 수정 페이지의 viewModel
// view컨트롤러가 다른데...

class PlanEditViewModel extends ChangeNotifier {
  late TextEditingController planNameController;
  late TextEditingController targetAmountController;
  late TextEditingController currentAssetController;
  String? selectedPurpose;

  late PlanInfo planInfo;
  late PlanInfoViewModel planInfoVM;
  late RefData refData;

  final List<String> purposeOptions = [
    '여행자금',
    '자취 준비',
    '부모님 선물',
    '결혼 준비',
    '학자금',
    '이직준비',
    '긴급자금',
    '기타',
  ];

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

    // purposeOptions 리스트에 있는 값인지 확인
    if (initialPlan.purpose!.isNotEmpty) {
      if (purposeOptions.contains(initialPlan.purpose)) {
        selectedPurpose = initialPlan.purpose;
      } else {
        // 기타로 입력한 값이면 리스트에 추가
        purposeOptions.add(initialPlan.purpose!);
        selectedPurpose = initialPlan.purpose;
      }
    } else {
      selectedPurpose = null;
    }

    targetAmountController = TextEditingController(
      text: initialPlan.targetAmount!.toStringAsFixed(0),
    );
    currentAssetController = TextEditingController(
      text: initialPlan.currentAsset!.toStringAsFixed(0),
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

  // Update selected purpose
  void updateSelectedPurpose(String? purpose) {
    selectedPurpose = purpose;
    if (purpose != null) {
      planInfoVM.updatePurpose(purpose);
    }
    notifyListeners();
  }

  // Create updated PlanInfo
  PlanInfo createUpdatedPlan(PlanInfo originalPlan) {
    print('createUpdatedPlan 호출됨');
    print('현재 selectedPurpose: $selectedPurpose');
    print('현재 planNameController.text: ${planNameController.text}');
    print('현재 targetAmountController.text: ${targetAmountController.text}');
    print('현재 currentAssetController.text: ${currentAssetController.text}');

    // planInfo 객체를 직접 업데이트
    planInfo.planName = planNameController.text;
    planInfo.purpose = selectedPurpose ?? '';
    planInfo.targetAmount = double.tryParse(targetAmountController.text) ?? 0;
    planInfo.currentAsset = double.tryParse(currentAssetController.text) ?? 0;

    // RefData도 함께 업데이트
    planInfo.fixedIncomeSum = monthlyIncome;
    planInfo.fixedConsumptionSum = monthlyFixedCost;
    planInfo.dailyConsumptionSum = dailySpendingLimit;

    print('업데이트된 planInfo:');
    print('- planName: ${planInfo.planName}');
    print('- purpose: ${planInfo.purpose}');
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
        selectedPurpose != null &&
        double.tryParse(targetAmountController.text) != null &&
        double.tryParse(currentAssetController.text) != null;
  }

  // Get validation error message
  String? getValidationError() {
    if (planNameController.text.isEmpty) {
      return '플랜 이름을 입력해주세요';
    }
    if (selectedPurpose == null) {
      return '플랜 목적을 선택해주세요';
    }
    if (double.tryParse(targetAmountController.text) == null) {
      return '목표 금액을 올바르게 입력해주세요';
    }
    if (double.tryParse(currentAssetController.text) == null) {
      return '보유 자산을 올바르게 입력해주세요';
    }
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

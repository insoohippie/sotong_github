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

  // 월 변동소비(일한도 × 30)
  double get monthlyVariableCost => dailySpendingLimit * 30.0;

// 월 저축액 (음수면 0으로 클램프)
  double get monthlySaving =>
      (monthlyIncome - monthlyFixedCost - monthlyVariableCost)
          .clamp(0, monthlyIncome);

  double get dailySpendingLimit =>
      refData.dailyConsumptions.fold(0, (sum, i) => sum + i.amount);

  // 입력 필드 파싱 getter
  double get parsedTarget =>
      double.tryParse(targetAmountController.text.replaceAll(',', '')) ?? 0.0;
  double get parsedCurrent =>
      double.tryParse(currentAssetController.text.replaceAll(',', '')) ?? 0.0;

  // 일일 순저축(원/일) = (월수입 - 고정지출 - (일한도×30)) / 30
  double get dailyNetSaving {
    final monthlyNet = monthlyIncome - monthlyFixedCost - (dailySpendingLimit * 30.0);
    return monthlyNet / 30.0;
  }

  // 목표까지 남은 일수 (저축 불가 or 목표 이하 → null)
  int? get daysToGoal {
    final remain = parsedTarget - parsedCurrent;
    if (parsedTarget <= 0) return null;
    if (remain <= 0) return null;
    if (dailyNetSaving <= 0) return null;
    return (remain / dailyNetSaving).ceil();
  }

  // 도달 예정일, 소요기간 문자열
  String? get reachDateStr {
    final d = daysToGoal;
    if (d == null) return null;
    final dt = DateTime.now().add(Duration(days: d));
    return DateFormat('yyyy.MM.dd').format(dt);
  }

  String? get durationStr {
    final d = daysToGoal;
    if (d == null) return null;
    final months = d ~/ 30;
    if (months <= 0) return '1개월 미만';
    return '${months}개월';
  }

  // 컨트롤러 리스너(실시간 반영)
  void _attachControllerListeners() {
    planNameController.addListener(_onFieldChanged);
    targetAmountController.addListener(_onFieldChanged);
    currentAssetController.addListener(_onFieldChanged);
  }
  void _onFieldChanged() => notifyListeners();

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

    // 🔔 실시간 반영: 입력 변화가 있을 때마다 화면 갱신
    _attachControllerListeners();

    notifyListeners();
  }

  void _detachControllerListeners() {
    planNameController.removeListener(_onFieldChanged);
    targetAmountController.removeListener(_onFieldChanged);
    currentAssetController.removeListener(_onFieldChanged);
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

    return planInfo;
  }

  // Get updated RefData
  RefData getUpdatedRefData() {
    return refData;
  }

  // Validate form
  bool isValidForm() {
    return planNameController.text.isNotEmpty &&
        double.tryParse(targetAmountController.text.replaceAll(',', '')) != null &&
        double.tryParse(currentAssetController.text.replaceAll(',', '')) != null;
  }

  // Get validation error message
  String? getValidationError() {
    if (planNameController.text.isEmpty) {
      return '플랜 이름을 입력해주세요';
    }
    final targetParsed =
    double.tryParse(targetAmountController.text.replaceAll(',', ''));
    if (targetParsed == null) {
      return '목표 금액을 올바르게 입력해주세요';
    }
    final assetParsed =
    double.tryParse(currentAssetController.text.replaceAll(',', ''));
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
    _detachControllerListeners();
    planNameController.dispose();
    targetAmountController.dispose();
    currentAssetController.dispose();
    super.dispose();
  }
}

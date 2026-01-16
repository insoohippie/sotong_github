import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/commands/update_daily_command.dart';
import '../../model/commands/update_monthly_command.dart';
import '../../model/plan/plan_edit_result.dart';
import '../../model/plan/total_plan.dart';
import '../../model/refData/ref_data.dart';
import '../../model/refData/entry.dart';
import '../services/ref_data_viewmodel.dart';
import '../services/saving_calculator.dart';
import '../services/total_plan_viewmodel.dart';

class PlanEditViewModel extends ChangeNotifier {
  late TextEditingController planNameController;
  late TextEditingController targetAmountController;
  late TextEditingController currentAssetController;

  late TotalPlan totalPlan;
  late TotalPlanViewModel totalPlanVM;
  late RefData refData;
  late RefDataViewModel refDataVM;

  List<Entry>? _pendingFixedIncomeEntries;
  List<Entry>? _pendingFixedConsumeEntries;
  List<Entry>? _pendingDailyConsumeEntries;
  DateTime? _pendingFixedIncomeApplyDate;
  DateTime? _pendingFixedConsumeApplyDate;
  DateTime? _pendingDailyConsumeApplyDate;

  // Getters for calculated values
  double get monthlyIncome => _pendingFixedIncomeEntries != null
      ? _sumEntries(_pendingFixedIncomeEntries!)
      : refData.primaryMonthlyIncomeSum;

  double get monthlyFixedCost => _pendingFixedConsumeEntries != null
      ? _sumEntries(_pendingFixedConsumeEntries!)
      : refData.primaryMonthlyConsumeSum;

  double get monthlyVariableCost => dailySpendingLimit * 30.0;

  double get monthlySaving => monthlyIncome - monthlyFixedCost - monthlyVariableCost;

  double get dailySpendingLimit => _pendingDailyConsumeEntries != null
      ? _sumEntries(_pendingDailyConsumeEntries!)
      : refData.primaryDailyConsumeSum;

  List<Entry> get currentMonthlyIncomeEntries =>
      _pendingFixedIncomeEntries ?? refData.primaryMonthlyIncomeEntries;

  List<Entry> get currentMonthlyConsumeEntries =>
      _pendingFixedConsumeEntries ?? refData.primaryMonthlyConsumeEntries;

  List<Entry> get currentDailyConsumeEntries =>
      _pendingDailyConsumeEntries ?? refData.primaryDailyConsumeEntries;

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

  DateTime? get projectedGoalDate {
    final calc = SavingPlanCalculator(plan: totalPlan).calculate();
    return calc?.goalDateTime;
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

  // Constructor that automatically initializes with TotalPlan
  PlanEditViewModel(TotalPlan initialPlan, {RefData? initialRefData}) {
    _initializeWithPlan(initialPlan, initialRefData: initialRefData);
  }

  // Initialize with initial plan data
  void _initializeWithPlan(TotalPlan initialPlan, {RefData? initialRefData}) {
    totalPlan = initialPlan;
    totalPlanVM = TotalPlanViewModel(totalPlan);
    refData = initialRefData ?? RefData(planId: initialPlan.planId);
    refData.planId = initialPlan.planId;
    refDataVM = RefDataViewModel(refData);

    planNameController = TextEditingController(text: initialPlan.planName ?? '');

    final formatter = NumberFormat('#,###');
    targetAmountController = TextEditingController(
      text: formatter.format((initialPlan.targetAmount ?? 0)),
    );
    currentAssetController = TextEditingController(
      text: formatter.format(initialPlan.currentAsset),
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
  DateTime? get pendingFixedIncomeApplyDate => _pendingFixedIncomeApplyDate;
  DateTime? get pendingFixedConsumeApplyDate => _pendingFixedConsumeApplyDate;
  DateTime? get pendingDailyConsumeApplyDate => _pendingDailyConsumeApplyDate;

  void applyFixedIncomeEdit({
    required List<Entry> entries,
    required DateTime applyDate,
  }) {
    _pendingFixedIncomeEntries = List<Entry>.unmodifiable(entries);
    _pendingFixedIncomeApplyDate = _normalizeDay(applyDate);
    totalPlanVM.updateMetrics(monthlyIncome: _sumEntries(entries));
    totalPlan = totalPlanVM.plan;
    notifyListeners();
  }

  void applyFixedConsumeEdit({
    required List<Entry> entries,
    required DateTime applyDate,
  }) {
    _pendingFixedConsumeEntries = List<Entry>.unmodifiable(entries);
    _pendingFixedConsumeApplyDate = _normalizeDay(applyDate);
    totalPlanVM.updateMetrics(monthlyConsume: _sumEntries(entries));
    totalPlan = totalPlanVM.plan;
    notifyListeners();
  }

  void applyDailyConsumeEdit({
    required List<Entry> entries,
    required DateTime applyDate,
  }) {
    _pendingDailyConsumeEntries = List<Entry>.unmodifiable(entries);
    _pendingDailyConsumeApplyDate = _normalizeDay(applyDate);
    totalPlanVM.updateMetrics(dailyConsume: _sumEntries(entries));
    totalPlan = totalPlanVM.plan;
    notifyListeners();
  }

  // Create updated TotalPlan
  TotalPlan createUpdatedPlan(TotalPlan originalPlan) {
    totalPlanVM.updateMeta(
      planName: planNameController.text,
      targetAmount: parsedTarget,
      currentAsset: parsedCurrent,
    );
    totalPlanVM.updateMetrics(
      monthlyIncome: monthlyIncome,
      monthlyConsume: monthlyFixedCost,
      dailyConsume: dailySpendingLimit,
    );
    totalPlan = totalPlanVM.plan;
    return totalPlan;
  }

  UpdateMonthlyCommand buildMonthlyCommand({
    required DateTime applyMonth,
    required DateTime modEndMonth,
    required List<Entry> entries,
    required String newDocumentId,
    String? previousDocumentId,
    required bool isIncome,
  }) {
    return UpdateMonthlyCommand(
      applyMonth: DateTime(applyMonth.year, applyMonth.month),
      modEndMonth: DateTime(modEndMonth.year, modEndMonth.month),
      entries: entries,
      newDocumentId: newDocumentId,
      previousDocumentId: previousDocumentId,
      isIncome: isIncome,
    );
  }

  UpdateDailyCommand buildDailyCommand({
    required DateTime applyDate,
    required DateTime modEndDate,
    required List<Entry> entries,
    required String newDailyId,
    required String newMiniDocId,
    String? previousDailyId,
  }) {
    return UpdateDailyCommand(
      applyDate: DateTime(applyDate.year, applyDate.month, applyDate.day),
      modEndDate: DateTime(modEndDate.year, modEndDate.month, modEndDate.day),
      entries: entries,
      newDailyId: newDailyId,
      newMiniDocId: newMiniDocId,
      previousDailyId: previousDailyId,
    );
  }

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  double _sumEntries(List<Entry> entries) =>
      entries.fold(0.0, (sum, e) => sum + e.amount);

  PlanEditResult finalizeEdits() {
    final projected = projectedGoalDate ??
        totalPlan.modEndDate ??
        totalPlan.endDate ??
        DateTime.now();

    totalPlanVM.plan = totalPlanVM.plan.copyWith(modEndDate: projected);
    totalPlan = totalPlanVM.plan;

    final projectedMonth = DateTime(projected.year, projected.month, 1);

    final monthlyCommands = <UpdateMonthlyCommand>[];
    final dailyCommands = <UpdateDailyCommand>[];
    DateTime? earliestApplyDate;

    void trackApplyDate(DateTime date) {
      final normalized = _normalizeDay(date);
      if (earliestApplyDate == null || normalized.isBefore(earliestApplyDate!)) {
        earliestApplyDate = normalized;
      }
    }

    if (_pendingFixedIncomeEntries != null) {
      final applyDate = _pendingFixedIncomeApplyDate;
      if (applyDate == null) {
        throw StateError('월 수입 적용일이 설정되어 있지 않습니다.');
      }
      final applyMonth = DateTime(applyDate.year, applyDate.month, 1);
      final previousId = refData.primaryMonthlyIncomeId;
      final income = refData.addMonthlyIncome(
        applyMonth: applyMonth,
        modEndMonth: projectedMonth,
        entries: _pendingFixedIncomeEntries!,
      );
      monthlyCommands.add(
        UpdateMonthlyCommand(
          applyMonth: applyMonth,
          modEndMonth: projectedMonth,
          entries: income.entries,
          newDocumentId: income.id,
          previousDocumentId: previousId,
          isIncome: true,
        ),
      );
      trackApplyDate(applyDate);
      _pendingFixedIncomeEntries = null;
      _pendingFixedIncomeApplyDate = null;
    }

    if (_pendingFixedConsumeEntries != null) {
      final applyDate = _pendingFixedConsumeApplyDate;
      if (applyDate == null) {
        throw StateError('고정 소비 적용일이 설정되어 있지 않습니다.');
      }
      final applyMonth = DateTime(applyDate.year, applyDate.month, 1);
      final previousId = refData.primaryMonthlyConsumeId;
      final consume = refData.addMonthlyConsume(
        applyMonth: applyMonth,
        modEndMonth: projectedMonth,
        entries: _pendingFixedConsumeEntries!,
      );
      monthlyCommands.add(
        UpdateMonthlyCommand(
          applyMonth: applyMonth,
          modEndMonth: projectedMonth,
          entries: consume.entries,
          newDocumentId: consume.id,
          previousDocumentId: previousId,
          isIncome: false,
        ),
      );
      trackApplyDate(applyDate);
      _pendingFixedConsumeEntries = null;
      _pendingFixedConsumeApplyDate = null;
    }

    if (_pendingDailyConsumeEntries != null) {
      final applyDate = _pendingDailyConsumeApplyDate;
      if (applyDate == null) {
        throw StateError('일일 소비 적용일이 설정되어 있지 않습니다.');
      }
      final previousId = refData.primaryDailyConsumeId;
      final daily = refData.addDailyConsume(
        applyDate: applyDate,
        modEndDate: projected,
        entries: _pendingDailyConsumeEntries!,
      );
      final miniDocId = _nextMiniDocId(applyDate);
      dailyCommands.add(
        UpdateDailyCommand(
          applyDate: applyDate,
          modEndDate: projected,
          entries: daily.entries,
          newDailyId: daily.id,
          newMiniDocId: miniDocId,
          previousDailyId: previousId,
        ),
      );
      trackApplyDate(applyDate);
      _pendingDailyConsumeEntries = null;
      _pendingDailyConsumeApplyDate = null;
    }

    final refDataSnapshot = RefData.fromMap(refData.toMap());
    final resolvedApplyDate =
        earliestApplyDate ?? (totalPlan.startDate ?? _normalizeDay(DateTime.now()));

    return PlanEditResult(
      updatedPlan: totalPlan,
      updatedRefData: refDataSnapshot,
      applyDate: resolvedApplyDate,
      projectedGoalDate: projected,
      monthlyCommands: monthlyCommands,
      dailyCommands: dailyCommands,
    );
  }

  String _nextMiniDocId(DateTime applyDate) {
    final base =
        '${applyDate.year.toString().padLeft(4, '0')}${applyDate.month.toString().padLeft(2, '0')}';
    final subPlan = totalPlan.subPlans[base];
    var maxSeq = 0;
    if (subPlan != null) {
      for (final id in subPlan.miniPlans.keys) {
        final parts = id.split('-');
        if (parts.length != 2) continue;
        final seq = int.tryParse(parts[1]);
        if (seq != null && seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }
    final nextSeq = (maxSeq + 1).toString().padLeft(3, '0');
    return '$base-$nextSeq';
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
    totalPlanVM.updateMeta(
      planName: planNameController.text,
      targetAmount: parsedTarget,
      currentAsset: parsedCurrent,
    );
    totalPlanVM.updateMetrics(
      monthlyIncome: monthlyIncome,
      monthlyConsume: monthlyFixedCost,
      dailyConsume: dailySpendingLimit,
    );
    totalPlan = totalPlanVM.plan;

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

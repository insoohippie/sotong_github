import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/commands/update_daily_command.dart';
import '../../model/commands/update_monthly_command.dart';
import '../../model/plan/mini_plan.dart';
import '../../model/plan/plan_edit_result.dart';
import '../../model/plan/sub_plan.dart';
import '../../model/plan/total_plan.dart';
import '../../model/refData/ref_data.dart';
import '../../model/refData/entry.dart';
import '../services/ref_data_viewmodel.dart';
import '../../model/saving_calculation_result.dart';
import '../../services/plan_debug_printer.dart';
import '../services/plan_preview_service.dart';
import '../services/total_plan_viewmodel.dart';

class PlanEditViewModel extends ChangeNotifier {
  late TextEditingController planNameController;
  late TextEditingController targetAmountController;
  late TextEditingController currentAssetController;

  late TotalPlan totalPlan;
  late TotalPlanViewModel totalPlanVM;
  late RefData refData;
  late RefDataViewModel refDataVM;
  DateTime? _initialEndDate;

  List<Entry>? _pendingFixedIncomeEntries;
  List<Entry>? _pendingFixedConsumeEntries;
  List<Entry>? _pendingDailyConsumeEntries;
  DateTime? _pendingFixedIncomeApplyDate;
  DateTime? _pendingFixedConsumeApplyDate;
  DateTime? _pendingDailyConsumeApplyDate;
  final PlanPreviewService _previewService = const PlanPreviewService();

  // Getters for calculated values
  double get monthlyIncome => _pendingFixedIncomeEntries != null
      ? _sumEntries(_pendingFixedIncomeEntries!)
      : refData.primaryMonthlyIncomeSum;

  double get monthlyFixedCost => _pendingFixedConsumeEntries != null
      ? _sumEntries(_pendingFixedConsumeEntries!)
      : refData.primaryMonthlyConsumeSum;

  double get monthlyVariableCost => dailySpendingLimit * 30.0;

  double get monthlySaving =>
      monthlyIncome - monthlyFixedCost - monthlyVariableCost;

  double get dailySpendingLimit => _pendingDailyConsumeEntries != null
      ? _sumEntries(_pendingDailyConsumeEntries!)
      : refData.primaryDailyConsumeSum;

  List<Entry> get currentMonthlyIncomeEntries {
    final source =
        _pendingFixedIncomeEntries ?? refData.primaryMonthlyIncomeEntries;
    return source.map((e) => e.copyWith()).toList(growable: false);
  }

  List<Entry> get currentMonthlyConsumeEntries {
    final source =
        _pendingFixedConsumeEntries ?? refData.primaryMonthlyConsumeEntries;
    return source.map((e) => e.copyWith()).toList(growable: false);
  }

  List<Entry> get currentDailyConsumeEntries {
    final source =
        _pendingDailyConsumeEntries ?? refData.primaryDailyConsumeEntries;
    return source.map((e) => e.copyWith()).toList(growable: false);
  }

  DateTime? _overrideToday;
  DateTime get effectiveToday =>
      _overrideToday ?? _normalizeDay(DateTime.now());

  void setOverrideToday(DateTime date) {
    final normalized = _normalizeDay(date);
    if (_overrideToday == normalized) return;
    _overrideToday = normalized;
    refData.setReferenceDate(normalized);
    notifyListeners();
  }

  double? _tryParseTarget() =>
      double.tryParse(targetAmountController.text.replaceAll(',', ''));

  double? _tryParseCurrent() =>
      double.tryParse(currentAssetController.text.replaceAll(',', ''));

  // 입력 필드 파싱 getter
  double get parsedTarget => _tryParseTarget() ?? 0.0;
  double get parsedCurrent => _tryParseCurrent() ?? 0.0;

  SavingCalculationResult? _calculatePreviewResult() {
    if (_calculatorInputIssue() != null) {
      return null;
    }
    final dailyApplyDate = _pendingDailyConsumeEntries != null
        ? (_pendingDailyConsumeApplyDate ?? _defaultApplyDate())
        : null;
    return _previewCalculationFor(
      applyDate: _previewCalculationStart(dailyApplyDate: dailyApplyDate),
      dailyLimit: dailySpendingLimit,
      dailyApplyDate: dailyApplyDate,
    );
  }

  SavingCalculationResult? previewDailyEntries(List<Entry> entries) {
    if (_calculatorInputIssue() != null) {
      return null;
    }
    final dailyApplyDate = _defaultApplyDate();
    return _previewCalculationFor(
      applyDate: _previewCalculationStart(dailyApplyDate: dailyApplyDate),
      dailyLimit: _sumEntries(entries),
      dailyApplyDate: dailyApplyDate,
    );
  }

  SavingCalculationResult? _previewCalculationFor({
    required DateTime applyDate,
    required double dailyLimit,
    DateTime? dailyApplyDate,
  }) {
    final previewInput = PlanPreviewInput(
      plan: totalPlan,
      refData: refData,
      applyDate: applyDate,
      targetAmount: parsedTarget <= 0
          ? (totalPlan.targetAmount ?? 0).toDouble()
          : parsedTarget,
      currentAsset: parsedCurrent <= 0
          ? totalPlan.currentAsset.toDouble()
          : parsedCurrent,
      monthlyIncome: monthlyIncome,
      monthlyFixedCost: monthlyFixedCost,
      dailySpendingLimit: dailyLimit,
      monthlyIncomeApplyDate: _pendingFixedIncomeEntries != null
          ? _monthStart(_pendingFixedIncomeApplyDate ?? _defaultApplyDate())
          : null,
      monthlyFixedCostApplyDate: _pendingFixedConsumeEntries != null
          ? _monthStart(_pendingFixedConsumeApplyDate ?? _defaultApplyDate())
          : null,
      dailySpendingApplyDate: dailyApplyDate,
    );
    return _previewService.calculatePreview(previewInput);
  }

  // 일일 순저축(원/일)
  double get dailyNetSaving {
    final calc = _calculatePreviewResult();
    return calc?.dailyNetSaving ?? 0.0;
  }

  DateTime? get projectedGoalDate {
    final calc = _calculatePreviewResult();
    return calc?.goalDateTime;
  }

  // 목표까지 남은 일수 (저축 불가 or 목표 이하 → null)
  int? get daysToGoal {
    final calc = _calculatePreviewResult();
    if (calc == null) return null;
    if (calc.daysToGoal <= 0) return null;
    return calc.daysToGoal.ceil();
  }

  // 도달 예정일, 소요기간 문자열
  String? get reachDateStr {
    final goal = projectedGoalDate;
    if (goal == null) return null;
    return DateFormat('yyyy.MM.dd').format(goal);
  }

  String? get durationStr {
    final d = daysToGoal;
    if (d == null) return null;
    if (d <= 30) return '1개월 미만';
    final months = d ~/ 30;
    return '$months개월';
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
    planNameController = TextEditingController();
    targetAmountController = TextEditingController();
    currentAssetController = TextEditingController();

    final ref = initialRefData ?? RefData(planId: initialPlan.planId);
    ref.planId = initialPlan.planId;
    _applyPlanSnapshot(initialPlan, ref);

    // 🔔 실시간 반영: 입력 변화가 있을 때마다 화면 갱신
    _attachControllerListeners();

    notifyListeners();
  }

  void _applyPlanSnapshot(TotalPlan plan, RefData data) {
    totalPlan = plan;
    totalPlanVM = TotalPlanViewModel(plan);
    refData = data;
    refData.planId = plan.planId;
    refData.setReferenceDate(effectiveToday);
    refDataVM = RefDataViewModel(refData);
    _initialEndDate = plan.endDate;

    final formatter = NumberFormat('#,###');
    planNameController.text = plan.planName ?? '';
    targetAmountController.text = formatter.format(plan.targetAmount ?? 0);
    currentAssetController.text = formatter.format(plan.currentAsset);

    _pendingFixedIncomeEntries = null;
    _pendingFixedConsumeEntries = null;
    _pendingDailyConsumeEntries = null;
    _pendingFixedIncomeApplyDate = null;
    _pendingFixedConsumeApplyDate = null;
    _pendingDailyConsumeApplyDate = null;
  }

  void reloadWith({required TotalPlan plan, required RefData refData}) {
    _applyPlanSnapshot(plan, refData);
    notifyListeners();
  }

  void _detachControllerListeners() {
    planNameController.removeListener(_onFieldChanged);
    targetAmountController.removeListener(_onFieldChanged);
    currentAssetController.removeListener(_onFieldChanged);
  }

  // Entry 리스트 업데이트
  void applyFixedIncomeEdit({required List<Entry> entries}) {
    final normalized = _defaultApplyDate();
    _pendingFixedIncomeEntries = List<Entry>.unmodifiable(entries);
    _pendingFixedIncomeApplyDate = normalized;
    totalPlanVM.updateMetrics(monthlyIncome: _sumEntries(entries));
    totalPlan = totalPlanVM.plan;
    _logPlanTree('FixedIncome Edit');
    notifyListeners();
  }

  void applyFixedConsumeEdit({required List<Entry> entries}) {
    final normalized = _defaultApplyDate();
    _pendingFixedConsumeEntries = List<Entry>.unmodifiable(entries);
    _pendingFixedConsumeApplyDate = normalized;
    totalPlanVM.updateMetrics(monthlyConsume: _sumEntries(entries));
    totalPlan = totalPlanVM.plan;
    _logPlanTree('FixedConsume Edit');
    notifyListeners();
  }

  void applyDailyConsumeEdit({required List<Entry> entries}) {
    final normalized = _defaultApplyDate();
    _pendingDailyConsumeEntries = List<Entry>.unmodifiable(entries);
    _pendingDailyConsumeApplyDate = normalized;
    totalPlanVM.updateMetrics(dailyConsume: _sumEntries(entries));
    totalPlan = totalPlanVM.plan;
    _logPlanTree('DailyConsume Edit');
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
    var updated = totalPlanVM.plan;
    if (_initialEndDate != null) {
      updated = updated.copyWith(endDate: _initialEndDate);
      totalPlanVM.plan = updated;
    }
    totalPlan = updated;
    _logPlanTree('CreateUpdatedPlan');
    return totalPlan;
  }

  void _logPlanTree(String label) {
    debugPrint(
      '--- Plan Tree After $label ---\n'
      '${PlanDebugPrinter.describe(plan: totalPlan, refData: refData)}',
    );
  }

  void _ensurePlanExtendsThrough(DateTime targetDate) {
    final targetMonth = DateTime(targetDate.year, targetDate.month, 1);
    final planStart = totalPlan.startDate ?? targetDate;
    final merged = Map<String, SubPlan>.from(totalPlan.subPlans);
    final orderedKeys = merged.keys.toList()..sort();

    DateTime lastExistingMonth;
    if (orderedKeys.isEmpty) {
      lastExistingMonth = DateTime(planStart.year, planStart.month - 1, 1);
    } else {
      lastExistingMonth = _parseYearMonthKey(orderedKeys.last);
    }

    if (!targetMonth.isAfter(lastExistingMonth)) {
      return;
    }

    var cursor = DateTime(
      lastExistingMonth.year,
      lastExistingMonth.month + 1,
      1,
    );
    while (!cursor.isAfter(targetMonth)) {
      final key = _formatYearMonth(cursor);
      if (!merged.containsKey(key)) {
        final isPlanStartMonth =
            _isSameMonth(
              cursor,
              DateTime(planStart.year, planStart.month, 1),
            ) &&
            orderedKeys.isEmpty;
        final startDate = isPlanStartMonth ? planStart : cursor;
        final normalizedEnd = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
        );
        final endDate = _isSameMonth(cursor, targetMonth)
            ? normalizedEnd
            : DateTime(cursor.year, cursor.month + 1, 0);
        final fractionalSeconds = _isSameMonth(cursor, targetMonth)
            ? _fractionalFromDate(targetDate)
            : 0;
        merged[key] = _buildGeneratedSubPlan(
          monthStart: cursor,
          startDate: startDate,
          endDate: endDate,
          fractionalEndSeconds: fractionalSeconds,
        );
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    totalPlan = totalPlan
        .copyWith(
          subPlans: merged,
          // endDate는 최초 플랜 생성 시점의 목표 종료일을 보존해야 하므로
          // 여기서 덮어쓰지 않는다. modEndDate만 외부에서 업데이트된다.
        )
        .recalculateTotals();
    totalPlanVM = TotalPlanViewModel(totalPlan);
  }

  SubPlan _buildGeneratedSubPlan({
    required DateTime monthStart,
    required DateTime startDate,
    required DateTime endDate,
    required int fractionalEndSeconds,
  }) {
    final template = _latestMiniTemplate();
    final metrics = totalPlan.result.totalMetrics;
    final key = _formatYearMonth(monthStart);
    final miniId = '${key}_mini_auto';
    final mini = MiniPlan(
      docId: miniId,
      yearMonth: monthStart,
      startDate: startDate,
      endDate: endDate,
      monthlyIncomeId: template?.monthlyIncomeId ?? '${key}_income_auto',
      monthlyConsumeId: template?.monthlyConsumeId ?? '${key}_consume_auto',
      dailyConsumeId: template?.dailyConsumeId ?? '${key}_daily_auto',
      monthlyIncomeAmount:
          template?.monthlyIncomeAmount ?? metrics.monthlyIncomeAmount,
      monthlyConsumeAmount:
          template?.monthlyConsumeAmount ?? metrics.monthlyConsumeAmount,
      dailyConsumeAmount:
          template?.dailyConsumeAmount ?? metrics.dailyConsumeAmount,
    ).recalculateNetAmounts();
    return SubPlan(
      yearMonth: monthStart,
      headDocId: miniId,
      miniPlans: {miniId: mini},
      miniResult: MiniPlanResult(
        headDocId: miniId,
        miniMetrics: [mini.toMetrics()],
        miniPlanHead: mini,
      ),
      fractionalEndSeconds: fractionalEndSeconds,
    );
  }

  MiniPlan? _latestMiniTemplate() {
    if (totalPlan.subPlans.isEmpty) return null;
    final ordered = totalPlan.subPlans.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ordered.last.value.head;
  }

  String _formatYearMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}';

  DateTime _parseYearMonthKey(String key) {
    final year = int.parse(key.substring(0, 4));
    final month = int.parse(key.substring(4, 6));
    return DateTime(year, month, 1);
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  int _fractionalFromDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final seconds = date.difference(normalized).inSeconds;
    if (seconds <= 0) return 0;
    if (seconds >= 86399) return 86399;
    return seconds;
  }

  UpdateMonthlyCommand buildMonthlyCommand({
    // 월 단위 변경
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
    // 일 단위 변경
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

  DateTime _monthStart(DateTime value) => DateTime(value.year, value.month, 1);

  DateTime _defaultApplyDate() {
    final today = effectiveToday;
    final planStart = totalPlan.startDate;
    if (planStart == null) {
      return today;
    }
    final normalizedStart = _normalizeDay(planStart);
    return today.isBefore(normalizedStart) ? normalizedStart : today;
  }

  DateTime _previewCalculationStart({DateTime? dailyApplyDate}) {
    final candidates = <DateTime>[];
    if (_pendingFixedIncomeEntries != null) {
      candidates.add(
        _monthStart(_pendingFixedIncomeApplyDate ?? _defaultApplyDate()),
      );
    }
    if (_pendingFixedConsumeEntries != null) {
      candidates.add(
        _monthStart(_pendingFixedConsumeApplyDate ?? _defaultApplyDate()),
      );
    }
    if (dailyApplyDate != null) {
      candidates.add(_normalizeDay(dailyApplyDate));
    }
    if (candidates.isEmpty) {
      return _defaultApplyDate();
    }
    candidates.sort();
    final planStart = totalPlan.startDate;
    if (planStart == null) {
      return candidates.first;
    }
    final normalizedStart = _normalizeDay(planStart);
    return candidates.first.isBefore(normalizedStart)
        ? normalizedStart
        : candidates.first;
  }

  double _sumEntries(List<Entry> entries) =>
      entries.fold(0.0, (sum, e) => sum + e.amount);

  @visibleForTesting
  int debugRemainingTargetFor(DateTime applyDate) =>
      _previewService.remainingTargetFor(
        input: PlanPreviewInput(
          plan: totalPlan,
          refData: refData,
          applyDate: _normalizeDay(applyDate),
          targetAmount: parsedTarget <= 0
              ? (totalPlan.targetAmount ?? 0).toDouble()
              : parsedTarget,
          currentAsset: parsedCurrent <= 0
              ? totalPlan.currentAsset.toDouble()
              : parsedCurrent,
          monthlyIncome: monthlyIncome,
          monthlyFixedCost: monthlyFixedCost,
          dailySpendingLimit: dailySpendingLimit,
          monthlyIncomeApplyDate: _pendingFixedIncomeEntries != null
              ? _monthStart(_pendingFixedIncomeApplyDate ?? _defaultApplyDate())
              : null,
          monthlyFixedCostApplyDate: _pendingFixedConsumeEntries != null
              ? _monthStart(
                  _pendingFixedConsumeApplyDate ?? _defaultApplyDate(),
                )
              : null,
          dailySpendingApplyDate: _pendingDailyConsumeEntries != null
              ? (_pendingDailyConsumeApplyDate ?? _defaultApplyDate())
              : null,
        ),
        applyDate: _normalizeDay(applyDate),
      );

  PlanEditResult finalizeEdits() {
    //
    final projected =
        projectedGoalDate ??
        totalPlan.modEndDate ??
        totalPlan.endDate ??
        effectiveToday;

    _ensurePlanExtendsThrough(projected);

    totalPlanVM.plan = totalPlanVM.plan.copyWith(modEndDate: projected);
    totalPlan = totalPlanVM.plan;

    final projectedMonth = DateTime(projected.year, projected.month, 1);

    final monthlyCommands = <UpdateMonthlyCommand>[];
    final dailyCommands = <UpdateDailyCommand>[];
    DateTime? earliestApplyDate;

    void trackApplyDate(DateTime date) {
      final normalized = _normalizeDay(date);
      if (earliestApplyDate == null ||
          normalized.isBefore(earliestApplyDate!)) {
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
        earliestApplyDate ?? (totalPlan.startDate ?? effectiveToday);

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
  bool isValidForm() => getValidationError() == null;

  String? _calculatorInputIssue() {
    final targetParsed = _tryParseTarget();
    if (targetParsed == null) {
      return '목표 금액을 올바르게 입력해주세요';
    }
    if (targetParsed <= 0) {
      return '목표 금액은 0보다 커야 합니다';
    }
    final assetParsed = _tryParseCurrent();
    if (assetParsed == null) {
      return '보유 자산을 올바르게 입력해주세요';
    }
    if (monthlyIncome < 0) {
      return '월 수입은 0 이상이어야 합니다';
    }
    if (monthlyFixedCost < 0) {
      return '고정 소비는 0 이상이어야 합니다';
    }
    if (dailySpendingLimit < 0) {
      return '하루 사용 금액은 0 이상이어야 합니다';
    }
    return null;
  }

  // Get validation error message
  String? getValidationError() {
    if (planNameController.text.isEmpty) {
      return '플랜 이름을 입력해주세요';
    }
    return _calculatorInputIssue();
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

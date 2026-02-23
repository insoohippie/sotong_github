import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// UI
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_edit/edit_summary_tile.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/buttons/period_toggle.dart';
import '../../../component/chart/fl_donut_colored_budget.dart';
import '../../../component/theme/app_colors.dart';

// Models / VMs
import '../../../model/refData/entry.dart';
import '../../../model/plan/total_plan.dart';
import '../../../model/refData/ref_data.dart';
import '../../../repository/plan_repository.dart';
import '../../../repository/ref_data_repository.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../view_model/plan/plan_edit_viewmodel.dart';

// Modals
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_input_modal/input_modal_widget.dart';
import 'package:sotong_local/component/inputs/single_value_input_modal.dart';

class PlanEditPage extends StatefulWidget {
  final TotalPlan? initialPlan;
  final RefData? initialRefData;
  final bool useLocalDraft;
  final bool requireApplyDate;

  const PlanEditPage({
    Key? key,
    this.initialPlan,
    this.initialRefData,
    this.useLocalDraft = false,
    this.requireApplyDate = true,
  }) : super(key: key);

  @override
  State<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanEditPageState extends State<PlanEditPage> {
  int _selectedTabIndex = 0;
  final NumberFormat _nf = NumberFormat.decimalPattern('ko_KR');
  Future<_PlanEditInitData>? _initialFuture;
  TotalPlan? _basePlan;
  DateTime? _originalEndDate;

  @override
  void initState() {
    super.initState();
    if (widget.useLocalDraft) {
      _basePlan = widget.initialPlan;
      _originalEndDate = widget.initialPlan?.endDate;
    } else {
      _initialFuture = _loadInitialData();
    }
  }

  double _parseController(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '')) ?? 0.0;

  Future<_PlanEditInitData> _loadInitialData() async {
    final planRepo = context.read<PlanRepository>();
    final refRepo = context.read<RefDataRepository>();
    TotalPlan? plan =
        widget.initialPlan ?? await planRepo.getLatestPlanForCurrentUser();
    if (plan == null) {
      throw StateError('편집할 플랜이 없습니다.');
    }
    final refData = widget.initialRefData ?? await refRepo.loadAll();
    refData.planId = plan.planId;
    return _PlanEditInitData(plan: plan, refData: refData);
  }

  /// 저장 비활성 사유 (짧은 메시지)
  String? _blockingMessage(PlanEditViewModel vm) {
    final income = vm.monthlyIncome;
    final fixed = vm.monthlyFixedCost;
    final daily30 = vm.dailySpendingLimit * 30.0;
    final leftover = income - fixed;
    final monthlySaving = income - fixed - daily30;

    final target = _parseController(vm.targetAmountController);
    final current = _parseController(vm.currentAssetController);

    if (income <= 0) return '월 수입을 입력해주세요!';
    if (fixed > income ||
        daily30 > (leftover > 0 ? leftover : 0) ||
        monthlySaving <= 0) {
      return '소비가 수입을 초과했어요!';
    }
    if (target > 0 && current >= target) return '보유 자산이 목표 금액을 넘었어요!';
    return null;
  }

  // ----------------- 모달 -----------------
  Future<void> _openIncomeModal(
      BuildContext context,
      PlanEditViewModel vm,
      ) async {
    List<Entry>? stagedEntries;
    await showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          type: MaterialType.transparency,
          child: InputModalWidget(
            isOpen: true,
            onClose: () => Navigator.of(ctx).pop(),
            title: '월 수입 입력하기',
            placeholder: '수입 카테고리',
            type: EntryType.fixed,
            initialEntries: vm.currentMonthlyIncomeEntries,
            onComplete: (items, total) {
              stagedEntries = List<Entry>.from(items);
            },
          ),
        );
      },
    );
    if (!mounted || stagedEntries == null) return;

    final DateTime? applyDate = await _resolveApplyDate(
      vm: vm,
      title: '월 수입 적용일을 선택하세요',
      initialDate: vm.pendingFixedIncomeApplyDate ?? DateTime.now(),
    );
    if (applyDate == null) return;
    vm.applyFixedIncomeEdit(entries: stagedEntries!, applyDate: applyDate);
  }

  Future<void> _openFixedCostModal(
      BuildContext context,
      PlanEditViewModel vm,
      ) async {
    List<Entry>? stagedEntries;
    await showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          type: MaterialType.transparency,
          child: InputModalWidget(
            isOpen: true,
            onClose: () => Navigator.of(ctx).pop(),
            title: '고정 소비 입력하기',
            placeholder: '고정 소비 항목',
            type: EntryType.fixed,
            initialEntries: vm.currentMonthlyConsumeEntries,
            onComplete: (items, total) {
              stagedEntries = List<Entry>.from(items);
            },
          ),
        );
      },
    );
    if (!mounted || stagedEntries == null) return;

    final DateTime? applyDate = await _resolveApplyDate(
      vm: vm,
      title: '고정 소비 적용일을 선택하세요',
      initialDate: vm.pendingFixedConsumeApplyDate ?? DateTime.now(),
    );
    if (applyDate == null) return;
    vm.applyFixedConsumeEdit(entries: stagedEntries!, applyDate: applyDate);
  }

  Future<void> _openPlanNameModal(
      BuildContext context,
      PlanEditViewModel vm,
      ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleValueInputModal(
          hintText: '플랜 이름을 입력하세요',
          buttonTextEmpty: '플랜 이름을 입력해주세요!',
          buttonTextFilled: '이 이름으로 수정할게요!',
          initialValue: vm.planNameController.text,
          onComplete: (value) {
            vm.planNameController.text = value;
          },
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _openTargetAmountModal(
      BuildContext context,
      PlanEditViewModel vm,
      ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleValueInputModal(
          hintText: '목표 금액을 입력하세요',
          buttonTextEmpty: '목표 금액을 입력해주세요!',
          buttonTextFilled: '제 목표 금액이에요!',
          initialValue: vm.targetAmountController.text,
          isNumber: true,
          allowNegative: false,
          onComplete: (value) {
            vm.targetAmountController.text = value;
          },
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _openCurrentAssetModal(
      BuildContext context,
      PlanEditViewModel vm,
      ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleValueInputModal(
          hintText: '보유 자산을 입력하세요 (빚은 -로)',
          buttonTextEmpty: '보유 자산을 입력해주세요!',
          buttonTextFilled: '제 보유 자산이에요!',
          initialValue: vm.currentAssetController.text,
          isNumber: true,
          allowNegative: true,
          onComplete: (value) {
            vm.currentAssetController.text = value;
          },
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _openDailyModal(
      BuildContext context,
      PlanEditViewModel vm,
      ) async {
    List<Entry>? stagedEntries;
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        // ✅ 월 잔여 예산 = 월수입 - 고정소비 (음수면 0으로 보정)
        final double leftover = (vm.monthlyIncome - vm.monthlyFixedCost);
        final double availableMonthly = leftover > 0 ? leftover : 0.0;

        return Material(
          type: MaterialType.transparency,
          child: InputModalWidget(
            isOpen: true,
            onClose: () => Navigator.of(ctx).pop(),
            title: '하루 사용 금액',
            placeholder: '하루 소비 항목',
            type: EntryType.daily,
            initialEntries: vm.currentDailyConsumeEntries,
            monthlyIncome: availableMonthly,
            onComplete: (items, total) {
              stagedEntries = List<Entry>.from(items);
            },
          ),
        );
      },
    );
    if (!mounted || stagedEntries == null) return;

    final DateTime? applyDate = await _resolveApplyDate(
      vm: vm,
      title: '일일 소비 적용일을 선택하세요',
      initialDate: vm.pendingDailyConsumeApplyDate ?? DateTime.now(),
    );
    if (applyDate == null) return;
    vm.applyDailyConsumeEdit(entries: stagedEntries!, applyDate: applyDate);
  }

  // ----------------- 저장 -----------------
  Future<void> _save(PlanEditViewModel vm) async {
    final msg = _blockingMessage(vm);
    if (msg != null) return;

    final validationError = vm.getValidationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.redText,
        ),
      );
      return;
    }

    final plan = _basePlan ?? widget.initialPlan ?? vm.totalPlan;
    vm.createUpdatedPlan(plan);
    if (_originalEndDate != null) {
      vm.totalPlanVM.plan = vm.totalPlanVM.plan.copyWith(
        endDate: _originalEndDate,
      );
      vm.totalPlan = vm.totalPlanVM.plan;
    }

    final result = vm.finalizeEdits();
    Navigator.of(context).pop(result);
  }

  Future<DateTime?> _resolveApplyDate({
    required PlanEditViewModel vm,
    required String title,
    required DateTime initialDate,
  }) async {
    if (!widget.requireApplyDate) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    return _pickApplyDate(vm: vm, title: title, initialDate: initialDate);
  }

  Future<DateTime?> _pickApplyDate({
    required PlanEditViewModel vm,
    required String title,
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final startSource = vm.totalPlan.startDate ?? now;
    final planStart = DateTime(
      startSource.year,
      startSource.month,
      startSource.day,
    );
    final endSource =
        vm.projectedGoalDate ??
            vm.totalPlan.modEndDate ??
            vm.totalPlan.endDate ??
            startSource;
    DateTime planEnd = DateTime(endSource.year, endSource.month, endSource.day);
    if (planEnd.isBefore(planStart)) {
      planEnd = planStart;
    }

    DateTime initial = initialDate != null
        ? DateTime(initialDate.year, initialDate.month, initialDate.day)
        : DateTime(now.year, now.month, now.day);
    if (initial.isBefore(planStart)) {
      initial = planStart;
    }
    if (initial.isAfter(planEnd)) {
      initial = planEnd;
    }

    DateTime tempSelected = initial;

    final result = await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            height: 320,
            width: 320,
            child: CalendarDatePicker(
              initialDate: initial,
              firstDate: planStart,
              lastDate: planEnd,
              onDateChanged: (value) {
                tempSelected = value;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, tempSelected),
              child: const Text('적용'),
            ),
          ],
        );
      },
    );

    if (result == null) return null;
    return DateTime(result.year, result.month, result.day);
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    if (widget.useLocalDraft) {
      final plan = widget.initialPlan;
      final ref = widget.initialRefData;
      if (plan == null || ref == null) {
        return const Scaffold(body: Center(child: Text('편집할 플랜 데이터가 없습니다.')));
      }
      _basePlan = plan;
      _originalEndDate = plan.endDate;
      return _buildEditorScaffold(plan: plan, refData: ref);
    }
    _initialFuture ??= _loadInitialData();
    return FutureBuilder<_PlanEditInitData>(
      future: _initialFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.hasError) {
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const SizedBox.shrink(),
            ),
            body: Center(
              child: Text(
                snapshot.hasError
                    ? '플랜을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.'
                    : '편집할 플랜이 없습니다.',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Pretendard Variable',
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        _basePlan = data.plan;
        _originalEndDate = data.plan.endDate;
        return _buildEditorScaffold(plan: data.plan, refData: data.refData);
      },
    );
  }

  Widget _buildEditorScaffold({
    required TotalPlan plan,
    required RefData refData,
  }) {
    return ChangeNotifierProvider(
      create: (_) => PlanEditViewModel(plan, initialRefData: refData),
      child: Builder(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(overlayColor: Colors.transparent),
              ),
              title: const SizedBox.shrink(),
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  // 상단: 차트 또는 경고 배너(대체 표시) — 앱바 아래 여백 확보
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 45, 24, 20),
                    child: _SyncBridgeForChartOrAdvice(),
                  ),

                  _buildTabBar(),

                  // ▼▼▼ 스크롤 비활성화 (컨테이너 3개 고정) ▼▼▼
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Column(
                        children: [
                          IndexedStack(
                            index: _selectedTabIndex,
                            children: const [
                              _PlanBasicInfoTab(),
                              _UserInfoTab(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 저장 버튼
                  Consumer<PlanEditViewModel>(
                    builder: (context, vm, _) {
                      final canSave =
                          vm.isValidForm() && _blockingMessage(vm) == null;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: CustomButton(
                          text: '저장',
                          enabled: canSave,
                          onPressed: canSave ? () => _save(vm) : () {},
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------ 탭바 (공용 TwoOptionToggle) ------------
  static const _tabLabels = ['플랜 기본정보', '사용자 정보'];

  Widget _buildTabBar() {
    return Center(
      child: TwoOptionToggle(
        labels: _tabLabels,
        selected: _tabLabels[_selectedTabIndex],
        onChanged: (label) {
          setState(() => _selectedTabIndex = _tabLabels.indexOf(label));
        },
        width: 220,
        height: 30,
      ),
    );
  }
}

/// =========================
/// 차트 or 경고 배너 (대체 렌더)
/// =========================
class _SyncBridgeForChartOrAdvice extends StatefulWidget {
  const _SyncBridgeForChartOrAdvice({Key? key}) : super(key: key);

  @override
  State<_SyncBridgeForChartOrAdvice> createState() =>
      _SyncBridgeForChartOrAdviceState();
}

class _SyncBridgeForChartOrAdviceState
    extends State<_SyncBridgeForChartOrAdvice> {
  Timer? _debounce;
  String _lastSignature = '';

  /// 차트 애니메이션 종료 후 → 이 딜레이 후 목표일 텍스트 갱신
  static const _kTextUpdateDelay = Duration(milliseconds: 300);

  /// 차트 아래 텍스트용. 애니메이션 끝난 뒤에만 갱신 (애니메이션 나온 다음 텍스트 변경)
  _ChartSectionData? _displayDataForText;
  _ChartSectionData? _pendingTextData;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // 변경점 시그니처
  String _makeSignature(PlanEditViewModel vm) {
    double _parse(String s) => double.tryParse(s.replaceAll(',', '')) ?? 0.0;

    final inc = vm.monthlyIncome;
    final fix = vm.monthlyFixedCost;
    final dly = vm.dailySpendingLimit;
    final target = _parse(vm.targetAmountController.text);
    final current = _parse(vm.currentAssetController.text);

    double _sum(List<Entry> xs) => xs.fold(0.0, (p, e) => p + e.amount);
    return [
      inc.toStringAsFixed(2),
      fix.toStringAsFixed(2),
      dly.toStringAsFixed(2),
      target.toStringAsFixed(2),
      current.toStringAsFixed(2),
      vm.currentMonthlyIncomeEntries.length,
      _sum(vm.currentMonthlyIncomeEntries).toStringAsFixed(2),
      vm.currentMonthlyConsumeEntries.length,
      _sum(vm.currentMonthlyConsumeEntries).toStringAsFixed(2),
      vm.currentDailyConsumeEntries.length,
      _sum(vm.currentDailyConsumeEntries).toStringAsFixed(2),
    ].join('|');
  }

  void _syncNow(
      BuildContext context,
      PlanEditViewModel editVM,
      ChatPlanViewModel chatVM,
      ) {
    double _parse(String s) => double.tryParse(s.replaceAll(',', '')) ?? 0.0;

    chatVM.updatePlanInfo(
      planName: editVM.planNameController.text,
      targetAmount: _parse(editVM.targetAmountController.text),
      currentAsset: _parse(editVM.currentAssetController.text),
      fixedIncomeSum: editVM.monthlyIncome,
      fixedConsumptionSum: editVM.monthlyFixedCost,
      dailyConsumptionSum: editVM.dailySpendingLimit,
    );
    chatVM.calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlanEditViewModel, ChatPlanViewModel>(
      builder: (context, editVM, chatVM, _) {
        final sig = _makeSignature(editVM);
        if (sig != _lastSignature) {
          _lastSignature = sig;
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 80), () {
            if (mounted) _syncNow(context, editVM, chatVM);
          });
        }

        chatVM.calculationResult ?? chatVM.calculate();

        return Selector<PlanEditViewModel, _ChartSectionData>(
          selector: (_, vm) => _ChartSectionData.from(vm),
          shouldRebuild: (a, b) => a != b,
          builder: (_, data, __) {
            if (_displayDataForText == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _displayDataForText = data);
              });
            } else if (data != _displayDataForText) {
              _pendingTextData = data;
            }
            final textData = _displayDataForText ?? data;

            return RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FlDonutColoredBudgetChart(
                    income: data.income,
                    fixed: data.fixed,
                    variable: data.variableCost,
                    saving: data.savingForChart,
                    centerSpace: 30,
                    chartHeight: 120,
                    isOverBudget: data.isOverBudget,
                    animationTrigger:
                    '${data.reachDateStr}_${data.durationStr}',
                    onEnterComplete: () {
                      if (!mounted) return;
                      Future.delayed(_kTextUpdateDelay, () {
                        if (!mounted) return;
                        setState(() {
                          if (_pendingTextData != null) {
                            _displayDataForText = _pendingTextData;
                            _pendingTextData = null;
                          }
                        });
                      });
                    },
                  ),
                  const SizedBox(height: 60),

                  if (textData.isOverBudget)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '월수입보다 월 소비가 더 많아요 😢',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Pretendard Variable',
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _PlanStatsBelowChart(
                      reachDateStr: textData.reachDateStr,
                      durationStr: textData.durationStr,
                      canSave: textData.canSave,
                      hasGoal: textData.hasGoal,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 차트 영역이 이 데이터가 바뀔 때만 다시 그려지도록 (불필요한 리빌드·버벅임 방지)
class _ChartSectionData {
  const _ChartSectionData({
    required this.income,
    required this.fixed,
    required this.variableCost,
    required this.savingForChart,
    required this.isOverBudget,
    required this.reachDateStr,
    required this.durationStr,
    required this.canSave,
    required this.hasGoal,
  });

  final double income;
  final double fixed;
  final double variableCost;
  final double savingForChart;
  final bool isOverBudget;
  final String? reachDateStr;
  final String? durationStr;
  final bool canSave;
  final bool hasGoal;

  static _ChartSectionData from(PlanEditViewModel vm) {
    final income = vm.monthlyIncome;
    final fixed = vm.monthlyFixedCost;
    final daily30 = vm.dailySpendingLimit * 30.0;
    final isOverBudget = income > 0 && (income - fixed - daily30) < 0;
    final savingForChart = isOverBudget
        ? 0.0
        : ((income - fixed - daily30) > 0 ? (income - fixed - daily30) : 0.0);
    return _ChartSectionData(
      income: income,
      fixed: fixed,
      variableCost: daily30,
      savingForChart: savingForChart,
      isOverBudget: isOverBudget,
      reachDateStr: vm.reachDateStr,
      durationStr: vm.durationStr,
      canSave: vm.dailyNetSaving > 0,
      hasGoal: vm.parsedTarget > vm.parsedCurrent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _ChartSectionData &&
              income == other.income &&
              fixed == other.fixed &&
              variableCost == other.variableCost &&
              savingForChart == other.savingForChart &&
              isOverBudget == other.isOverBudget &&
              reachDateStr == other.reachDateStr &&
              durationStr == other.durationStr &&
              canSave == other.canSave &&
              hasGoal == other.hasGoal;

  @override
  int get hashCode => Object.hash(
    income,
    fixed,
    variableCost,
    savingForChart,
    isOverBudget,
    reachDateStr,
    durationStr,
    canSave,
    hasGoal,
  );
}

/// =========================
/// 탭 1: 플랜 기본정보 (탭 → 모달)
/// =========================
class _PlanBasicInfoTab extends StatelessWidget {
  const _PlanBasicInfoTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final page = context.findAncestorStateOfType<_PlanEditPageState>()!;
    return Consumer<PlanEditViewModel>(
      builder: (context, vm, _) {
        final targetStr = vm.targetAmountController.text;
        final assetStr = vm.currentAssetController.text;
        final planName = vm.planNameController.text.trim();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _BasicInfoTile(
                label: '플랜 이름',
                value: planName.isEmpty ? '입력 안 함' : planName,
                onTap: () => page._openPlanNameModal(context, vm),
              ),
              _BasicInfoTile(
                label: '목표 금액',
                value: '${targetStr.isEmpty ? '0' : targetStr}원',
                onTap: () => page._openTargetAmountModal(context, vm),
              ),
              _BasicInfoTile(
                label: '보유 자산',
                value: '${assetStr.isEmpty ? '0' : assetStr}원',
                onTap: () => page._openCurrentAssetModal(context, vm),
                showDivider: false,
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

/// 기본정보 탭용 탭 가능한 행 (값 표시 + 탭 시 모달)
class _BasicInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;

  const _BasicInfoTile({
    Key? key,
    required this.label,
    required this.value,
    required this.onTap,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputBg = isDark
        ? theme.colorScheme.surface
        : AppColors.greyBackground;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard Variable',
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Pretendard Variable',
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (showDivider) Divider(height: 5, color: theme.dividerColor),
        ],
      ),
    );
  }
}

/// =========================
/// 탭 2: 사용자 정보 (EditSummaryTile)
/// =========================
class _UserInfoTab extends StatelessWidget {
  const _UserInfoTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final page = context.findAncestorStateOfType<_PlanEditPageState>()!;
    return Consumer<PlanEditViewModel>(
      builder: (context, vm, _) {
        final income = vm.monthlyIncome;
        final fixed = vm.monthlyFixedCost;
        final daily30 = vm.dailySpendingLimit * 30.0;
        final hasSavings = income > 0 && (income - fixed - daily30) >= 0;
        final labelColor = hasSavings ? AppColors.primary : AppColors.redText;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              EditSummaryTile(
                label: '월 수입',
                total: vm.monthlyIncome,
                onEdit: () => page._openIncomeModal(context, vm),
                labelColor: labelColor,
              ),
              EditSummaryTile(
                label: '고정 소비',
                total: vm.monthlyFixedCost,
                onEdit: () => page._openFixedCostModal(context, vm),
                labelColor: labelColor,
              ),
              EditSummaryTile(
                label: '하루 소비 한도 금액',
                total: vm.dailySpendingLimit,
                unit: '원',
                onEdit: () => page._openDailyModal(context, vm),
                showDivider: false,
                labelColor: labelColor,
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

/// =========================
/// 차트 하단 한 줄 (목표 도달 예정일 텍스트)
/// =========================
class _PlanStatsBelowChart extends StatelessWidget {
  final String? reachDateStr;
  final String? durationStr;
  final bool hasGoal;
  final bool canSave;

  const _PlanStatsBelowChart({
    Key? key,
    required this.reachDateStr,
    required this.durationStr,
    required this.hasGoal,
    required this.canSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final show =
        hasGoal && canSave && reachDateStr != null && durationStr != null;

    if (show) {
      return Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Pretendard Variable',
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
                children: [
                  const TextSpan(text: '목표 도달 예정일: '),
                  TextSpan(
                    text: reachDateStr!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard Variable',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _PlanEditInitData {
  const _PlanEditInitData({required this.plan, required this.refData});

  final TotalPlan plan;
  final RefData refData;
}

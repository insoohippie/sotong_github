import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// UI
import 'package:sotong_local/component/appbars/custom_app_bar.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/view/pages/plan/plan_edit_widgets/edit_summary_tile.dart';
import 'package:sotong_local/view/pages/plan/plan_edit_widgets/minimal_field.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/chart/animated_budget_bar_chart.dart';
import '../../../component/theme/app_colors.dart';

// Models / VMs
import '../../../model/entry.dart';
import '../../../model/plan_info.dart';
import '../../../model/ref_data.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../view_model/plan/plan_edit_viewmodel.dart';

// Modals
import 'chat_widgets/input_modal/input_modal_widget.dart';

class PlanEditPage extends StatefulWidget {
  final PlanInfo initialPlan;
  final RefData initialRefData;

  const PlanEditPage({
    Key? key,
    required this.initialPlan,
    required this.initialRefData,
  }) : super(key: key);

  @override
  State<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanEditPageState extends State<PlanEditPage> {
  int _selectedTabIndex = 0;
  final NumberFormat _nf = NumberFormat.decimalPattern('ko_KR');

  @override
  void initState() {
    super.initState();
  }

  double _parseController(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '')) ?? 0.0;

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
    if (fixed > income || daily30 > (leftover > 0 ? leftover : 0) || monthlySaving <= 0) {
      return '소비가 수입을 초과했어요!';
    }
    if (target > 0 && current >= target) return '보유 자산이 목표 금액을 넘었어요!';
    return null;
  }

  // ----------------- 모달 -----------------
  Future<void> _openIncomeModal(BuildContext context, PlanEditViewModel vm) async {
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
            initialEntries: vm.refData.fixedIncomes,
            onComplete: (items, total) {
              context.read<PlanEditViewModel>().updateFixedIncomeEntries(items);
            },
          ),
        );
      },
    );
  }

  Future<void> _openFixedCostModal(BuildContext context, PlanEditViewModel vm) async {
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
            initialEntries: vm.refData.fixedConsumptions,
            onComplete: (items, total) {
              context.read<PlanEditViewModel>().updateFixedCostEntries(items);
            },
          ),
        );
      },
    );
  }

  Future<void> _openDailyModal(BuildContext context, PlanEditViewModel vm) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          type: MaterialType.transparency,
          child: InputModalWidget(
            isOpen: true,
            onClose: () => Navigator.of(ctx).pop(),
            title: '하루 사용 금액',
            placeholder: '하루 소비 항목',
            type: EntryType.daily,
            initialEntries: vm.refData.dailyConsumptions,
            isEditMode: true,
            onComplete: (items, total) {
              context.read<PlanEditViewModel>().updateDailyCostEntries(items);
            },
          ),
        );
      },
    );
  }

  // ----------------- 저장 -----------------
  void _save(PlanEditViewModel vm) {
    final msg = _blockingMessage(vm);
    if (msg != null) return;

    final validationError = vm.getValidationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: AppColors.redText),
      );
      return;
    }

    final updated = vm.createUpdatedPlan(widget.initialPlan);
    Navigator.of(context).pop(updated);
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanEditViewModel(
        widget.initialPlan,
        initialRefData: widget.initialRefData,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const CustomAppBar(title: '저축 플랜 수정'),

              // 상단: 차트 또는 경고 배너(대체 표시)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: _SyncBridgeForChartOrAdvice(),
              ),

              _buildTabBar(),

              // ▼▼▼ 스크롤 가능한 영역 ▼▼▼
              Expanded(
                child: Scrollbar(
                  thumbVisibility: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: IndexedStack(
                            index: _selectedTabIndex,
                            children: const [
                              _PlanBasicInfoTab(),
                              _UserInfoTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 저장 버튼
              Consumer<PlanEditViewModel>(
                builder: (context, vm, _) {
                  final canSave = vm.isValidForm() && _blockingMessage(vm) == null;
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
      ),
    );
  }

  // ------------ 탭바 ------------
  Widget _buildTabBar() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: _buildTabButton('플랜 기본정보', 0)),
            Expanded(child: _buildTabButton('사용자 정보', 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : const Color(0xFF6C757D),
          ),
        ),
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
  State<_SyncBridgeForChartOrAdvice> createState() => _SyncBridgeForChartOrAdviceState();
}

class _SyncBridgeForChartOrAdviceState extends State<_SyncBridgeForChartOrAdvice> {
  Timer? _debounce;
  String _lastSignature = '';

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
      vm.refData.fixedIncomes.length,
      _sum(vm.refData.fixedIncomes).toStringAsFixed(2),
      vm.refData.fixedConsumptions.length,
      _sum(vm.refData.fixedConsumptions).toStringAsFixed(2),
      vm.refData.dailyConsumptions.length,
      _sum(vm.refData.dailyConsumptions).toStringAsFixed(2),
    ].join('|');
  }

  void _syncNow(BuildContext context, PlanEditViewModel editVM, ChatPlanViewModel chatVM) {
    double _parse(String s) => double.tryParse(s.replaceAll(',', '')) ?? 0.0;

    chatVM.updatePlanInfo(
      planName: editVM.planNameController.text,
      targetAmount: _parse(editVM.targetAmountController.text),
      currentAsset: _parse(editVM.currentAssetController.text),
      fixedIncomeSum: editVM.monthlyIncome,
      fixedConsumptionSum: editVM.monthlyFixedCost,
      dailyConsumptionSum: editVM.dailySpendingLimit,
    );
    chatVM.updateRefData(
      fixedIncomes: editVM.refData.fixedIncomes,
      fixedConsumptions: editVM.refData.fixedConsumptions,
      dailyConsumptions: editVM.refData.dailyConsumptions,
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

        final calc = chatVM.calculationResult ?? chatVM.calculate();

        // 문제 여부 판정
        final income = editVM.monthlyIncome;
        final fixed = editVM.monthlyFixedCost;
        final daily30 = editVM.dailySpendingLimit * 30.0;
        final leftover = income - fixed;
        final monthlySaving = income - fixed - daily30;

        double _parse(String s) => double.tryParse(s.replaceAll(',', '')) ?? 0.0;
        final target = _parse(editVM.targetAmountController.text);
        final current = _parse(editVM.currentAssetController.text);

        final List<_AdviceItem> issues = [];
        String _fmt(num v) => NumberFormat.decimalPattern('ko_KR').format(v.round());

        if (income <= 0) {
          issues.add(_AdviceItem(
            title: '월 수입이 0원이에요.',
            tips: const ['수입 항목을 입력해 주세요', '정확한 금액이 어렵다면 추정치로 입력도 OK'],
          ));
        }
        if (fixed > income) {
          issues.add(_AdviceItem(
            title: '고정소비가 수입을 초과했어요.',
            subtitle: '고정소비 ${_fmt(fixed)}원 > 수입 ${_fmt(income)}원',
            tips: const ['고정 소비 점검', '수입 항목 추가 고려'],
          ));
        } else if (daily30 > (leftover > 0 ? leftover : 0)) {
          issues.add(_AdviceItem(
            title: '하루 소비(×30)가 남는 금액을 초과했어요.',
            subtitle: '남는 금액 ${_fmt(leftover)}원, 변동소비 ${_fmt(daily30)}원',
            tips: const ['하루 한도를 낮추기', '고정소비 줄이기', '수입 늘리기 검토'],
          ));
        } else if (monthlySaving <= 0) {
          issues.add(_AdviceItem(
            title: '현재 설정으로 월 저축액이 0원 이하예요.',
            subtitle: '월저축 = 수입 − 고정 − 변동',
            tips: const ['하루 한도를 5~10% 낮추기', '불필요한 구독/고정비 정리'],
          ));
        }
        if (target > 0 && current >= target) {
          issues.add(_AdviceItem(
            title: '보유 자산이 목표 금액을 넘었어요.',
            subtitle: '보유 ${_fmt(current)}원 ≥ 목표 ${_fmt(target)}원',
            tips: const ['목표 금액 상향', '해당 목표 달성 처리'],
          ));
        }

        if (issues.isNotEmpty) {
          return _BudgetAdviceBanner(items: issues);
        }

        return RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedBudgetBarChart(
                planInfo: chatVM.planInfo,
                calculation: calc,
                height: 20,
                showPercentages: true,
                animationDuration: const Duration(milliseconds: 1200),
              ),
              const SizedBox(height: 12),

              // ⬇️ 여기를 수정: chatVM이 아닌 editVM에서 바로 읽기
              _PlanStatsBelowChart(
                reachDateStr: editVM.reachDateStr,
                durationStr: editVM.durationStr,
                canSave: editVM.dailyNetSaving > 0,
                hasGoal: (editVM.parsedTarget > editVM.parsedCurrent),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// =========================
/// 탭 1: 플랜 기본정보
/// =========================
class _PlanBasicInfoTab extends StatelessWidget {
  const _PlanBasicInfoTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlanEditViewModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              MinimalField(
                label: '플랜 이름',
                controller: vm.planNameController,
                hint: '예: 여름휴가 프로젝트',
                onChanged: (_) {}, // 리스너가 이미 notify 처리
              ),
              MinimalField(
                label: '목표 금액',
                controller: vm.targetAmountController,
                isNumber: true,
                hint: '예: 10,000,000',
                onChanged: (_) {},
              ),
              MinimalField(
                label: '보유 자산',
                controller: vm.currentAssetController,
                isNumber: true,
                hint: '예: 5,000,000 또는 -300,000',
                onChanged: (_) {},
              ),
            ],
          ),
        );
      },
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              EditSummaryTile(
                label: '월 수입',
                total: vm.monthlyIncome,
                onEdit: () => page._openIncomeModal(context, vm),
              ),
              EditSummaryTile(
                label: '고정 소비',
                total: vm.monthlyFixedCost,
                onEdit: () => page._openFixedCostModal(context, vm),
              ),
              EditSummaryTile(
                label: '하루 소비 한도 금액',
                total: vm.dailySpendingLimit,
                unit: '원',
                onEdit: () => page._openDailyModal(context, vm),
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
/// 경고 배너 + 아이템
/// =========================
class _BudgetAdviceBanner extends StatelessWidget {
  final List<_AdviceItem> items;
  const _BudgetAdviceBanner({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text(
                '예산을 조정해 주세요',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.take(3).map((e) => _AdviceTile(item: e)),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '외 ${items.length - 3}개 항목 더 있음',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdviceItem {
  final String title;
  final String? subtitle;
  final List<String> tips;
  _AdviceItem({required this.title, this.subtitle, required this.tips});
}

class _AdviceTile extends StatelessWidget {
  final _AdviceItem item;
  const _AdviceTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubText(text: item.title, fontWeight: FontWeight.bold, color: Colors.black),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  SubText(text: item.subtitle!),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: item.tips.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SubText(text: t, color: AppColors.redText),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================
/// 차트 하단 한 줄 3타일
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
    Widget tile(String title, String value, {Color? valueColor}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubText(text: title, fontWeight: FontWeight.bold),
              const SizedBox(height: 6),
              SubText(
                text: value,
                color: valueColor ?? Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
      );
    }

    final show = hasGoal && canSave && reachDateStr != null && durationStr != null;

    if (show) {
      return Row(
        children: [
          tile('목표 도달 예정일', reachDateStr!),
          const SizedBox(width: 8),
          tile('예상 소요 기간', durationStr!),
        ],
      );
    }

    // 표시 조건이 안 되면 빈 자리
    return const SizedBox.shrink();
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/plan_summary_chart_widget.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/plan_summary_donut_chart_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ───────── 너의 실제 경로로 맞춰줘
import 'package:sotong_local/model/plan_info.dart';
import 'package:sotong_local/model/saving_calculation_result.dart';

import 'component/chart/fl_donut_budget_chart.dart';


// ─────────────────────────────────────────────────────────────────────────────
// 4) 모두 한 화면에서 보기: BudgetPieChartSyncfusion + PlanSummaryChartWidget
// ─────────────────────────────────────────────────────────────────────────────
class BudgetAllWidgetsSandboxPage extends StatefulWidget {
  BudgetAllWidgetsSandboxPage({super.key});
  @override
  State<BudgetAllWidgetsSandboxPage> createState() => _BudgetAllWidgetsSandboxPageState();
}

class _BudgetAllWidgetsSandboxPageState extends State<BudgetAllWidgetsSandboxPage> {
  late PlanInfo plan;
  late SavingCalculationResult calc;

  @override
  void initState() {
    super.initState();

    plan = PlanInfo()
      ..planName = '유럽여행'
      ..targetAmount = 5_000_000
      ..currentAsset = 1_200_000
      ..fixedIncomeSum = 2_000_000
      ..fixedConsumptionSum = 800_000
      ..dailyConsumptionSum = 4_000
      ..variableConsumptionSum = 0
      ..autoService = true;

    final income   = plan.fixedIncomeSum?.toInt() ?? 0;
    final fixed    = plan.fixedConsumptionSum?.toInt() ?? 0;
    final variable = ((plan.dailyConsumptionSum ?? 0) * 30).toInt();
    final saving   = (income - fixed - variable).clamp(0, income);

    final dailySaving    = income == 0 ? 0.0 : saving / 30.0;
    final requiredSaving = (plan.targetAmount ?? 0) - (plan.currentAsset ?? 0);
    final daysToGoal     = dailySaving > 0 ? (requiredSaving / dailySaving) : 0;
    final goalDate       = DateTime.now().add(Duration(days: daysToGoal.ceil()));

    calc = SavingCalculationResult(
      monthlySaving: saving.toDouble(),
      dailySaving: dailySaving.toDouble(),
      savingRatio: income == 0 ? 0 : saving / income,
      dailyNetSaving: dailySaving.toDouble(),
      requiredSaving: requiredSaving.toDouble(),
      daysToGoal: daysToGoal.toDouble(),
      totalSeconds: (daysToGoal * 24 * 60 * 60).toDouble(),
      goalDateTime: goalDate,
      savingPerSecond: dailySaving / (24 * 60 * 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income   = plan.fixedIncomeSum?.toDouble() ?? 0;
    final fixed    = plan.fixedConsumptionSum?.toDouble() ?? 0;
    final variable = ((plan.dailyConsumptionSum ?? 0) * 30).toDouble();
    final saving   = calc.monthlySaving;

    return Scaffold(
      appBar: AppBar(title: Text('All Budget Widgets (Scroll Demo)')),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PlanSummaryPieChartWidget(
              //   planInfo: plan,
              //   calculation: calc,
              //   userName: '하경',
              //   onEdit: () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(content: Text('수정하기 눌림!')),
              //     );
              //   },
              // ),
              _card(
                '기존 Plan Summary',
                PlanSummaryChartWidget(
                  planInfo: plan,
                  calculation: calc,
                  userName: '하경',
                  onEdit: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('수정하기 눌림!')),
                    );
                  },
                ),
                height: 500,
              ),
              const SizedBox(height: 16),

              // ✅ 새로 추가: fl_chart 도넛 차트
              _card(
                'fl_chart • 도넛 차트(금액 라벨 + 텍스트 배지)',
                PlanSummaryDonutChartWidget(
                  planInfo: plan,
                  calculation: calc,
                  userName: '하경',
                  onEdit: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('수정하기 눌림!')),
                    );
                  },
                ),
                height: 500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, Widget child, {double height = 260}) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Divider(height: 1),
              SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

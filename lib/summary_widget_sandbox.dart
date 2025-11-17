import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sotong_local/model/plan/plan_metrics.dart';
import 'package:sotong_local/model/plan/sub_plan.dart';
import 'package:sotong_local/model/plan/total_plan.dart';
import 'package:sotong_local/model/saving_calculation_result.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/plan_summary_chart_widget.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/plan_summary_donut_chart_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


// ─────────────────────────────────────────────────────────────────────────────
// 4) 모두 한 화면에서 보기: BudgetPieChartSyncfusion + PlanSummaryChartWidget
// ─────────────────────────────────────────────────────────────────────────────
class BudgetAllWidgetsSandboxPage extends StatefulWidget {
  const BudgetAllWidgetsSandboxPage({super.key});
  @override
  State<BudgetAllWidgetsSandboxPage> createState() => _BudgetAllWidgetsSandboxPageState();
}

class _BudgetAllWidgetsSandboxPageState extends State<BudgetAllWidgetsSandboxPage> {
  // fl_chart touched indices
  int touchedIndexSolid = -1;
  int touchedIndexDonut = -1;
  int touchedIndexTiny = -1;

  // 팔레트(연→중→진 파랑)
  final Color colorFixed = const Color(0xFFB9D2FF);    // 고정지출
  final Color colorVariable = const Color(0xFF8BB8FF); // 변동지출
  final Color colorSaving = const Color(0xFF3C7BFF);   // 저축

  // 데이터
  late final TotalPlan plan;
  late final SavingCalculationResult calc;

  // Syncfusion
  late final TooltipBehavior _sfTooltip;

  @override
  void initState() {
    super.initState();

    final metrics = PlanMetrics.fromRange(
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 29)),
      sumMonthlyIncome: 2000000,
      sumMonthlyConsume: 800000,
      sumDailyConsume: 20000,
    );
    plan = TotalPlan(
      planId: 'sandbox',
      planName: '유럽여행',
      targetAmount: 5000000,
      currentAmount: 0,
      currentAsset: 1200000,
      startDate: DateTime.now(),
      endDate: null,
      modEndDate: null,
      creationDate: DateTime.now(),
      autoService: true,
      subPlans: const {},
      result: TotalResult(
        totalMetrics: metrics,
        subResult: const SubPlanResult(subMetrics: [], subPlanList: []),
      ),
    );

    final totalMetrics = plan.result.totalMetrics;
    final income = totalMetrics.sumMonthlyIncome;
    final fixedC = totalMetrics.sumMonthlyConsume;
    final variableC = (totalMetrics.sumDailyConsume * 30);
    final saving = (income - fixedC - variableC).clamp(0, income);

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

    _sfTooltip = TooltipBehavior(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = plan.result.totalMetrics;
    final income = metrics.sumMonthlyIncome.toDouble();
    final fixedVal = metrics.sumMonthlyConsume.toDouble();
    final variableVal = (metrics.sumDailyConsume * 30).toDouble();
    final double savingVal = (calc.monthlySaving).clamp(0, income);

    // Syncfusion 데이터 공통 (x=라벨, y=금액)
    final sfData = [
      _SFItem('고정', fixedVal, colorFixed),
      _SFItem('변동', variableVal, colorVariable),
      _SFItem('저축', savingVal, colorSaving),
    ];

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
                  plan: plan,
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
                  plan: plan,
                  calculation: calc,
                  userName: '하경',
                  onEdit: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('수정하기 눌림!')),
                    );
                  },
                ),
                height: 260,
              ),
              SizedBox(height: 14),

              // ───────── Syncfusion 2) Radial Bar
              _whiteCard(
                'Syncfusion • Radial Bar (만원 라벨, 최대=수입)',
                SfCircularChart(
                  tooltipBehavior: _sfTooltip,
                  legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                  series: <RadialBarSeries<_SFItem, String>>[
                    RadialBarSeries<_SFItem, String>(
                      dataSource: sfData,
                      xValueMapper: (_SFItem d, _) => d.x,
                      yValueMapper: (_SFItem d, _) => d.y,
                      pointColorMapper: (_SFItem d, _) => d.color,
                      maximumValue: metrics.sumMonthlyIncome.toDouble(),
                      cornerStyle: CornerStyle.bothCurve,
                      gap: '8%',
                      radius: '90%',
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.inside,
                        textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        useSeriesColor: false,
                      ),
                      dataLabelMapper: (_SFItem d, _) => '${d.x} ${_manWon(d.y)}',
                    ),
                  ],
                ),
                height: 320,
              ),
              SizedBox(height: 14),

              // ───────── Syncfusion 3) Pie
              _whiteCard(
                'Syncfusion • Pie (만원 라벨, 작은 조각은 바깥)',
                SfCircularChart(
                  tooltipBehavior: _sfTooltip,
                  // smartLabelMode: SmartLabelMode.shift, // 겹치면 자동 이동
                  legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                  series: <PieSeries<_SFItem, String>>[
                    PieSeries<_SFItem, String>(
                      dataSource: sfData,
                      xValueMapper: (_SFItem d, _) => d.x,
                      yValueMapper: (_SFItem d, _) => d.y,
                      pointColorMapper: (_SFItem d, _) => d.color,
                      explode: true,
                      explodeIndex: 0,
                      startAngle: 90,
                      endAngle: 90,
                      dataLabelMapper: (_SFItem d, _) => '${d.x}\n${_manWon(d.y)}',
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside, // 항상 바깥
                        connectorLineSettings: ConnectorLineSettings(
                          type: ConnectorType.curve,
                          length: '10%',
                          width: 1.5,
                        ),
                        textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      onPointTap: (ChartPointDetails details) {
                        setState(() {
                          // 터치한 조각 explode
                          // (SfPie는 한 번에 하나씩만 터뜨리고 싶으면 selectionBehavior 사용 가능)
                        });
                      },
                    ),
                  ],
                ),
                height: 320,
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

  Widget _whiteCard(String title, Widget child, {double height = 260}) {
    return Card(
      color: Colors.white,
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  String _manWon(double value) {
    if (value == 0) return '0원';
    final double man = value / 10000;
    final bool needDecimal = man < 10;
    final String formatted = needDecimal ? man.toStringAsFixed(1) : man.toStringAsFixed(0);
    return '$formatted만';
  }
}

class _SFItem {
  final String x;
  final double y;
  final Color color;

  const _SFItem(this.x, this.y, this.color);
}

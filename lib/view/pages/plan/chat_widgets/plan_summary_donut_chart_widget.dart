import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/model/plan/plan_metrics.dart';
import 'package:sotong_local/model/plan/total_plan.dart';
import 'package:sotong_local/model/saving_calculation_result.dart';

// 차트 파일 경로 맞춰서!
import '../../../../component/chart/fl_donut_budget_chart.dart';
import '../../../../component/chart/fl_donut_colored_budget.dart';
import '../../../../component/theme/app_colors.dart';

class PlanSummaryDonutChartWidget extends StatefulWidget {
  final TotalPlan plan;
  final SavingCalculationResult? calculation;
  final VoidCallback? onEdit;
  final String userName;

  const PlanSummaryDonutChartWidget({
    super.key,
    required this.plan,
    required this.calculation,
    this.onEdit,
    required this.userName,
  });

  @override
  State<PlanSummaryDonutChartWidget> createState() => _PlanSummaryDonutChartWidgetState();
}

class _PlanSummaryDonutChartWidgetState extends State<PlanSummaryDonutChartWidget> {
  Timer? _ticker;

  PlanMetrics get _metrics => widget.plan.result.totalMetrics;

  double get monthlyIncome => _metrics.sumMonthlyIncome.toDouble();
  double get monthlyFixedCost => _metrics.sumMonthlyConsume.toDouble();
  double get dailySpendingLimit => _metrics.sumDailyConsume.toDouble();
  double get monthlyVariableCost => dailySpendingLimit * 30;
  double get monthlySaving => widget.calculation?.monthlySaving ?? 0;

  final _chartKey = GlobalKey<FlDonutBudgetChartState>();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalDate = widget.calculation?.goalDateTime ?? DateTime.now();
    final remain = goalDate.difference(DateTime.now());
    final days = remain.inDays;
    final hours = remain.inHours % 24;
    final minutes = remain.inMinutes % 60;
    final seconds = remain.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 36),
          FlDonutColoredBudgetChart(
            key: _chartKey,
            income: monthlyIncome,
            fixed: monthlyFixedCost,
            variable: monthlyVariableCost,
            saving: monthlySaving,
            chartHeight: 180,
            centerSpace: 30,
            minRatio: 0.15,
          ),

          const SizedBox(height: 50),

          // 목표/카운트다운
          Center(
            child: Column(
              children: [
                ParagraphText(
                    text: '목표 달성 예정일: ${goalDate.year}년 ${goalDate.month}월 ${goalDate.day}일',
                    // fontWeight: FontWeight.bold,
                    color: AppColors.primary),
                // Text(
                //   '목표 달성 예정일: ${goalDate.year}년 ${goalDate.month}월 ${goalDate.day}일',
                //   style: const TextStyle(fontSize: 15, color: Color(0xFF3B82F6)),
                // ),
                const SizedBox(height: 2),
                Text(
                  '목표까지 ${days}일 ${hours}시간 ${minutes}분 ${seconds}초 남았어요!',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 수정하기 = 현재 모드로 재생 + 콜백
          Center(
            child: ElevatedButton(
              onPressed: () {
                _chartKey.currentState?.replay(); // 현재 모드로 재생
                widget.onEdit?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                '수정하기',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

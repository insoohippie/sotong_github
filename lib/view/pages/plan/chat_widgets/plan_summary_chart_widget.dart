import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../component/chart/animated_budget_bar_chart.dart';
import '../../../../model/plan_info.dart';
import '../../../../model/saving_calculation_result.dart';

class PlanSummaryChartWidget extends StatefulWidget {
  final PlanInfo planInfo;
  final SavingCalculationResult? calculation;
  final VoidCallback? onEdit;
  final String userName;

  const PlanSummaryChartWidget({
    Key? key,
    required this.planInfo,
    required this.calculation,
    this.onEdit,
    required this.userName,
  }) : super(key: key);

  @override
  State<PlanSummaryChartWidget> createState() => _PlanSummaryChartWidgetState();
}

class _PlanSummaryChartWidgetState extends State<PlanSummaryChartWidget> {
  // ⬇️ 추가: 1초마다 다시 그리기 위한 타이머
  Timer? _ticker;

  double get monthlyIncome => widget.planInfo.fixedIncomeSum!;
  double get monthlyFixedCost => widget.planInfo.fixedConsumptionSum!;
  double get dailySpendingLimit => widget.planInfo.dailyConsumptionSum!;
  double get fixedRatio => (monthlyFixedCost / (monthlyIncome == 0 ? 1 : monthlyIncome)).clamp(0.0, 1.0);
  double get monthlyVariableCost => dailySpendingLimit * 30;
  double get variableRatio => (monthlyVariableCost / (monthlyIncome == 0 ? 1 : monthlyIncome)).clamp(0.0, 1.0);
  double get monthlySaving => widget.calculation?.monthlySaving ?? 0;
  double get savingRatio => widget.calculation?.savingRatio ?? 0;

  @override
  void initState() {
    super.initState();
    // ⬇️ 추가: 1초마다 setState() 호출해 남은 시간 갱신
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // build()가 다시 돌면서 now가 갱신됨
    });
  }

  @override
  void dispose() {
    // ⬇️ 추가: 타이머 정리
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userName.isNotEmpty ? widget.userName : '회원';
    final now = DateTime.now(); // 타이머로 매초 갱신됨
    final goalDate = widget.calculation?.goalDateTime ?? DateTime.now();
    final duration = goalDate.difference(now);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final dailyIncome = monthlyIncome / 30;
    final dailyFixed = monthlyFixedCost / 30;
    final dailyVariable = dailySpendingLimit;
    final dailySaving = widget.calculation?.dailyNetSaving ?? 0;
    final savingPerSecond = widget.calculation?.savingPerSecond ?? 0;
    final monthlyVariableCost = this.monthlyVariableCost;
    final monthlySaving = this.monthlySaving;

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 한눈에 보는 플랜 요약',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBudgetBarChart(
            planInfo: widget.planInfo,
            calculation: widget.calculation,
            height: 20,
            showPercentages: true,
            animationDuration: const Duration(milliseconds: 1200),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  '📅 목표 달성 예정일: ${goalDate.year}년 ${goalDate.month}월 ${goalDate.day}일',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '목표까지 ${days}일 ${hours}시간 ${minutes}분 ${seconds}초 남았어요!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: widget.onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '수정하기',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

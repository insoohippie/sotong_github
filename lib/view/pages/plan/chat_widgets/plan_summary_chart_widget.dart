import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../component/chart/animated_budget_bar_chart.dart';
import '../../../../model/plan_info.dart';
import '../../../../model/saving_calculation_result.dart';
import '../../../../view_model/services/saving_calculator.dart';



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

  double get monthlyIncome => widget.planInfo.fixedIncomeSum!;
  double get monthlyFixedCost => widget.planInfo.fixedConsumptionSum!;
  double get dailySpendingLimit => widget.planInfo.dailyConsumptionSum!;
  double get fixedRatio => (monthlyFixedCost / (monthlyIncome == 0 ? 1 : monthlyIncome)).clamp(0.0, 1.0);
  double get monthlyVariableCost => dailySpendingLimit * 30;
  double get variableRatio => (monthlyVariableCost / (monthlyIncome == 0 ? 1 : monthlyIncome)).clamp(0.0, 1.0);
  double get monthlySaving => widget.calculation?.monthlySaving ?? 0;
  double get savingRatio => widget.calculation?.savingRatio ?? 0;



  @override
  Widget build(BuildContext context) {
    final name = widget.userName.isNotEmpty ? widget.userName : '회원';
    final now = DateTime.now();
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
    // Animated stacked bar
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
          // 분리된 애니메이션 차트 위젯 사용
          AnimatedBudgetBarChart(
            planInfo: widget.planInfo,
            calculation: widget.calculation,
            height: 20,
            showPercentages: true,
            animationDuration: const Duration(milliseconds: 1200),
          ),
          const SizedBox(height: 24),
          // 요약 설명 박스
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name님의 하루 재정 플랜',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Text(
                    '$name님은 하루에 ${SavingPlanCalculator.formatAmount(dailyIncome)}원을 벌고, 고정소비로 ${SavingPlanCalculator.formatAmount(dailyFixed)}원이 지출되고, 하루소비로 ${SavingPlanCalculator.formatAmount(dailyVariable)}원을 등록하여 최종적으로 하루에 저축 가능한 금액은 ${SavingPlanCalculator.formatAmount(dailySaving)}원입니다.',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('1초당 약 ${savingPerSecond.toStringAsFixed(2)}원이 저축됩니다.',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF3B82F6))),
                const SizedBox(height: 8),
                Text('$name님은 하루에 이 소비한도 금액만 지켜주시면 목표달성일에 문제없이 도달할 수 있어요!',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF1E40AF))),
                const SizedBox(height: 18),
                Center(
                  child: ElevatedButton(
                    onPressed: widget.onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '수정하기',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
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
        ],
      ),
    );
  }
}

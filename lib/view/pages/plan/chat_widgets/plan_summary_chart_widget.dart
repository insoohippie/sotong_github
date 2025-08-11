import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../model/plan_info.dart';
import '../../../../model/saving_calculation_result.dart';
import '../../../../services/saving_calculator.dart';

class PlanSummaryChartWidget extends StatefulWidget {
  final PlanInfo planInfo;
  final SavingCalculationResult? calculation;
  final VoidCallback? onEdit;

  const PlanSummaryChartWidget({
    Key? key,
    required this.planInfo,
    required this.calculation,
    this.onEdit,
  }) : super(key: key);

  @override
  State<PlanSummaryChartWidget> createState() => _PlanSummaryChartWidgetState();
}

class _PlanSummaryChartWidgetState extends State<PlanSummaryChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fixedAnim;
  late Animation<double> _variableAnim;
  late Animation<double> _savingAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initAnims();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  void _initAnims() {
    _fixedAnim = Tween<double>(
      begin: 0,
      end: fixedRatio,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _variableAnim = Tween<double>(
      begin: 0,
      end: variableRatio,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _savingAnim = Tween<double>(
      begin: 0,
      end: savingRatio,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant PlanSummaryChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calculation != widget.calculation ||
        oldWidget.planInfo != widget.planInfo) {
      _initAnims();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get monthlyIncome => widget.planInfo.fixedIncomeSum!;

  double get monthlyFixedCost => widget.planInfo.fixedConsumptionSum!;

  double get dailySpendingLimit => widget.planInfo.dailyConsumptionSum!;

  double get fixedRatio =>
      (monthlyFixedCost / (monthlyIncome == 0 ? 1 : monthlyIncome)).clamp(
        0.0,
        1.0,
      );

  double get monthlyVariableCost => dailySpendingLimit * 30;

  double get variableRatio =>
      (monthlyVariableCost / (monthlyIncome == 0 ? 1 : monthlyIncome)).clamp(
        0.0,
        1.0,
      );

  double get monthlySaving => widget.calculation?.monthlySaving ?? 0;

  double get savingRatio => widget.calculation?.savingRatio ?? 0;

  Widget _buildBarWithPercentLabels() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final fixedWidth = totalWidth * _fixedAnim.value;
        final variableWidth = totalWidth * _variableAnim.value;
        final savingWidth = totalWidth * _savingAnim.value;
        final fixedPercent = (fixedRatio * 100).round();
        final variablePercent = (variableRatio * 100).round();
        final savingPercent = (savingRatio * 100).round();
        return Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: (_fixedAnim.value * 100).round(),
                  child: Container(
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF87171),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: (_variableAnim.value * 100).round(),
                  child: Container(height: 16, color: const Color(0xFFFB923C)),
                ),
                Expanded(
                  flex: (_savingAnim.value * 100).round(),
                  child: Container(
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // % 라벨
            if (fixedWidth > 0)
              Positioned(
                left: fixedWidth / 2 - 18,
                top: -22,
                child: fixedPercent > 0
                    ? Text(
                        '$fixedPercent%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF87171),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            if (variableWidth > 0)
              Positioned(
                left: fixedWidth + variableWidth / 2 - 18,
                top: -22,
                child: variablePercent > 0
                    ? Text(
                        '$variablePercent%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFB923C),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            if (savingWidth > 0)
              Positioned(
                left: fixedWidth + variableWidth + savingWidth / 2 - 18,
                top: -22,
                child: savingPercent > 0
                    ? Text(
                        '$savingPercent%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planName =
        (ModalRoute.of(context)?.settings.arguments
            as Map?)?['planName'] ?? // 수정 필요
        '회원';
    final name = planName is String && planName.isNotEmpty ? planName : '회원';
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
          // Animated stacked bar with overlayed amounts
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Normalize ratios so their sum is at most 1.0
              final totalRatio =
                  _fixedAnim.value + _variableAnim.value + _savingAnim.value;
              final normFixed = totalRatio > 0
                  ? _fixedAnim.value / totalRatio
                  : 0.0;
              final normVariable = totalRatio > 0
                  ? _variableAnim.value / totalRatio
                  : 0.0;
              final normSaving = totalRatio > 0
                  ? _savingAnim.value / totalRatio
                  : 0.0;
              final fixedPercent = (fixedRatio * 100).round();
              final variablePercent = (variableRatio * 100).round();
              final savingPercent = (savingRatio * 100).round();
              return SizedBox(
                height: 40,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: (normFixed * 1000).round(),
                          child: Container(
                            // 고정 소비
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF87171),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(8),
                                bottomLeft: const Radius.circular(8),
                                topRight: normVariable == 0 && normSaving == 0
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                                bottomRight:
                                    normVariable == 0 && normSaving == 0
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          // 변동 지출
                          flex: (normVariable * 1000).round(),
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFB923C),
                              borderRadius: BorderRadius.only(
                                topRight: normSaving == 0 && normVariable > 0
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                                bottomRight: normSaving == 0 && normVariable > 0
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          // 저축
                          flex: (normSaving * 1000).round(),
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.only(
                                topRight: normSaving > 0
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                                bottomRight: normSaving > 0
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Overlay: 금액+퍼센트 텍스트 (위, only)
                    Row(
                      children: [
                        Expanded(
                          flex: (normFixed * 1000).round(),
                          child: normFixed > 0.04
                              ? Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${SavingPlanCalculator.formatAmount(monthlyFixedCost)}원 ($fixedPercent%)',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFF87171),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Expanded(
                          flex: (normVariable * 1000).round(),
                          child: normVariable > 0.04
                              ? Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${SavingPlanCalculator.formatAmount(monthlyVariableCost)}원 ($variablePercent%)',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFFB923C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Expanded(
                          flex: (normSaving * 1000).round(),
                          child: normSaving > 0.04
                              ? Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${SavingPlanCalculator.formatAmount(monthlySaving)}원 ($savingPercent%)',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF3B82F6),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
                Text(
                  '$name님의 하루 재정 플랜',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$name님은 하루에 ${SavingPlanCalculator.formatAmount(dailyIncome)}원을 벌고, 고정소비로 ${SavingPlanCalculator.formatAmount(dailyFixed)}원이 지출되고, 하루소비로 ${SavingPlanCalculator.formatAmount(dailyVariable)}원을 등록하여 최종적으로 하루에 저축 가능한 금액은 ${SavingPlanCalculator.formatAmount(dailySaving)}원입니다.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '1초당 약 ${savingPerSecond.toStringAsFixed(2)}원이 저축됩니다.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$name님은 하루에 이 소비한도 금액만 지켜주시면 목표달성일에 문제없이 도달할 수 있어요!',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: ElevatedButton(
                    onPressed: widget.onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '수정하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/appbars/custom_app_bar_home.dart';
import 'package:sotong_local/component/buttons/small_rounded_button.dart';
import 'package:sotong_local/component/containers/rounded_info_container.dart';

import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/theme/app_spacing.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeTestPage extends StatefulWidget {
  const HomeTestPage({super.key});

  @override
  State<HomeTestPage> createState() => _HomeTestPageState();
}

class _HomeTestPageState extends State<HomeTestPage> {
  // Test data
  String _userName = '테스트 사용자';
  String _planName = '테스트 플랜';
  final double _savingPerSec = 50.5;
  String _fixedSpending = '7,000원';

  // Live saving amount (simulated)
  double _liveSavedAmount = 345132.0;

  // 목표 저축 금액
  final double _targetSavingAmount = 5000000.0; // 500만원

  // D-Day 텍스트 (목표일까지 남은 일수)
  String get _dDayText {
    if (_goalDate == null) {
      return '';
    }
    final now = DateTime.now();
    final remainingDays = _goalDate!.difference(now).inDays;
    return 'D-${remainingDays.abs()}';
  }

  // 플랜 날짜 데이터 (테스트용)
  final DateTime _planStartDate = DateTime.now().subtract(
    const Duration(days: 28),
  );
  final DateTime? _goalDate = DateTime.now().add(const Duration(days: 52));

  // Selected date
  DateTime _selectedDate = DateTime.now();

  // Simulated spending data (date -> amount)
  final Map<String, double> _spendingData = {
    '${DateTime.now().month}/${DateTime.now().day}':
        10000.0, // 현재 날짜: 10,000원 (한도 초과)
    '11/2': 20000.0, // 11월 2일: 20,000원 (한도 초과)
    '11/3': 5000.0, // 11월 3일: 5,000원 (한도 미만)
  };

  // 최근 7일 소비 데이터 (테스트용)
  List<Map<String, dynamic>> get _weeklySpendingData {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final key = '${date.month}/${date.day}';
      final amount = _spendingData[key] ?? 
          (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday 
              ? 12000.0 
              : 8000.0); // 주말은 조금 더 많이 소비
      return {
        'date': date,
        'amount': amount,
        'limit': _dailyLimitAmount,
      };
    });
  }

  // 이번 달 총 예산
  final double _monthlyBudget = 210000.0; // 일일 7,000원 * 30일

  // 이번 달 실제 소비 총액
  double get _monthlyActualSpending {
    final now = DateTime.now();
    return _spendingData.entries
        .where((entry) {
          final parts = entry.key.split('/');
          if (parts.length == 2) {
            final month = int.tryParse(parts[0]);
            return month == now.month;
          }
          return false;
        })
        .fold<double>(0.0, (sum, entry) => sum + entry.value);
  }

  @override
  void initState() {
    super.initState();
    // Simulate live updates every second
    _startLiveUpdates();
  }

  void _startLiveUpdates() {
    // Simulate live saving amount updates
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _liveSavedAmount += _savingPerSec;
        });
        _startLiveUpdates();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _getSpendingForDate(DateTime date) {
    final key = '${date.month}/${date.day}';
    final amount = _spendingData[key] ?? 0.0;
    return '${amount.toStringAsFixed(0)}원';
  }

  // 금액 문자열에서 숫자 추출
  double _parseAmount(String amountStr) {
    final cleaned = amountStr.replaceAll(RegExp(r'[원,\s]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // 한도 금액 숫자 추출
  double get _dailyLimitAmount {
    return _parseAmount(_fixedSpending);
  }

  // 실제 사용 금액 숫자 추출
  double _getActualSpentAmount(DateTime date) {
    final key = '${date.month}/${date.day}';
    return _spendingData[key] ?? 0.0;
  }

  void _showCountdownDialog() {
    if (_goalDate == null) return;

    Duration remaining = _goalDate!.difference(DateTime.now());
    Timer? countdown;

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            countdown ??= Timer.periodic(const Duration(seconds: 1), (_) {
              final newRemaining = _goalDate!.difference(DateTime.now());
              setState(() {
                if (newRemaining.isNegative) {
                  remaining = Duration.zero;
                  countdown?.cancel();
                } else {
                  remaining = newRemaining;
                }
              });
            });

            final days = remaining.inDays;
            final hours = remaining.inHours % 24;
            final minutes = remaining.inMinutes % 60;
            final seconds = remaining.inSeconds % 60;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      '$days일 ${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '1초씩 $_savingPerSec원이 증가해요',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => countdown?.cancel());
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  // 저축 목표 진행률 계산
  double get _savingProgressPercent {
    return (_liveSavedAmount / _targetSavingAmount * 100).clamp(0.0, 100.0);
  }

  // 기준선 금액 계산 (시간 경과에 따라 도달해야 하는 금액)
  double get _targetLineAmount {
    if (_goalDate == null) return 0.0;
    final now = DateTime.now();
    final totalDays = _goalDate!.difference(_planStartDate).inDays;
    final elapsedDays = now.difference(_planStartDate).inDays;
    
    if (totalDays <= 0) return 0.0;
    final progressRatio = (elapsedDays / totalDays).clamp(0.0, 1.0);
    return _targetSavingAmount * progressRatio;
  }

  // 기준선 위치 (0.0 ~ 1.0)
  double get _targetLinePosition {
    if (_targetSavingAmount <= 0) return 0.0;
    return (_targetLineAmount / _targetSavingAmount).clamp(0.0, 1.0);
  }

  // 실제 진행률이 기준선보다 높은지 확인
  bool get _isAboveTarget {
    return _liveSavedAmount >= _targetLineAmount;
  }

  // 재정 상태 그래프 위젯
  Widget _buildFinancialStatusCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        const Text(
          '재정 현황',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: AppSpacing.fieldSpacing),
        
        // 1. 저축 목표 진행률 프로그레스 바
        _buildSavingProgressCard(),
        SizedBox(height: AppSpacing.fieldSpacing),
        
        // 2. 최근 7일 소비 추이
        _buildWeeklySpendingChart(),
        SizedBox(height: AppSpacing.fieldSpacing),
        
        // 3. 이번 달 예산 대비 소비
        _buildMonthlyBudgetChart(),
      ],
    );
  }

  // 저축 목표 진행률 카드
  Widget _buildSavingProgressCard() {
    final progress = _savingProgressPercent / 100;
    final targetLinePos = _targetLinePosition;
    final progressColor = _isAboveTarget 
        ? AppColors.primary // 파랑 (기준선 이상)
        : const Color(0xFFFF5F5F); // 빨강 (기준선 미만)
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '저축 목표 진행률',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
        Text(
                '${_savingProgressPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 프로그레스 바 (기준선 포함)
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final targetLineX = barWidth * targetLinePos;
              
              return SizedBox(
                height: 16,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 배경 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.grey[200],
                      ),
                    ),
                    // 실제 진행 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        heightFactor: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // 기준선 (노란색 세로선)
                    if (targetLinePos > 0 && targetLinePos < 1.0)
                      Positioned(
                        left: targetLineX - 1, // 선의 중심이 기준선 위치
                        child: Container(
                          width: 2,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107), // 노란색
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFC107).withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // 기준선 및 상태 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 기준선 정보
              if (_targetLineAmount > 0)
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.3),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '현재 시점 기준',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _targetLineAmount.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      ) + '원',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              
              // 상태 표시 (기준 대비)
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: progressColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isAboveTarget ? '기준 달성' : '기준 미달',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (!_isAboveTarget)
                    Text(
                      '${(_targetLineAmount - _liveSavedAmount).toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )}원 부족',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Text(
                      '+${(_liveSavedAmount - _targetLineAmount).toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )}원',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 최근 7일 소비 추이 라인 차트
  Widget _buildWeeklySpendingChart() {
    final maxAmount = _weeklySpendingData
        .map((e) => math.max(e['amount'] as double, e['limit'] as double))
        .reduce(math.max) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 7일 소비 추이',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxAmount / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _weeklySpendingData.length) {
                          final date = _weeklySpendingData[index]['date'] as DateTime;
                          final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${dayNames[date.weekday % 7]}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxAmount / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // 한도 라인
                  LineChartBarData(
                    spots: _weeklySpendingData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['limit'] as double);
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange[300],
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // 실제 소비 라인
                  LineChartBarData(
                    spots: _weeklySpendingData.asMap().entries.map((e) {
                      final amount = e.value['amount'] as double;
                      return FlSpot(e.key.toDouble(), amount);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final amount = _weeklySpendingData[index]['amount'] as double;
                        final limit = _weeklySpendingData[index]['limit'] as double;
                        return FlDotCirclePainter(
                          radius: 4,
                          color: amount > limit
                              ? const Color(0xFFFF5F5F)
                              : AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxAmount,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.orange[300]!, '일일 한도'),
              const SizedBox(width: 16),
              _buildLegendItem(AppColors.primary, '실제 소비'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // 이번 달 예산 대비 소비 도넛 차트
  Widget _buildMonthlyBudgetChart() {
    final actualSpending = _monthlyActualSpending;
    final remaining = (_monthlyBudget - actualSpending).clamp(0.0, double.infinity);
    final overSpent = (actualSpending - _monthlyBudget).clamp(0.0, double.infinity);
    
    final spendingPercent = (_monthlyBudget > 0 
        ? (actualSpending / _monthlyBudget * 100).clamp(0.0, 100.0)
        : 0.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 예산 현황',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 도넛 차트
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: spendingPercent > 100 
                            ? 100 
                            : spendingPercent,
                        color: spendingPercent > 100
                            ? const Color(0xFFFF5F5F)
                            : AppColors.primary,
                        radius: 35,
                        title: spendingPercent > 100 
                            ? '${spendingPercent.toStringAsFixed(0)}%'
                            : '${spendingPercent.toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (spendingPercent < 100)
                        PieChartSectionData(
                          value: 100 - spendingPercent,
                          color: Colors.grey[300],
                          radius: 35,
                          title: '',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 상세 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBudgetInfoItem(
                      '예산',
                      _monthlyBudget,
                      Colors.grey[600]!,
                    ),
                    const SizedBox(height: 8),
                    _buildBudgetInfoItem(
                      '실제 소비',
                      actualSpending,
                      spendingPercent > 100
                          ? const Color(0xFFFF5F5F)
                          : AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    if (spendingPercent < 100)
                      _buildBudgetInfoItem(
                        '남은 예산',
                        remaining,
                        const Color(0xFF4CAF50),
                      )
                    else
                      _buildBudgetInfoItem(
                        '초과 소비',
                        overSpent,
                        const Color(0xFFFF5F5F),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInfoItem(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          ) + '원',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = _formatDate(_selectedDate);
    final todaySpending = _getSpendingForDate(_selectedDate);
    final bool hasSpendingRecord = todaySpending != '0원';

    // 금액 비교
    final actualSpent = _getActualSpentAmount(_selectedDate);
    final dailyLimit = _dailyLimitAmount;
    final isOverLimit = actualSpent > dailyLimit;

    // 배경색과 실제 사용 금액 텍스트 색상 결정
    final containerBackgroundColor = !hasSpendingRecord
        ? Colors.grey[200]! // 라이트그레이 (기록 없음)
        : isOverLimit
        ? const Color(0xFFFFEFEF) // 분홍색 (한도 초과)
        : const Color(0xFFEFF5FF); // 연한 파란색 (한도 미만/동일)

    final actualSpentTextColor = isOverLimit
        ? const Color(0xFFFF5F5F) // 빨간색 (한도 초과)
        : const Color(0xFF0062FF); // 파란색 (한도 미만/동일)

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
            CustomAppBarHome(
              text: '$_userName 님',
              unreadCount: 3,
              onNotifications: () =>
                  Navigator.pushNamed(context, '/notification'),
              onSettings: () => Navigator.pushNamed(context, '/setting'),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RoundedInfoContainer(
                        backgroundColor: const Color(0xFFF5F5F5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 플랜 이름과 D-Day를 나란히 배치
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.planTagBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ParagraphText(
                                        text: _planName,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () async {
                                          // Test: Show a simple dialog instead of the actual modal
                                      final controller = TextEditingController(
                                                text: _planName,
                                              );
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('플랜 이름 수정'),
                                              content: TextField(
                                                controller: controller,
                                            decoration: const InputDecoration(
                                                      hintText: '플랜 이름을 입력하세요',
                                                    ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('취소'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                if (controller.text
                                                        .isNotEmpty) {
                                                      setState(() {
                                                        _planName =
                                                            controller.text;
                                                      });
                                                    }
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('저장'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // D-Day 표시
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _showCountdownDialog,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: ParagraphText(
                                  text: _dDayText,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.fieldSpacing),
                            // 모인 금액 컨테이너
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 모인 금액 텍스트 (왼쪽 정렬)
                                ParagraphText(text: '모인 금액', fontWeight: FontWeight.bold),
                                SizedBox(height: AppSpacing.fieldSpacing),
                                // 금액 표시 (큰 크기, 파란색)
                                Text(
                                  _liveSavedAmount
                                          .toStringAsFixed(0)
                                          .replaceAllMapped(
                                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                            (Match m) => '${m[1]},',
                                          ) +
                                      '원',
                                  style: TextStyle(
                                    fontSize: 32,
                              fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.sectionSpacing2),
                                
                                // 재정 상태 그래프 섹션
                                if (_goalDate != null) ...[
                                  _buildFinancialStatusCharts(),
                                  SizedBox(height: AppSpacing.fieldSpacing),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.fieldSpacing),
                      RoundedInfoContainer(
                        backgroundColor: containerBackgroundColor,
                        padding: 20,
                        child: Column(
                          crossAxisAlignment: hasSpendingRecord
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ParagraphText(
                                      text: displayDate,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const SizedBox(width: 8),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/add_income_edit',
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        onTap: () => _changeDate(-1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.chevron_left,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        onTap: () => _changeDate(1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.chevron_right,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.fieldSpacing),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!hasSpendingRecord) ...[
                                  SmallRoundedButton(
                                    text: "소비 기록하러 가기",
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/record_spending',
                                      );
                                    },
                                  ),
                                ] else ...[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/today_spending',
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            // 실제 사용 금액 (조건부 색상)
                                            Text(
                                              todaySpending,
                                              style: TextStyle(
                                                color: actualSpentTextColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              ' / ',
                                              style: TextStyle(
                                                color: AppColors.text,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            // 한도 금액 (검은색)
                                            Text(
                                              _fixedSpending,
                                              style: TextStyle(
                                                color: AppColors.text,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 롤링 숫자 애니메이션 위젯 (자릿수별로 롤링 효과)
class _RollingNumberWidget extends StatefulWidget {
  final double value;
  const _RollingNumberWidget({required this.value});

  @override
  State<_RollingNumberWidget> createState() => _RollingNumberWidgetState();
}

class _RollingNumberWidgetState extends State<_RollingNumberWidget>
    with TickerProviderStateMixin {
  List<AnimationController> _controllers = [];
  List<Animation<double>> _animations = [];
  List<int> _previousDigits = [];
  List<int> _currentDigits = [];

  @override
  void initState() {
    super.initState();
    _initializeDigits(widget.value.toInt());
  }

  void _initializeDigits(int value) {
    // 숫자를 문자열로 변환하고 각 자릿수 추출
    final valueStr = value.toString();
    _currentDigits = valueStr.split('').map((e) => int.parse(e)).toList();
    _previousDigits = List.from(_currentDigits);

    // 각 자릿수마다 애니메이션 컨트롤러 생성
    _controllers = List.generate(
      _currentDigits.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(_RollingNumberWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newValue = widget.value.toInt();
      final newValueStr = newValue.toString();
      final newDigits = newValueStr.split('').map((e) => int.parse(e)).toList();

      // 자릿수가 변경되면 재초기화
      if (newDigits.length != _currentDigits.length) {
        for (var controller in _controllers) {
          controller.dispose();
        }
        _initializeDigits(newValue);
      } else {
        _previousDigits = List.from(_currentDigits);
        _currentDigits = newDigits;

        // 각 자릿수별로 애니메이션 실행
        for (int i = 0; i < _currentDigits.length; i++) {
          if (_previousDigits[i] != _currentDigits[i]) {
            final diff = _currentDigits[i] - _previousDigits[i];
            // 자릿수 롤오버 고려 (예: 9 -> 0은 -9가 아니라 +1로 처리)
            final normalizedDiff = diff < 0 ? diff + 10 : diff;

            _animations[i] =
                Tween<double>(
                  begin: _previousDigits[i].toDouble(),
                  end:
                      _currentDigits[i].toDouble() +
                      (normalizedDiff > 5 ? -10 : 0).toDouble(),
                ).animate(
                  CurvedAnimation(
                    parent: _controllers[i],
                    curve: Curves.easeOutCubic,
                  ),
                );

            _controllers[i].reset();
            _controllers[i].forward();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _formatAmount(widget.value.toInt());

    // 각 자릿수를 개별적으로 애니메이션 처리하여 표시
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      textBaseline: TextBaseline.alphabetic,
      children: formattedAmount.split('').asMap().entries.map((entry) {
        final index = entry.key;
        final char = entry.value;

        // 숫자인 경우에만 애니메이션 적용
        if (RegExp(r'[0-9]').hasMatch(char)) {
          // 현재 위치까지의 숫자 개수를 세어 인덱스 계산
          final digitIndex = formattedAmount
              .substring(0, index)
              .replaceAll(RegExp(r'[^0-9]'), '')
              .length;

          if (digitIndex < _animations.length &&
              digitIndex < _currentDigits.length) {
            return AnimatedBuilder(
              animation: _animations[digitIndex],
              builder: (context, child) {
                final animatedValue = _animations[digitIndex].value;
                final displayDigit = (animatedValue.round() % 10).abs();
                return Text(
                  displayDigit.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                );
              },
            );
          }
        }

        // 숫자가 아닌 문자 (콤마, 원 등)는 그대로 표시
        return Text(
          char,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        );
      }).toList(),
    );
  }
}

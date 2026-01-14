import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

import 'package:sotong_local/component/theme/app_colors.dart';

class ReportTestPage extends StatefulWidget {
  const ReportTestPage({super.key});

  @override
  State<ReportTestPage> createState() => _ReportTestPageState();
}

class _ReportTestPageState extends State<ReportTestPage>
    with SingleTickerProviderStateMixin {
  String budgetPeriod = '주간'; // 일간/주간/월간 토글 (남은 예산용)
  int currentInsightIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  // 소비 인사이트 데이터 (무한 스크롤을 위해 반복)
  late List<Map<String, dynamic>> insights;

  // 선택된 월
  int selectedMonth = 10; // 기본값: 10월

  // 선택된 카테고리
  String selectedCategory = '저축'; // 기본값: 저축

  // 재정 요약 데이터 (하드코딩)
  final int incomeTotal = 2800000;
  final int fixedExpenseTotal = 1200000;
  final int variableExpenseTotal = 900000;
  final int savingTotal = 700000;
  final double goalProgressPercent = 0.6;
  final int goalProgressAmount = 600000;
  final int goalTotalAmount = 1000000;

  // 숫자 애니메이션 관련
  late AnimationController _amountAnimationController;
  late Animation<double> _amountAnimation;
  int _previousAmount = 700000;
  int _currentAmount = 700000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 숫자 애니메이션 컨트롤러 초기화
    _amountAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _amountAnimation =
        Tween<double>(
          begin: _previousAmount.toDouble(),
          end: _currentAmount.toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _amountAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // 원본 데이터
    final originalInsights = [
      {
        'title': '이번 주 가장 많이 쓴 곳은 \'식비\'예요',
        'icon': Icons.trending_up,
        'color': const Color(0xFFE53935), // 빨간색 (부정적)
      },
      {
        'title': '이번 주 가장 적게 쓴 곳은 \'교통비\'예요',
        'icon': Icons.trending_down,
        'color': const Color(0xFF43A047), // 초록색 (긍정적)
      },
      {
        'title': '\'취미·여가\' 지출이 예산을 초과했어요',
        'icon': Icons.warning,
        'color': const Color(0xFFFF8F00), // 오렌지색 (경고)
      },
      {
        'title': '목표금액의 60%를 달성했어요',
        'icon': Icons.flag_circle,
        'color': const Color(0xFF1E88E5), // 파란색 (중립/긍정)
      },
      {
        'title': '하루 평균 ₩15,800을 사용했어요',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF43A047), // 초록색 (긍정적)
      },
      {
        'title': '일주일 평균 ₩110,000을 사용했어요',
        'icon': Icons.bar_chart,
        'color': const Color(0xFF1E88E5), // 파란색 (중립/긍정)
      },
      {
        'title': '현재 속도로 가면 5일 뒤 예산을 모두 소진해요',
        'icon': Icons.access_time,
        'color': const Color(0xFFD32F2F), // 진한 빨간색 (경고)
      },
    ];

    // 무한 스크롤을 위해 데이터를 여러 번 반복
    insights = [];
    for (int i = 0; i < 10; i++) {
      insights.addAll(originalInsights);
    }

    _startAutoSlide();
  }

  // 카테고리별 남은 예산 데이터
  Map<String, List<Map<String, dynamic>>> get categoryBudgetData => {
    '일간': [
      {'category': '식비', 'budget': 15000, 'spent': 12000},
      {'category': '교통비', 'budget': 8000, 'spent': 9500},
      {'category': '고정비', 'budget': 10000, 'spent': 8000},
      {'category': '기타', 'budget': 7000, 'spent': 5000},
    ],
    '주간': [
      {'category': '식비', 'budget': 50000, 'spent': 42000},
      {'category': '교통비', 'budget': 25000, 'spent': 28000},
      {'category': '고정비', 'budget': 35000, 'spent': 30000},
      {'category': '기타', 'budget': 20000, 'spent': 15000},
    ],
    '월간': [
      {'category': '식비', 'budget': 200000, 'spent': 180000},
      {'category': '교통비', 'budget': 100000, 'spent': 95000},
      {'category': '고정비', 'budget': 150000, 'spent': 140000},
      {'category': '기타', 'budget': 80000, 'spent': 65000},
    ],
  };

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _amountAnimationController.dispose();
    super.dispose();
  }

  // 금액 애니메이션 실행
  void _animateAmount(int newAmount) {
    setState(() {
      _previousAmount = _currentAmount;
      _currentAmount = newAmount;

      _amountAnimation =
          Tween<double>(
            begin: _previousAmount.toDouble(),
            end: _currentAmount.toDouble(),
          ).animate(
            CurvedAnimation(
              parent: _amountAnimationController,
              curve: Curves.easeOutCubic,
            ),
          );

      _amountAnimationController.reset();
      _amountAnimationController.forward();
    });
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (currentInsightIndex + 1) % insights.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 앱바 with 소비 인사이트
            _buildAppBarWithInsights(),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 월/카테고리 선택 및 금액 표시
                    _buildMonthCategorySelector(),
                    const SizedBox(height: 24),

                    // 카테고리별 남은 예산 (새로 추가)
                    _buildCategoryBudgetChartContainer(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarWithInsights() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white),
      child: SizedBox(
        height: 44,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: (index) {
            setState(() {
              currentInsightIndex = index;
            });
          },
          itemCount: insights.length,
          itemBuilder: (context, index) {
            final insight = insights[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: insight['color'].withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: insight['color'].withOpacity(0.25),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(insight['icon'], color: insight['color'], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight['title'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetChartContainer() {
    final currentData = categoryBudgetData[budgetPeriod] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '카테고리별 남은 예산',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // 토글 버튼 [일간 | 주간 | 월간]
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['일간', '주간', '월간'].map((period) {
                    final isSelected = budgetPeriod == period;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          budgetPeriod = period;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 세로 막대 차트 with 라벨
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                // 막대 차트
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(currentData),
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) =>
                              Colors.black.withOpacity(0.8),
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          tooltipMargin: 8,
                          tooltipRoundedRadius: 6,
                          direction: TooltipDirection.bottom,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex >= currentData.length) return null;

                            final item = currentData[groupIndex];
                            final budget = item['budget'] as int;
                            final spent = item['spent'] as int;
                            final remaining = budget - spent;

                            // 간단한 메시지
                            final message = remaining >= 0
                                ? '${_formatAmount(remaining)}원 미달!'
                                : '${_formatAmount(remaining.abs())}원 초과!';

                            return BarTooltipItem(
                              message,
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < currentData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    currentData[value.toInt()]['category'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: _buildBarGroups(currentData),
                    ),
                  ),
                ),

                // 막대 위에 텍스트 라벨
                _buildBarLabels(currentData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100000;
    double max = 0;
    for (var item in data) {
      final budget = (item['budget'] as num).toDouble();
      final spent = (item['spent'] as num).toDouble();
      final highest = spent > budget ? spent : budget;
      if (highest > max) max = highest;
    }
    return (max * 1.2).ceilToDouble();
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> data) {
    return List.generate(data.length, (index) {
      final item = data[index];
      final budget = (item['budget'] as num).toDouble();
      final spent = (item['spent'] as num).toDouble();
      final isOverBudget = spent > budget;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: spent,
            color: isOverBudget ? Colors.red : AppColors.primary,
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            rodStackItems: isOverBudget
                ? [
                    BarChartRodStackItem(0, budget, Colors.grey[300]!),
                    BarChartRodStackItem(budget, spent, Colors.red),
                  ]
                : [BarChartRodStackItem(0, spent, AppColors.primary)],
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: budget,
              color: Colors.grey[300],
            ),
          ),
        ],
      );
    });
  }

  // 막대 위에 텍스트 표시를 위한 위젯 오버레이
  Widget _buildBarLabels(List<Map<String, dynamic>> data) {
    final maxY = _getMaxY(data);

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(data.length, (index) {
            final item = data[index];
            final budget = item['budget'] as int;
            final spent = item['spent'] as int;

            // 막대의 실제 높이 (budget과 spent 중 더 큰 값)
            final barHeight = spent > budget ? spent : budget;

            // 전체 차트 높이 대비 막대 높이의 비율
            final heightRatio = barHeight / maxY;

            return Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 1.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 막대 위에 예산 금액 표시
                      SizedBox(
                        height: (1.0 - heightRatio) * (320 - 60),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '₩${_formatAmount(budget)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 막대가 차지하는 공간 (실제 막대는 BarChart에서 그림)
                      SizedBox(height: heightRatio * (320 - 60)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // 카테고리에 따른 금액 가져오기
  int _getAmountForCategory(String category) {
    switch (category) {
      case '저축':
        return savingTotal;
      case '수입':
        return incomeTotal;
      case '고정소비':
        return fixedExpenseTotal;
      case '변동소비':
        return variableExpenseTotal;
      default:
        return 0;
    }
  }

  // 월/카테고리 선택 및 금액 표시
  Widget _buildMonthCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // 월 선택 다이얼
          _buildMonthSelector(),
          const SizedBox(height: 16),

          // 카테고리 선택 버튼과 드롭다운
          _buildCategorySelectorWithDropdown(),

          // 드롭다운 카테고리 리스트
          if (isCategoryDropdownOpen)
            Container(
              width: 120,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildNewDropdownOption('저축'),
                  _buildNewDropdownOption('수입'),
                  _buildNewDropdownOption('고정소비'),
                  _buildNewDropdownOption('변동소비'),
                ],
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 월 선택 다이얼
  Widget _buildMonthSelector() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 왼쪽 화살표 (이전 달)
          GestureDetector(
            onTap: () {
              selectedMonth--;
              if (selectedMonth < 1) {
                selectedMonth = 12; // 12월로 순환
              }

              // 선택된 카테고리의 새 금액으로 애니메이션
              int newAmount = _getAmountForCategory(selectedCategory);
              _animateAmount(newAmount);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left,
                color: Colors.grey[700],
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 중앙 월 표시
          Text(
            '$selectedMonth월',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 8),

          // 오른쪽 화살표 (다음 달)
          GestureDetector(
            onTap: () {
              selectedMonth++;
              if (selectedMonth > 12) {
                selectedMonth = 1; // 1월로 순환
              }

              // 선택된 카테고리의 새 금액으로 애니메이션
              int newAmount = _getAmountForCategory(selectedCategory);
              _animateAmount(newAmount);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[700],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 드롭다운 상태 관리
  bool isCategoryDropdownOpen = false;

  // 카테고리 선택 버튼과 드롭다운을 하나로 묶은 위젯
  Widget _buildCategorySelectorWithDropdown() {
    return Row(
      children: [
        // 카테고리 선택 버튼 (드롭다운)
        SizedBox(
          width: 120,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isCategoryDropdownOpen = !isCategoryDropdownOpen;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                children: [
                  Text(
                    selectedCategory,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isCategoryDropdownOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // 금액 표시 - 중앙 정렬, 천 단위 구분자, 애니메이션
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _amountAnimation,
              builder: (context, child) {
                return Text(
                  '${_formatAmount(_amountAnimation.value.toInt())}원',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // 새로운 드롭다운 옵션 위젯
  Widget _buildNewDropdownOption(String category) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          isCategoryDropdownOpen = false;
        });
        // 새 카테고리의 금액으로 애니메이션 실행
        int newAmount = _getAmountForCategory(category);
        _animateAmount(newAmount);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue[700] : Colors.black87,
          ),
        ),
      ),
    );
  }
}

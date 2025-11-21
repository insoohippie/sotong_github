import 'dart:math' as math;

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
  int selectedMonth = 10; // 10월부터 시작
  int selectedYear = DateTime.now().year;
  String? _selectedChartCategory;
  bool _isCollapsing = false;
  bool _showSelectionLayout = false;
  bool _showPopup = false;
  Timer? _selectionTimer;
  Timer? _popupTimer;

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
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
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
    final chartData = [...currentData];
    if (currentData.isNotEmpty) {
      final totalBudget = currentData
          .map((item) => item['budget'] as int)
          .fold<int>(0, (sum, value) => sum + value);
      final totalSpent = currentData
          .map((item) => item['spent'] as int)
          .fold<int>(0, (sum, value) => sum + value);
      chartData.add({
        'category': '총예산',
        'budget': totalBudget,
        'spent': totalSpent,
        'isTotal': true,
      });
    }

    final displayData = _reorderChartData(chartData);

    final maxY = _getMaxY(displayData);

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
          Align(
            alignment: Alignment.centerRight,
            child: _buildPeriodToggle(),
          ),
          const SizedBox(height: 12),

          // 세로 막대 차트 with 라벨
          SizedBox(
            height: 320,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  Map<String, dynamic>? popupData;
                  if (_showPopup && _selectedChartCategory != null) {
                    final match = displayData.firstWhere(
                      (item) => item['category'] == _selectedChartCategory,
                      orElse: () => <String, dynamic>{},
                    );
                    if (match.isNotEmpty) {
                      popupData = match;
                    }
                  }

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceBetween,
                            maxY: maxY,
                            minY: 0,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipPadding: EdgeInsets.zero,
                                tooltipMargin: 0,
                                tooltipBorder: BorderSide.none,
                                getTooltipColor: (_) => Colors.transparent,
                                getTooltipItem: (a, b, c, d) => null,
                              ),
                              touchCallback: (event, response) {
                                if (event is! FlTapUpEvent) return;
                                if (response == null ||
                                    response.spot == null) {
                                  _resetSelectionState();
                                  return;
                                }
                                final index = response.spot!.touchedBarGroupIndex;
                                if (index < 0 || index >= displayData.length) {
                                  _resetSelectionState();
                                  return;
                                }
                                final category =
                                    displayData[index]['category'] as String?;
                                if (category == null) {
                                  _resetSelectionState();
                                  return;
                                }
                                _startSelectionTransition(category);
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < displayData.length) {
                                      final category = displayData[idx]
                                          ['category'] as String?;
                                      final bool isSelected = _showSelectionLayout &&
                                          category != null &&
                                          category == _selectedChartCategory;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          category ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.black87,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
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
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval:
                                  maxY == 0 ? 1 : maxY / 4,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey[200],
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: _buildBarGroups(displayData, maxY),
                            extraLinesData:
                                const ExtraLinesData(horizontalLines: []),
                          ),
                          swapAnimationDuration:
                              const Duration(milliseconds: 260),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),
                      ),
                      if (popupData != null)
                      Positioned(
                          top: 16,
                          left: 100,
                          child: AnimatedOpacity(
                            opacity: _showPopup ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: _SelectedChartPopup(
                              category: popupData['category'] as String? ?? '',
                            budget: (popupData['budget'] as num?)?.toInt() ?? 0,
                            spent: (popupData['spent'] as num?)?.toInt() ?? 0,
                            isOverBudget: (popupData['spent'] as num?) != null &&
                                (popupData['budget'] as num?) != null &&
                                (popupData['spent'] as num?)! >
                                    (popupData['budget'] as num?)!,
                              formatter: _formatAmount,
                              periodLabel: budgetPeriod,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
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

  void _resetSelectionState() {
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    setState(() {
      _selectedChartCategory = null;
      _isCollapsing = false;
      _showSelectionLayout = false;
      _showPopup = false;
    });
  }

  void _changePeriod(String period) {
    if (budgetPeriod == period) return;
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    setState(() {
      budgetPeriod = period;
      _selectedChartCategory = null;
      _isCollapsing = false;
      _showSelectionLayout = false;
      _showPopup = false;
    });
  }

  void _changeMonth(int direction) {
    if (direction == 0) return;
    setState(() {
      selectedMonth += direction;
      if (selectedMonth < 1) {
        selectedMonth = 12;
        selectedYear--;
      } else if (selectedMonth > 12) {
        selectedMonth = 1;
        selectedYear++;
      }
      _resetSelectionState();
    });
    int newAmount = _getAmountForCategory(selectedCategory);
    _animateAmount(newAmount);
  }

  void _startSelectionTransition(String category) {
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    setState(() {
      _selectedChartCategory = category;
      _isCollapsing = true;
      _showSelectionLayout = false;
      _showPopup = false;
    });
    _selectionTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _isCollapsing = false;
        _showSelectionLayout = true;
      });
      _popupTimer = Timer(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        setState(() {
          _showPopup = true;
        });
      });
    });
  }

  List<Map<String, dynamic>> _reorderChartData(
    List<Map<String, dynamic>> data,
  ) {
    if (_selectedChartCategory == null || !_showSelectionLayout) {
      return List<Map<String, dynamic>>.from(data);
    }
    final index = data.indexWhere(
      (item) => item['category'] == _selectedChartCategory,
    );
    if (index <= 0) {
      return List<Map<String, dynamic>>.from(data);
    }
    final reordered = List<Map<String, dynamic>>.from(data);
    final selected = reordered.removeAt(index);
    reordered.insert(0, selected);
    return reordered;
  }

  List<BarChartGroupData> _buildBarGroups(
    List<Map<String, dynamic>> data,
    double maxY,
  ) {
    return List.generate(data.length, (index) {
      final item = data[index];
      final budget = (item['budget'] as num).toDouble();
      final spent = (item['spent'] as num).toDouble();
      final isOverBudget = spent > budget;
      final isTotal = item['isTotal'] == true;
      final String? category = item['category'] as String?;

      final bool hasSelection = _selectedChartCategory != null;
      final bool collapsePhase =
          hasSelection && (_isCollapsing || !_showSelectionLayout);
      final bool layoutActive =
          hasSelection && _showSelectionLayout && !_isCollapsing;
      final bool isSelected =
          layoutActive && category == _selectedChartCategory;

      final double baseWidth = isTotal ? 48.0 : 36.0;
      final double rodWidth = layoutActive
          ? (isSelected ? baseWidth + 12 : baseWidth - 8)
          : baseWidth;

      double scaledBudget;
      double scaledSpent;

      if (!hasSelection) {
        scaledBudget = budget;
        scaledSpent = spent;
      } else if (collapsePhase) {
        scaledBudget = 0;
        scaledSpent = 0;
      } else if (layoutActive) {
        if (isSelected) {
          final double baseMax = math.max(budget, spent);
          final double factor = baseMax > 0 ? maxY / baseMax : 0;
          scaledBudget = budget * factor;
          scaledSpent = spent * factor;
        } else {
          scaledBudget = budget * 0.4;
          scaledSpent = spent * 0.4;
        }
      } else {
        scaledBudget = budget;
        scaledSpent = spent;
      }

      final double effectiveSpent = scaledSpent.clamp(0.0, maxY);
      final double effectiveBudget = scaledBudget.clamp(0.0, maxY);

      final double lowerHeight = math.min(effectiveSpent, effectiveBudget);
      final double upperHeight = math.max(effectiveSpent, effectiveBudget);

      const Color hoverRed = Color(0xFFFF5F5F);

      final double radiusValue = isSelected ? 16 : 8;
      final Radius topRadius = Radius.circular(radiusValue);
      const double epsilon = 0.0001;

      final List<BarChartRodStackItem> stackItems = [];

      if (lowerHeight > epsilon) {
        final Color lowerColor = isOverBudget
            ? Colors.grey[300]!
            : (isSelected
                ? AppColors.primary.withOpacity(0.92)
                : AppColors.primary);
        stackItems.add(
          BarChartRodStackItem(0, lowerHeight, lowerColor),
        );
      }

      final double upperSegmentHeight = (upperHeight - lowerHeight).clamp(0.0, maxY);
      if (upperSegmentHeight > epsilon) {
        final Color upperColor = isOverBudget
            ? hoverRed
            : Colors.grey[300]!;
        stackItems.add(
          BarChartRodStackItem(lowerHeight, upperHeight, upperColor),
        );
      }

      if (stackItems.isEmpty) {
        stackItems.add(BarChartRodStackItem(0, 0, Colors.transparent));
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: upperHeight,
            width: rodWidth,
            color: stackItems.last.color,
            rodStackItems: stackItems,
            borderRadius: BorderRadius.vertical(
              top: topRadius,
              bottom: Radius.zero,
            ),
          ),
        ],
      );
    });
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
            onTap: () => _changeMonth(-1),
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
            onTap: () => _changeMonth(1),
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

  Widget _buildPeriodToggle() {
    const periods = ['주간', '월간'];
    final selectedIndex = periods.indexOf(budgetPeriod);

    Alignment _alignmentForIndex(int index) {
      switch (index) {
        case 0:
          return Alignment.centerLeft;
        case 1:
          return Alignment.centerRight;
        default:
          return Alignment.centerLeft;
      }
    }

    return Container(
      width: 120,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: _alignmentForIndex(selectedIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Container(
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(periods.length, (index) {
              final period = periods[index];
              final isSelected = budgetPeriod == period;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _changePeriod(period),
                  child: Center(
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SelectedChartPopup extends StatelessWidget {
  const _SelectedChartPopup({
    required this.category,
    required this.budget,
    required this.spent,
    required this.isOverBudget,
    required this.formatter,
    required this.periodLabel,
  });

  final String category;
  final int budget;
  final int spent;
  final bool isOverBudget;
  final String Function(int) formatter;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$periodLabel 총 예산: ₩${formatter(budget)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          _buildUsageText(),
        ],
      ),
    );
  }

  Widget _buildUsageText() {
    final int diff = spent - budget;
    if (isOverBudget) {
      return Text(
        '초과 사용액: ₩${formatter(diff.abs())}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFF5F5F),
        ),
      );
    } else {
      final int remaining = budget - spent;
      return Text(
        '미달 사용액: ₩${formatter(remaining)}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0062FF),
        ),
      );
    }
  }
}


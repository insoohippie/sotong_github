// (카테고리별 남은 예산 차트 + 기간 토글 + 팝업)

import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/theme/app_colors.dart';
import '../../../../component/buttons/period_toggle.dart';

import '../../../../view_model/report/report_view_model.dart';

class ReportCategoryBudgetChartSection extends StatefulWidget {
  const ReportCategoryBudgetChartSection({super.key});

  @override
  State<ReportCategoryBudgetChartSection> createState() =>
      _ReportCategoryBudgetChartSectionState();
}

class _ReportCategoryBudgetChartSectionState
    extends State<ReportCategoryBudgetChartSection> {
  String? _selectedChartCategory;
  bool _isCollapsing = false;
  bool _showSelectionLayout = false;
  bool _showPopup = false;
  Timer? _selectionTimer;
  Timer? _popupTimer;

  // ✅ popup width 측정용
  final GlobalKey _popupKey = GlobalKey();
  double _popupWidth = 220; // 초기값(대충), 실제 측정 후 갱신

  @override
  void dispose() {
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    super.dispose();
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  /// ✅ 선택된 막대 중심 기준으로 팝업 left 계산 (spaceBetween 근사)
  double _calcPopupLeft({
    required double chartWidth,
    required int index,
    required int count,
    required double popupWidth,
  }) {
    // spaceBetween 근사: 첫 막대는 0, 마지막 막대는 chartWidth에 위치
    final double centerX =
    (count <= 1) ? chartWidth / 2 : (chartWidth * index / (count - 1));

    final double rawLeft = centerX - (popupWidth / 2);
    final double maxLeft = math.max(0.0, chartWidth - popupWidth);

    return rawLeft.clamp(0.0, maxLeft);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    final currentData = vm.currentBudgetData;
    final chartData = [...currentData];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryEditButton(context),
              const SizedBox(width: 10),
              _buildPeriodToggle(vm),
            ],
          ),
          const SizedBox(height: 12),
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
                    if (match.isNotEmpty) popupData = match;
                  }

                  // ✅ 선택된 항목 인덱스
                  final selectedIndex = (_selectedChartCategory == null)
                      ? -1
                      : displayData.indexWhere(
                        (e) => e['category'] == _selectedChartCategory,
                  );

                  // popup left 계산 (팝업 width 반영 + clamp)
                  final popupLeft = (popupData != null && selectedIndex >= 0)
                      ? (() {
                    final baseLeft = _calcPopupLeft(
                      chartWidth: constraints.maxWidth,
                      index: selectedIndex,
                      count: displayData.length,
                      popupWidth: _popupWidth,
                    );

                    final shifted = baseLeft + 20;

                    final maxLeft = math.max(
                      0.0,
                      constraints.maxWidth - _popupWidth,
                    );
                    return shifted.clamp(0.0, maxLeft);
                  })()
                      : 0.0;

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
                                if (response == null || response.spot == null) {
                                  _resetSelectionState();
                                  return;
                                }
                                final index =
                                    response.spot!.touchedBarGroupIndex;
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
                                      final category =
                                      displayData[idx]['category']
                                      as String?;
                                      final isSelected =
                                          _showSelectionLayout &&
                                              category ==
                                                  _selectedChartCategory;
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
                              horizontalInterval: maxY == 0 ? 1 : maxY / 4,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey[200],
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: _buildBarGroups(displayData, maxY),
                          ),
                          swapAnimationDuration:
                          const Duration(milliseconds: 260),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),
                      ),

                      // ✅ 팝업: needsBudget 반영
                      if (popupData != null && selectedIndex >= 0)
                        Positioned(
                          top: 16,
                          left: popupLeft,
                          child: AnimatedOpacity(
                            opacity: _showPopup ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: _MeasureSize(
                              onChange: (size) {
                                if ((size.width - _popupWidth).abs() > 0.5) {
                                  setState(() => _popupWidth = size.width);
                                }
                              },
                              child: KeyedSubtree(
                                key: _popupKey,
                                child: _SelectedChartPopup(
                                  category:
                                  popupData['category'] as String? ?? '',
                                  budget:
                                  (popupData['budget'] as num?)?.toInt() ??
                                      0,
                                  spent:
                                  (popupData['spent'] as num?)?.toInt() ??
                                      0,
                                  needsBudget:
                                  popupData['needsBudget'] == true,
                                  formatter: _formatAmount,
                                  periodLabel: vm.budgetPeriod,
                                ),
                              ),
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

  // ───── helper들 ─────

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
        setState(() => _showPopup = true);
      });
    });
  }

  List<Map<String, dynamic>> _reorderChartData(List<Map<String, dynamic>> data) {
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

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100000;
    double maxVal = 0;
    for (final item in data) {
      final needsBudget = item['needsBudget'] == true;

      final budgetRaw = (item['budget'] as num?)?.toDouble() ?? 0.0;
      final spentRaw = (item['spent'] as num?)?.toDouble() ?? 0.0;

      // ✅ 예산 미설정이면 budget을 spent로 “표시용” 보정(빨강 초과 방지)
      final budget = needsBudget ? spentRaw : budgetRaw;
      final spent = spentRaw;

      final highest = math.max(budget, spent);
      if (highest > maxVal) maxVal = highest;
    }
    final scaled = (maxVal * 1.2).ceil();
    return scaled <= 0 ? 1.0 : scaled.toDouble();
  }

  List<BarChartGroupData> _buildBarGroups(
      List<Map<String, dynamic>> data,
      double maxY,
      ) {
    return List.generate(data.length, (index) {
      final item = data[index];

      final needsBudget = item['needsBudget'] == true;
      final budgetRaw = (item['budget'] as num?)?.toDouble() ?? 0.0;
      final spentRaw = (item['spent'] as num?)?.toDouble() ?? 0.0;

      // ✅ 예산 미설정이면 budget을 spent로 “표시용” 보정(빨강 초과 방지)
      final budget = needsBudget ? spentRaw : budgetRaw;
      final spent = spentRaw;

      final isOverBudget = needsBudget ? false : (spent > budget);

      final isTotal = item['isTotal'] == true;
      final category = item['category'] as String?;

      final hasSelection = _selectedChartCategory != null;
      final collapsePhase =
          hasSelection && (_isCollapsing || !_showSelectionLayout);
      final layoutActive = hasSelection && _showSelectionLayout && !_isCollapsing;
      final isSelected = layoutActive && category == _selectedChartCategory;

      final baseWidth = isTotal ? 48.0 : 36.0;
      final rodWidth =
      layoutActive ? (isSelected ? baseWidth + 12 : baseWidth - 8) : baseWidth;

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
          final baseMax = math.max(budget, spent);
          final factor = baseMax > 0 ? maxY / baseMax : 0;
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

      final effectiveSpent = scaledSpent.clamp(0.0, maxY);
      final effectiveBudget = scaledBudget.clamp(0.0, maxY);

      final lowerHeight = math.min(effectiveSpent, effectiveBudget);
      final upperHeight = math.max(effectiveSpent, effectiveBudget);

      const hoverRed = Color(0xFFFF5F5F);
      final radiusValue = isSelected ? 16.0 : 8.0;
      const epsilon = 0.0001;

      final List<BarChartRodStackItem> stackItems = [];

      if (lowerHeight > epsilon) {
        final Color lowerColor;
        if (needsBudget) {
          lowerColor = Colors.grey[300]!;
        } else {
          lowerColor = isOverBudget
              ? Colors.grey[300]!
              : (isSelected
              ? AppColors.primary.withOpacity(0.92)
              : AppColors.primary);
        }
        stackItems.add(BarChartRodStackItem(0, lowerHeight, lowerColor));
      }

      final upperSegHeight = (upperHeight - lowerHeight).clamp(0.0, maxY);
      if (upperSegHeight > epsilon) {
        final upperColor = isOverBudget ? hoverRed : Colors.grey[300]!;
        stackItems.add(BarChartRodStackItem(lowerHeight, upperHeight, upperColor));
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
              top: Radius.circular(radiusValue),
              bottom: Radius.zero,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCategoryEditButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context, rootNavigator: true).pushNamed('/category_edit');
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          children: const [
            Icon(Icons.tune, size: 16, color: Colors.black87),
            SizedBox(width: 6),
            Text(
              '카테고리 편집',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(ReportViewModel vm) {
    const periods = ['주간', '월간'];

    return TwoOptionToggle(
      labels: periods,
      selected: vm.budgetPeriod,
      width: 120,
      height: 34,
      onChanged: (period) {
        if (vm.budgetPeriod != period) {
          _resetSelectionState();
          vm.setBudgetPeriod(period);
        }
      },
    );
  }
}

class _SelectedChartPopup extends StatelessWidget {
  const _SelectedChartPopup({
    required this.category,
    required this.budget,
    required this.spent,
    required this.needsBudget,
    required this.formatter,
    required this.periodLabel,
  });

  final String category;
  final int budget;
  final int spent;
  final bool needsBudget;
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
            needsBudget
                ? '$periodLabel 총 예산: 설정 필요'
                : '$periodLabel 총 예산: ₩${formatter(budget)}',
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
    if (needsBudget) {
      return const Text(
        '예산 설정 필요',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
        ),
      );
    }

    final isOverBudget = spent > budget;
    final diff = spent - budget;

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
      final remaining = budget - spent;
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

typedef OnWidgetSizeChange = void Function(Size size);

class _MeasureSize extends StatefulWidget {
  const _MeasureSize({
    required this.onChange,
    required this.child,
  });

  final OnWidgetSizeChange onChange;
  final Widget child;

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final render = context.findRenderObject();
      if (render is RenderBox) {
        final newSize = render.size;
        if (_oldSize == null || _oldSize != newSize) {
          _oldSize = newSize;
          widget.onChange(newSize);
        }
      }
    });

    return widget.child;
  }
}

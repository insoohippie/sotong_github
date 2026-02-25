import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/theme/app_colors.dart';
import '../../../../component/buttons/period_toggle.dart';

import '../../../../view_model/report/report_view_model.dart';
import '../../../../model/report/report_models.dart';

class ReportCategoryBudgetChartSection extends StatefulWidget {
  const ReportCategoryBudgetChartSection({super.key});

  @override
  State<ReportCategoryBudgetChartSection> createState() =>
      _ReportCategoryBudgetChartSectionState();
}

class _ReportCategoryBudgetChartSectionState
    extends State<ReportCategoryBudgetChartSection> {
  String? _selectedChartKey;
  bool _isCollapsing = false;
  bool _showSelectionLayout = false;
  bool _showPopup = false;
  Timer? _selectionTimer;
  Timer? _popupTimer;
  Timer? _hapticTimer;

  final GlobalKey _popupKey = GlobalKey();
  double _popupWidth = 220;

  @override
  void dispose() {
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    _hapticTimer?.cancel();
    super.dispose();
  }

  void _playSelectionSequentialHaptic() {
    _hapticTimer?.cancel();
    HapticFeedback.selectionClick();
    int count = 1;
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) {
        _hapticTimer?.cancel();
        return;
      }
      if (count >= 6) {
        _hapticTimer?.cancel();
        _hapticTimer = null;
        return;
      }
      HapticFeedback.selectionClick();
      count++;
    });
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  double _calcPopupLeft({
    required double chartWidth,
    required int index,
    required int count,
    required double popupWidth,
  }) {
    final double centerX =
    (count <= 1) ? chartWidth / 2 : (chartWidth * index / (count - 1));
    final double rawLeft = centerX - (popupWidth / 2);
    final double maxLeft = math.max(0.0, chartWidth - popupWidth);
    return rawLeft.clamp(0.0, maxLeft);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final chart = vm.budgetChart;
    final rows = chart?.rows ?? const <ReportCategoryBudgetRow>[];

    final displayData = _reorderChartData(rows);
    final maxY = _getMaxY(displayData);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.12),
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
                  ReportCategoryBudgetRow? popupRow;

                  if (_showPopup && _selectedChartKey != null) {
                    final match =
                    displayData.where((r) => r.categoryKey == _selectedChartKey);
                    if (match.isNotEmpty) popupRow = match.first;
                  }

                  final selectedIndex = (_selectedChartKey == null)
                      ? -1
                      : displayData.indexWhere(
                        (e) => e.categoryKey == _selectedChartKey,
                  );

                  final popupLeft = (popupRow != null && selectedIndex >= 0)
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
                                final row = displayData[index];
                                _startSelectionTransition(row.categoryKey);
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
                                      final row = displayData[idx];
                                      final isSelected = _showSelectionLayout &&
                                          row.categoryKey == _selectedChartKey;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          row.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: theme.colorScheme.onSurface,
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
                                color: theme.dividerColor,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: _buildBarGroups(
                              displayData,
                              maxY,
                              theme,
                            ),
                          ),
                          swapAnimationDuration:
                          const Duration(milliseconds: 260),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),
                      ),

                      if (popupRow != null && selectedIndex >= 0)
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
                                  title: '${popupRow.emoji} ${popupRow.name}',
                                  planned: popupRow.planned,
                                  spent: popupRow.spent,
                                  needsBudget: popupRow.planned <= 0,
                                  formatter: _formatAmount,
                                  periodLabel: vm.rangeLabel,
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
      _selectedChartKey = null;
      _isCollapsing = false;
      _showSelectionLayout = false;
      _showPopup = false;
    });
  }

  void _startSelectionTransition(String key) {
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    _playSelectionSequentialHaptic();
    setState(() {
      _selectedChartKey = key;
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

  List<ReportCategoryBudgetRow> _reorderChartData(
      List<ReportCategoryBudgetRow> data,
      ) {
    if (_selectedChartKey == null || !_showSelectionLayout) {
      return List<ReportCategoryBudgetRow>.from(data);
    }
    final index = data.indexWhere((r) => r.categoryKey == _selectedChartKey);
    if (index <= 0) return List<ReportCategoryBudgetRow>.from(data);

    final reordered = List<ReportCategoryBudgetRow>.from(data);
    final selected = reordered.removeAt(index);
    reordered.insert(0, selected);
    return reordered;
  }

  double _getMaxY(List<ReportCategoryBudgetRow> data) {
    if (data.isEmpty) return 100000;

    double maxVal = 0;
    for (final r in data) {
      final planned = r.planned.toDouble();
      final spent = r.spent.toDouble();

      // planned=0이면 표시용 planned=spent 보정
      final effectivePlanned = planned <= 0 ? spent : planned;

      final highest = math.max(effectivePlanned, spent);
      if (highest > maxVal) maxVal = highest;
    }
    final scaled = (maxVal * 1.2).ceil();
    return scaled <= 0 ? 1.0 : scaled.toDouble();
  }

  List<BarChartGroupData> _buildBarGroups(
      List<ReportCategoryBudgetRow> data,
      double maxY,
      ThemeData theme,
      ) {
    return List.generate(data.length, (index) {
      final r = data[index];

      final plannedRaw = r.planned.toDouble();
      final spentRaw = r.spent.toDouble();

      final needsBudget = plannedRaw <= 0;
      final planned = needsBudget ? spentRaw : plannedRaw;
      final spent = spentRaw;

      final isOverBudget = needsBudget ? false : (spent > planned);

      final hasSelection = _selectedChartKey != null;
      final collapsePhase =
          hasSelection && (_isCollapsing || !_showSelectionLayout);
      final layoutActive =
          hasSelection && _showSelectionLayout && !_isCollapsing;
      final isSelected = layoutActive && r.categoryKey == _selectedChartKey;

      final baseWidth = r.isTotal ? 48.0 : 36.0;
      final rodWidth = layoutActive
          ? (isSelected ? baseWidth + 12 : baseWidth - 8)
          : baseWidth;

      double scaledPlanned;
      double scaledSpent;

      if (!hasSelection) {
        scaledPlanned = planned;
        scaledSpent = spent;
      } else if (collapsePhase) {
        scaledPlanned = 0;
        scaledSpent = 0;
      } else if (layoutActive) {
        if (isSelected) {
          final baseMax = math.max(planned, spent);
          final factor = baseMax > 0 ? maxY / baseMax : 0;
          scaledPlanned = planned * factor;
          scaledSpent = spent * factor;
        } else {
          scaledPlanned = planned * 0.4;
          scaledSpent = spent * 0.4;
        }
      } else {
        scaledPlanned = planned;
        scaledSpent = spent;
      }

      final effectiveSpent = scaledSpent.clamp(0.0, maxY);
      final effectivePlanned = scaledPlanned.clamp(0.0, maxY);

      final lowerHeight = math.min(effectiveSpent, effectivePlanned);
      final upperHeight = math.max(effectiveSpent, effectivePlanned);

      const hoverRed = Color(0xFFFF5F5F);
      final radiusValue = isSelected ? 16.0 : 8.0;
      const epsilon = 0.0001;

      final isDark = theme.brightness == Brightness.dark;
      final greyBar = isDark
          ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
          : Colors.grey[300]!;

      final List<BarChartRodStackItem> stackItems = [];

      if (lowerHeight > epsilon) {
        final Color lowerColor;
        if (needsBudget) {
          lowerColor = greyBar;
        } else {
          lowerColor = isOverBudget
              ? greyBar
              : (isSelected
              ? AppColors.primary.withOpacity(0.92)
              : AppColors.primary);
        }
        stackItems.add(BarChartRodStackItem(0, lowerHeight, lowerColor));
      }

      final upperSegHeight = (upperHeight - lowerHeight).clamp(0.0, maxY);
      if (upperSegHeight > epsilon) {
        final upperColor = isOverBudget ? hoverRed : greyBar;
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
              top: Radius.circular(radiusValue),
              bottom: Radius.zero,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCategoryEditButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final btnBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;
    final btnBorder = isDark ? theme.dividerColor : Colors.grey.shade300;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context, rootNavigator: true).pushNamed('/category_edit');
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: btnBorder, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.tune, size: 16, color: theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              '카테고리 편집',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(ReportViewModel vm) {
    const periods = ['주간', '월간'];
    final selected =
    (vm.rangeType == ReportRangeType.weekly) ? '주간' : '월간';

    return TwoOptionToggle(
      labels: periods,
      selected: selected,
      width: 106,
      height: 30,
      onChanged: (period) {
        final next =
        (period == '주간') ? ReportRangeType.weekly : ReportRangeType.monthly;

        if (vm.rangeType != next) {
          _resetSelectionState();
          vm.setRangeType(next);
        }
      },
    );
  }
}

class _SelectedChartPopup extends StatelessWidget {
  const _SelectedChartPopup({
    required this.title,
    required this.planned,
    required this.spent,
    required this.needsBudget,
    required this.formatter,
    required this.periodLabel,
  });

  final String title;
  final int planned;
  final int spent;
  final bool needsBudget;
  final String Function(int) formatter;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.3 : 0.08,
            ),
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
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            needsBudget
                ? '$periodLabel 총 예산: 설정 필요'
                : '$periodLabel 총 예산: ₩${formatter(planned)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
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

    final isOverBudget = spent > planned;
    final diff = spent - planned;

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
      final remaining = planned - spent;
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
  const _MeasureSize({required this.onChange, required this.child});

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
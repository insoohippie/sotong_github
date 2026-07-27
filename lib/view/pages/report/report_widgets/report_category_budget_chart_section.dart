import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:sotong/component/theme/app_colors.dart';
import '../../../../component/buttons/period_toggle.dart';

import '../../../../services/chart_animation_haptic.dart';
import '../../../../services/tab_chart_animation_notifier.dart';
import '../../../../view_model/report/report_view_model.dart';
import '../../../../model/report/report_models.dart';

class ReportCategoryBudgetChartSection extends StatefulWidget {
  const ReportCategoryBudgetChartSection({super.key});

  @override
  State<ReportCategoryBudgetChartSection> createState() =>
      _ReportCategoryBudgetChartSectionState();
}

class _ReportCategoryBudgetChartSectionState
    extends State<ReportCategoryBudgetChartSection>
    with SingleTickerProviderStateMixin {
  static const _entryAnimationDuration = Duration(milliseconds: 1000);
  static const _entryHapticInterval = Duration(milliseconds: 110);

  String? _selectedChartKey;
  int? _selectedSlotIndex;
  bool _isCollapsing = false;
  bool _showSelectionLayout = false;
  bool _showPopup = false;
  Timer? _selectionTimer;
  Timer? _popupTimer;
  Timer? _hapticTimer;

  late final AnimationController _entryController;
  late final Animation<double> _entryAnim;
  final ChartAnimationHapticPlayer _chartHaptic = ChartAnimationHapticPlayer();
  int? _syncedReportTick;
  ReportRangeType? _syncedRangeType;

  int _categoryWindowStart = 0;
  double _windowItemExtent = 56;
  final ScrollController _windowScrollController = ScrollController();
  double _dragAccumDx = 0;
  bool _isWindowDragging = false;
  DateTime? _lastDragEndAt;
  int? _lastDragHapticIndex;

  final GlobalKey _popupKey = GlobalKey();
  double _popupWidth = 220;

  static const String _etcKey = 'etc';

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: _entryAnimationDuration,
    );
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _startEntryAnimation();
  }

  void _startEntryAnimation() {
    _entryController.forward(from: 0);
    _playEntrySequentialHaptic();
  }

  void _playEntrySequentialHaptic() {
    _chartHaptic.play(
      duration: _entryAnimationDuration,
      interval: _entryHapticInterval,
    );
  }

  void _replayEntryAnimation() {
    _resetSelectionState();
    _entryController
      ..stop()
      ..reset();
    _startEntryAnimation();
  }

  @override
  void dispose() {
    _chartHaptic.cancel();
    _entryController.dispose();
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    _hapticTimer?.cancel();
    _windowScrollController.dispose();
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
    final double centerX = (count <= 1)
        ? chartWidth / 2
        : (chartWidth * index / (count - 1));
    final double rawLeft = centerX - (popupWidth / 2);
    final double maxLeft = math.max(0.0, chartWidth - popupWidth);
    return rawLeft.clamp(0.0, maxLeft);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    final reportTick = context.reportChartAnimationTick;
    if (_syncedReportTick == null) {
      _syncedReportTick = reportTick;
    } else if (reportTick != _syncedReportTick) {
      _syncedReportTick = reportTick;
      _replayEntryAnimation();
    }

    if (_syncedRangeType == null) {
      _syncedRangeType = vm.rangeType;
    } else if (_syncedRangeType != vm.rangeType &&
        !vm.isLoading &&
        vm.budgetChart != null) {
      _syncedRangeType = vm.rangeType;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _replayEntryAnimation();
      });
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final chart = vm.budgetChart;
    final rows = chart?.rows ?? const <ReportCategoryBudgetRow>[];
    final categoryCount = rows.where((r) => !r.isTotal).length;
    final maxWindowStart = _maxCategoryWindowStart(categoryCount);

    final slotData = _buildChartSlots(rows);
    final maxY = _getMaxY(slotData);

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
          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              vm.chartRangeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 320,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final estimatedStep = constraints.maxWidth / 5;
                  if ((_windowItemExtent - estimatedStep).abs() > 0.5) {
                    _windowItemExtent = estimatedStep;
                  }
                  _clampWindowOffsetOnly(maxWindowStart);

                  ReportCategoryBudgetRow? popupRow;

                  final selectedIndex =
                  (_selectedSlotIndex != null &&
                      _selectedSlotIndex! >= 0 &&
                      _selectedSlotIndex! < slotData.length)
                      ? _selectedSlotIndex!
                      : -1;

                  if (_showPopup && _selectedChartKey != null) {
                    final match = slotData.where(
                          (row) => row?.categoryKey == _selectedChartKey,
                    );
                    if (match.isNotEmpty) {
                      popupRow = match.first;
                    }
                  }

                  final popupLeft = (popupRow != null && selectedIndex >= 0)
                      ? (() {
                    const double barGap = 40;
                    final bool placeRight = selectedIndex <= 2;

                    final double chartWidth = constraints.maxWidth;
                    final double groupCount = slotData.length.toDouble();

                    // 현재 막대의 중심 x
                    final double centerX = (groupCount <= 1)
                        ? chartWidth / 2
                        : (chartWidth * selectedIndex / (groupCount - 1));

                    // 현재 막대 너비와 비슷하게 맞춤
                    final double barWidth = popupRow!.isTotal
                        ? 48.0
                        : 36.0;
                    final double halfBarWidth = barWidth / 2;

                    final double rawLeft = placeRight
                    // 왼쪽 3개: 막대 오른쪽에 배치
                        ? centerX + halfBarWidth + barGap
                    // 나머지: 막대 왼쪽에 배치
                        : centerX - halfBarWidth - barGap - _popupWidth;

                    final double maxLeft = math.max(
                      0.0,
                      chartWidth - _popupWidth,
                    );
                    return rawLeft.clamp(0.0, maxLeft);
                  })()
                      : 0.0;

                  final isEtcSelected =
                      popupRow != null && popupRow.categoryKey == _etcKey;

                  final unplannedList = isEtcSelected
                      ? vm.unplannedSpentListForChartRange(maxItems: 8)
                      : const <({String name, int spent})>[];

                  final plannedDetailList = (!isEtcSelected && popupRow != null)
                      ? vm.plannedSpentDetailListForChartRange(
                    popupRow.categoryKey,
                    maxItems: 8,
                  )
                      : const <({String date, int spent})>[];

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart: (_) {
                            _dragAccumDx = 0;
                            _isWindowDragging = false;
                            _lastDragHapticIndex = _categoryWindowStart;
                          },
                          onHorizontalDragUpdate: (details) {
                            if (maxWindowStart <= 0) return;
                            final delta = details.primaryDelta ?? 0;
                            if (delta == 0) return;
                            _dragAccumDx += delta.abs();
                            if (!_isWindowDragging && _dragAccumDx < 10) {
                              return;
                            }
                            _isWindowDragging = true;
                            _scrollByDragDelta(delta, maxWindowStart);
                          },
                          onHorizontalDragEnd: (_) {
                            if (_isWindowDragging) {
                              _lastDragEndAt = DateTime.now();
                              _snapToNearestWindow(maxWindowStart);
                            }
                            _dragAccumDx = 0;
                            _isWindowDragging = false;
                            _lastDragHapticIndex = null;
                          },
                          onHorizontalDragCancel: () {
                            if (_isWindowDragging) {
                              _lastDragEndAt = DateTime.now();
                              _snapToNearestWindow(maxWindowStart);
                            }
                            _dragAccumDx = 0;
                            _isWindowDragging = false;
                            _lastDragHapticIndex = null;
                          },
                          child: AnimatedBuilder(
                            animation: _entryAnim,
                            builder: (context, _) {
                              return BarChart(
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
                                      final justDragged =
                                          _lastDragEndAt != null &&
                                              DateTime.now()
                                                  .difference(_lastDragEndAt!)
                                                  .inMilliseconds <
                                                  120;
                                      if (_isWindowDragging || justDragged) {
                                        return;
                                      }
                                      if (response == null ||
                                          response.spot == null) {
                                        _resetSelectionState();
                                        return;
                                      }
                                      final index =
                                          response.spot!.touchedBarGroupIndex;
                                      if (index < 0 || index >= slotData.length) {
                                        _resetSelectionState();
                                        return;
                                      }
                                      final row = slotData[index];
                                      if (row == null) {
                                        _resetSelectionState();
                                        return;
                                      }
                                      _startSelectionTransition(
                                        row.categoryKey,
                                        index,
                                      );
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
                                          if (idx >= 0 && idx < slotData.length) {
                                            final row = slotData[idx];
                                            if (row == null) {
                                              return const SizedBox.shrink();
                                            }
                                            final isSelected =
                                                _showSelectionLayout &&
                                                    idx == _selectedSlotIndex &&
                                                    row.categoryKey ==
                                                        _selectedChartKey;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                row.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color:
                                                  theme.colorScheme.onSurface,
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
                                    slotData,
                                    maxY,
                                    theme,
                                    entryFactor: _entryAnim.value,
                                  ),
                                ),
                                swapAnimationDuration: const Duration(
                                  milliseconds: 260,
                                ),
                                swapAnimationCurve: Curves.easeOutCubic,
                              );
                            },
                          ),
                        ),
                      ),

                      if (popupRow != null && selectedIndex >= 0)
                        Positioned(
                          top: 0,
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
                                  title: isEtcSelected
                                      ? '플랜 외 소비'
                                      : '${popupRow.emoji} ${popupRow.name}',
                                  planned: popupRow.planned,
                                  spent: popupRow.spent,
                                  periodLabel: vm.rangeLabel,
                                  formatter: _formatAmount,
                                  isEtcSelected: isEtcSelected,
                                  isTotalSelected: popupRow.isTotal,
                                  unplannedList: unplannedList,
                                  // plannedDetailList: plannedDetailList,
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

          if (maxWindowStart > 0) ...[
            const SizedBox(height: 10),
            _buildCategoryDragIndicator(theme: theme, maxStart: maxWindowStart),
          ],

          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: _windowItemExtent,
              height: 1,
              child: IgnorePointer(
                child: ListView.builder(
                  controller: _windowScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemExtent: _windowItemExtent,
                  itemCount: math.max(1, maxWindowStart + 1),
                  itemBuilder: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetSelectionState() {
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    setState(() {
      _selectedChartKey = null;
      _selectedSlotIndex = null;
      _isCollapsing = false;
      _showSelectionLayout = false;
      _showPopup = false;
    });
  }

  void _startSelectionTransition(String key, int slotIndex) {
    _selectionTimer?.cancel();
    _popupTimer?.cancel();
    _playSelectionSequentialHaptic();
    setState(() {
      _selectedChartKey = key;
      _selectedSlotIndex = slotIndex;
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

  List<ReportCategoryBudgetRow?> _buildChartSlots(
      List<ReportCategoryBudgetRow> rows,
      ) {
    final categories = rows.where((r) => !r.isTotal).toList(growable: false);

    ReportCategoryBudgetRow? totalRow;
    for (final row in rows) {
      if (row.isTotal) {
        totalRow = row;
        break;
      }
    }

    final maxStart = _maxCategoryWindowStart(categories.length);
    if (_categoryWindowStart > maxStart) {
      _categoryWindowStart = maxStart;
    }

    final visibleCategories = categories
        .skip(_categoryWindowStart)
        .take(4)
        .toList(growable: false);

    final slots = List<ReportCategoryBudgetRow?>.filled(5, null);
    for (int i = 0; i < visibleCategories.length && i < 4; i++) {
      slots[i] = visibleCategories[i];
    }
    slots[4] = totalRow;

    return slots;
  }

  int _maxCategoryWindowStart(int categoryCount) {
    return math.max(0, categoryCount - 4);
  }

  void _scrollByDragDelta(double deltaDx, int maxStart) {
    if (!_windowScrollController.hasClients) return;

    final maxOffset = _effectiveMaxOffset(maxStart);
    final nextOffset = (_windowScrollController.offset - deltaDx).clamp(
      0.0,
      maxOffset,
    );
    _windowScrollController.jumpTo(nextOffset);
    _syncWindowStartFromOffset(nextOffset, maxStart);
  }

  void _snapToNearestWindow(int maxStart) {
    if (!_windowScrollController.hasClients) return;
    final currentOffset = _windowScrollController.offset;
    final maxOffset = _effectiveMaxOffset(maxStart);
    final step = (maxStart > 0) ? (maxOffset / maxStart) : _windowItemExtent;
    final safeStep = step <= 0 ? _windowItemExtent : step;
    final targetIndex = (currentOffset / safeStep).round().clamp(0, maxStart);
    final targetOffset = (targetIndex * safeStep).clamp(0.0, maxOffset);

    _windowScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
    );

    setState(() {
      _categoryWindowStart = targetIndex;
      _selectedChartKey = null;
      _selectedSlotIndex = null;
      _isCollapsing = false;
      _showSelectionLayout = false;
      _showPopup = false;
    });
  }

  void _syncWindowStartFromOffset(double offset, int maxStart) {
    final maxOffset = _effectiveMaxOffset(maxStart);
    final step = (maxStart > 0) ? (maxOffset / maxStart) : _windowItemExtent;
    final safeStep = step <= 0 ? _windowItemExtent : step;

    final next = (offset / safeStep).floor().clamp(0, maxStart);
    if (next == _categoryWindowStart) return;

    if (_isWindowDragging && _lastDragHapticIndex != next) {
      HapticFeedback.selectionClick();
      _lastDragHapticIndex = next;
    }

    setState(() {
      _categoryWindowStart = next;
      _selectedChartKey = null;
      _selectedSlotIndex = null;
      _isCollapsing = false;
      _showSelectionLayout = false;
      _showPopup = false;
    });
  }

  void _clampWindowOffsetOnly(int maxStart) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_windowScrollController.hasClients) return;

      final maxOffset = _effectiveMaxOffset(maxStart);
      final currentOffset = _windowScrollController.offset;
      final clamped = currentOffset.clamp(0.0, maxOffset);

      if ((currentOffset - clamped).abs() > 0.5) {
        _windowScrollController.jumpTo(clamped);
      }
    });
  }

  double _effectiveMaxOffset(int maxStart) {
    if (_windowScrollController.hasClients) {
      return _windowScrollController.position.maxScrollExtent;
    }
    return maxStart * _windowItemExtent;
  }

  Widget _buildCategoryDragIndicator({
    required ThemeData theme,
    required int maxStart,
  }) {
    final progress = maxStart == 0
        ? 0.0
        : _categoryWindowStart.clamp(0, maxStart) / maxStart;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final railWidth = constraints.maxWidth * 0.1;
          final thumbWidth = railWidth * 0.45;
          final maxLeft = math.max(0.0, railWidth - thumbWidth);
          final left = maxLeft * progress;

          return SizedBox(
            height: 12,
            child: Center(
              child: SizedBox(
                width: railWidth,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      left: left,
                      top: 2,
                      child: Container(
                        width: thumbWidth,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _getMaxY(List<ReportCategoryBudgetRow?> data) {
    final rows = data.whereType<ReportCategoryBudgetRow>().toList(
      growable: false,
    );
    if (rows.isEmpty) return 100000;

    double maxVal = 0;
    for (final r in rows) {
      final planned = r.planned.toDouble();
      final spent = r.spent.toDouble();
      final effectivePlanned = planned <= 0 ? spent : planned;
      final highest = math.max(effectivePlanned, spent);
      if (highest > maxVal) maxVal = highest;
    }
    final scaled = (maxVal * 1.2).ceil();
    return scaled <= 0 ? 1.0 : scaled.toDouble();
  }

  List<BarChartGroupData> _buildBarGroups(
      List<ReportCategoryBudgetRow?> data,
      double maxY,
      ThemeData theme, {
      double entryFactor = 1.0,
      }) {
    final anim = entryFactor.clamp(0.0, 1.0);
    return List.generate(data.length, (index) {
      final r = data[index];

      if (r == null) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              fromY: 0,
              toY: 0,
              width: 36,
              color: Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
          ],
        );
      }

      final plannedRaw = r.planned.toDouble();
      final spentRaw = r.spent.toDouble();
      final isEtc = r.categoryKey == _etcKey;

      final needsBudget = !isEtc && plannedRaw <= 0;
      final planned = isEtc ? spentRaw : (needsBudget ? spentRaw : plannedRaw);
      final spent = spentRaw;

      final isOverBudget = isEtc
          ? false
          : (needsBudget ? false : (spent > planned));

      final hasSelection = _selectedChartKey != null;
      final collapsePhase =
          hasSelection && (_isCollapsing || !_showSelectionLayout);
      final layoutActive =
          hasSelection && _showSelectionLayout && !_isCollapsing;
      final isSelected =
          layoutActive &&
              index == _selectedSlotIndex &&
              r.categoryKey == _selectedChartKey;

      final baseWidth = r.isTotal ? 48.0 : 36.0;
      final rodWidth = layoutActive
          ? (isSelected ? baseWidth + 12 : baseWidth - 8)
          : baseWidth;

      double scaledPlanned;
      double scaledSpent;

      if (isEtc) {
        if (!hasSelection) {
          scaledPlanned = spent;
          scaledSpent = spent;
        } else if (collapsePhase) {
          scaledPlanned = 0;
          scaledSpent = 0;
        } else if (layoutActive) {
          if (isSelected) {
            final factor = spent > 0 ? maxY / spent : 0;
            scaledPlanned = spent * factor;
            scaledSpent = spent * factor;
          } else {
            scaledPlanned = spent * 0.4;
            scaledSpent = spent * 0.4;
          }
        } else {
          scaledPlanned = spent;
          scaledSpent = spent;
        }
      } else {
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
      }

      final effectiveSpent = (scaledSpent.clamp(0.0, maxY)) * anim;
      final effectivePlanned = (scaledPlanned.clamp(0.0, maxY)) * anim;

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
        if (isEtc) {
          lowerColor = isSelected
              ? AppColors.primary.withOpacity(0.92)
              : AppColors.primary;
        } else if (needsBudget) {
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
      if (!isEtc && upperSegHeight > epsilon) {
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
      onTap: () async {
        final changed = await Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed('/category_edit');

        if (!context.mounted) return;

        if (changed == true) {
          await context.read<ReportViewModel>().refreshAfterPlanUpdated();
        }
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
    final selected = (vm.rangeType == ReportRangeType.weekly) ? '주간' : '월간';
    final viewWidth = MediaQuery.sizeOf(context).width;
    final toggleWidth = viewWidth <= 386
        ? 88.0
        : viewWidth < 412
        ? 96.0
        : 106.0;
    final toggleHeight = viewWidth <= 386
        ? 26.0
        : viewWidth < 412
        ? 28.0
        : 30.0;
    final toggleFontSize = viewWidth <= 386
        ? 10.0
        : viewWidth < 412
        ? 11.0
        : 12.0;

    return TwoOptionToggle(
      labels: periods,
      selected: selected,
      width: toggleWidth,
      height: toggleHeight,
      fontSize: toggleFontSize,
      onChanged: (period) {
        final next = (period == '주간')
            ? ReportRangeType.weekly
            : ReportRangeType.monthly;

        if (vm.rangeType != next) {
          _resetSelectionState();
          setState(() => _categoryWindowStart = 0);
          if (_windowScrollController.hasClients) {
            _windowScrollController.jumpTo(0);
          }
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
    required this.periodLabel,
    required this.formatter,
    required this.isEtcSelected,
    required this.isTotalSelected,
    required this.unplannedList,
    // required this.plannedDetailList,
  });

  final String title;
  final int planned;
  final int spent;
  final String periodLabel;
  final String Function(int) formatter;

  final bool isEtcSelected;
  final bool isTotalSelected;
  final List<({String name, int spent})> unplannedList;
  // final List<({String date, int spent})> plannedDetailList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final showEtcList = isEtcSelected && unplannedList.isNotEmpty;
    // final showPlannedList =
    //     !isEtcSelected && !isTotalSelected && plannedDetailList.isNotEmpty;

    // 리스트는 최대 4줄까지만 보이고, 넘으면 내부 스크롤
    const double rowHeight = 24;
    // final double plannedListHeight =
    //     math.min(plannedDetailList.length, 3) * rowHeight;
    final double etcListHeight = math.min(unplannedList.length, 3) * rowHeight;

    return IntrinsicWidth(
      child: Container(
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
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
              const SizedBox(height: 10),

              if (showEtcList) ...[
                Text(
                  '총 소비 금액: ₩${formatter(spent)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.82),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: etcListHeight,
                  child: SingleChildScrollView(
                    child: Column(
                      children: unplannedList.map((it) {
                        return SizedBox(
                          height: rowHeight,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '₩${formatter(it.spent)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  planned <= 0 ? '총 예산: 설정 필요' : '총 예산: ₩${formatter(planned)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.82),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '총 소비 금액: ₩${formatter(spent)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.82),
                  ),
                ),
                const SizedBox(height: 4),
                _buildUsageText(),
                // if (showPlannedList) ...[
                //   const SizedBox(height: 8),
                //   Divider(
                //     height: 1,
                //     thickness: 1,
                //     color: theme.dividerColor.withOpacity(0.7),
                //   ),
                //   const SizedBox(height: 8),
                //   SizedBox(
                //     height: plannedListHeight,
                //     child: SingleChildScrollView(
                //       child: Column(
                //         children: plannedDetailList.map((it) {
                //           return SizedBox(
                //             height: rowHeight,
                //             child: Row(
                //               children: [
                //                 Expanded(
                //                   child: Text(
                //                     it.date,
                //                     maxLines: 1,
                //                     overflow: TextOverflow.ellipsis,
                //                     style: TextStyle(
                //                       fontSize: 12,
                //                       fontWeight: FontWeight.w600,
                //                       color: theme.colorScheme.onSurface,
                //                     ),
                //                   ),
                //                 ),
                //                 const SizedBox(width: 10),
                //                 Text(
                //                   '₩${formatter(it.spent)}',
                //                   style: TextStyle(
                //                     fontSize: 12,
                //                     fontWeight: FontWeight.w800,
                //                     color: theme.colorScheme.onSurface,
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           );
                //         }).toList(),
                //       ),
                //     ),
                //   ),
                // ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageText() {
    if (planned <= 0) {
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
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF5F5F),
        ),
      );
    } else {
      final remaining = planned - spent;
      return Text(
        '미달 사용액: ₩${formatter(remaining)}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
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

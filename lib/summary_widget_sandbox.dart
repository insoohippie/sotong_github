import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// 너의 실제 경로로 맞춰줘
import 'package:sotong_local/view/pages/plan/chat_widgets/plan_summary_chart_widget.dart';
import 'package:sotong_local/model/plan/plan_metrics.dart';
import 'package:sotong_local/model/plan/sub_plan.dart';
import 'package:sotong_local/model/plan/total_plan.dart';
import 'package:sotong_local/model/saving_calculation_result.dart';

class PieAndPlanSummaryPage extends StatefulWidget {
  PieAndPlanSummaryPage({super.key});
  @override
  State<PieAndPlanSummaryPage> createState() => _PieAndPlanSummaryPageState();
}

class _PieAndPlanSummaryPageState extends State<PieAndPlanSummaryPage> {
  // fl_chart touched indices
  int touchedIndexSolid = -1;
  int touchedIndexDonut = -1;
  int touchedIndexTiny = -1;

  // 팔레트(연→중→진 파랑)
  final Color colorFixed = Color(0xFFB9D2FF);    // 고정지출
  final Color colorVariable = Color(0xFF8BB8FF); // 변동지출
  final Color colorSaving = Color(0xFF3C7BFF);   // 저축

  // 텍스트 배지 스타일(연하늘 컨테이너 느낌)
  final Color badgeBg = Color(0xFFEFF6FF);
  final Color badgeBorder = Color(0xFFDCEAFF);

  // 데이터
  late final TotalPlan plan;
  late final SavingCalculationResult calc;

  // Syncfusion
  TooltipBehavior? _sfTooltip;

  @override
  void initState() {
    super.initState();

    final metrics = PlanMetrics.fromRange(
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 29)),
      sumMonthlyIncome: 2000000,
      sumMonthlyConsume: 800000,
      sumDailyConsume: 20000,
    );
    plan = TotalPlan(
      planId: 'sandbox',
      planName: '유럽여행',
      targetAmount: 5000000,
      currentAmount: 0,
      currentAsset: 1200000,
      startDate: DateTime.now(),
      endDate: null,
      modEndDate: null,
      creationDate: DateTime.now(),
      autoService: true,
      subPlans: const {},
      result: TotalResult(
        totalMetrics: metrics,
        subResult: const SubPlanResult(subMetrics: [], subPlanList: []),
      ),
    );

    final totalMetrics = plan.result.totalMetrics;
    final income = totalMetrics.sumMonthlyIncome;
    final fixedC = totalMetrics.sumMonthlyConsume;
    final variableC = (totalMetrics.sumDailyConsume * 30);
    final saving = (income - fixedC - variableC).clamp(0, income);

    final dailySaving = income == 0 ? 0.0 : saving / 30.0;
    final requiredSaving = (plan.targetAmount ?? 0) - (plan.currentAsset ?? 0);
    final daysToGoal = dailySaving > 0 ? (requiredSaving / dailySaving) : 0;
    final goalDate = DateTime.now().add(Duration(days: daysToGoal.ceil()));

    calc = SavingCalculationResult(
      monthlySaving: saving.toDouble(),
      dailySaving: dailySaving.toDouble(),
      savingRatio: income == 0 ? 0 : saving / income,
      dailyNetSaving: dailySaving.toDouble(),
      requiredSaving: requiredSaving.toDouble(),
      daysToGoal: daysToGoal.toDouble(),
      totalSeconds: (daysToGoal * 24 * 60 * 60).toDouble(),
      goalDateTime: goalDate,
      savingPerSecond: dailySaving / (24 * 60 * 60),
    );

    _sfTooltip = TooltipBehavior(
      enable: true,
      header: '',
      format: 'point.x : point.y',
      canShowMarker: true,
    );
  }

  // ===== 공통 포맷 =====
  String _manWon(num v) {
    if (v <= 0) return '0만원';
    final man = (v / 10000).round();
    return '${man}만원';
  }

  @override
  Widget build(BuildContext context) {
    final metrics = plan.result.totalMetrics;
    final income = metrics.sumMonthlyIncome.toDouble();
    final fixedVal = metrics.sumMonthlyConsume.toDouble();
    final variableVal = (metrics.sumDailyConsume * 30).toDouble();
    final double savingVal = (calc.monthlySaving).clamp(0, income);

    final tinyVariable = income * 0.01; // 오버플로 테스트용
    final restForTiny = (fixedVal + savingVal) <= 0 ? income : (fixedVal + savingVal);

    // Syncfusion 데이터 공통 (x=라벨, y=금액)
    final sfData = [
      _SFItem('고정', fixedVal, colorFixed),
      _SFItem('변동', variableVal, colorVariable),
      _SFItem('저축', savingVal, colorSaving),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('fl_chart + Syncfusion (월 예산 시각화)')),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────── fl_chart 1) 파이(원형)
              _whiteCard(
                'fl_chart • Pie (금액/만원, 작은 조각 외부 라벨)',
                AspectRatio(
                  aspectRatio: 1.2,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndexSolid = -1;
                              return;
                            }
                            touchedIndexSolid = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0,
                      centerSpaceRadius: 0,
                      sections: _sections(
                        values: [fixedVal, variableVal, savingVal],
                        colors: [colorFixed, colorVariable, colorSaving],
                        labelsForBadge: ['고정', '변동', '저축'],
                        touchedIndex: touchedIndexSolid,
                        donut: false,
                        outsideLabelThreshold: 0.08,
                      ),
                    ),
                  ),
                ),
                height: 380,
              ),
              SizedBox(height: 14),

              // ───────── fl_chart 2) 도넛
              _whiteCard(
                'Syncfusion • Pie (만원 라벨, 저축만 분리)',
                SfCircularChart(
                  tooltipBehavior: _sfTooltip,
                  // smartLabelMode: SmartLabelMode.shift,
                  legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                  series: <PieSeries<_SFItem, String>>[
                    PieSeries<_SFItem, String>(
                      dataSource: sfData,
                      xValueMapper: (_SFItem d, _) => d.x,
                      yValueMapper: (_SFItem d, _) => d.y,
                      pointColorMapper: (_SFItem d, _) => d.color,
                      // ✅ '저축'만 explode
                      explode: true,
                      explodeIndex: 2,                 // sfData[2] == '저축'
                      explodeOffset: '8%',             // 분리 거리 (원하면 조절)
                      startAngle: 90,
                      endAngle: 90,
                      dataLabelMapper: (_SFItem d, _) => '${d.x}\n${_manWon(d.y)}',
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        connectorLineSettings: ConnectorLineSettings(
                          type: ConnectorType.curve,
                          length: '10%',
                          width: 1.5,
                        ),
                        textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                height: 320,
              ),
              SizedBox(height: 14),

              // ───────── fl_chart 3) 작은조각 테스트
              _whiteCard(
                'fl_chart • Doughnut (작은 조각 외부 금액)',
                AspectRatio(
                  aspectRatio: 1.2,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndexTiny = -1;
                              return;
                            }
                            touchedIndexTiny = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: _sections(
                        values: [restForTiny * 0.6, tinyVariable, restForTiny * 0.4],
                        colors: [colorFixed, colorVariable, colorSaving],
                        labelsForBadge: ['고정(큰)', '변동(작)', '저축(중)'],
                        touchedIndex: touchedIndexTiny,
                        donut: true,
                        outsideLabelThreshold: 0.10,
                      ),
                    ),
                  ),
                ),
                height: 380,
              ),
              SizedBox(height: 16),

              // ───────── Plan Summary
              _whiteCard(
                'Plan Summary',
                PlanSummaryChartWidget(
                  plan: plan,
                  calculation: calc,
                  userName: '하경',
                  onEdit: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정하기 눌림!')));
                  },
                ),
                height: 420,
              ),
              SizedBox(height: 16),

              // ===== Syncfusion 추가 =====

              // ───────── Syncfusion 1) 100% Stacked Bar
              _whiteCard(
                'Syncfusion • 100% Stacked Bar (월 예산 내 구성 비율)',
                SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  tooltipBehavior: _sfTooltip,
                  primaryXAxis: CategoryAxis(
                    majorGridLines: MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    numberFormat: NumberFormat.percentPattern(), // y축 퍼센트 느낌
                    axisLine: AxisLine(width: 0),
                    majorTickLines: MajorTickLines(size: 0),
                  ),
                  legend: Legend(isVisible: true),
                  series: [
                    StackedBar100Series<_SFItem, String>(
                      dataSource: sfData,
                      xValueMapper: (_SFItem d, _) => d.x, // '고정','변동','저축'을 하나의 막대에 쌓기 위해
                      yValueMapper: (_SFItem d, _) => d.y,
                      pointColorMapper: (_SFItem d, _) => d.color,
                      name: '고정지출',
                    ),
                  ],
                  // 한 카테고리만 보여주고 그 안에 여러 시리즈로 100% 쌓는 대신,
                  // 간결하게 한 막대('월 예산')에 세 값 쌓기:
                  // → 카테고리 하나로 만들려면 데이터를 [월 예산] 하나로 넣고
                  //   각 시리즈마다 고정/변동/저축을 y에 매핑해도 됨.
                ),
                height: 260,
              ),
              SizedBox(height: 14),

              // ───────── Syncfusion 2) Radial Bar
              _whiteCard(
                'Syncfusion • Radial Bar (만원 라벨, 최대=수입)',
                SfCircularChart(
                  tooltipBehavior: _sfTooltip,
                  legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                  series: <RadialBarSeries<_SFItem, String>>[
                    RadialBarSeries<_SFItem, String>(
                      dataSource: sfData,
                      xValueMapper: (_SFItem d, _) => d.x,
                      yValueMapper: (_SFItem d, _) => d.y,
                      pointColorMapper: (_SFItem d, _) => d.color,
                      maximumValue: metrics.sumMonthlyIncome.toDouble(),
                      cornerStyle: CornerStyle.bothCurve,
                      gap: '8%',
                      radius: '90%',
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.inside,
                        textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        useSeriesColor: false,
                      ),
                      dataLabelMapper: (_SFItem d, _) => '${d.x} ${_manWon(d.y)}',
                    ),
                  ],
                ),
                height: 320,
              ),
              SizedBox(height: 14),

              // ───────── Syncfusion 3) Pie
              _whiteCard(
                'Syncfusion • Pie (만원 라벨, 작은 조각은 바깥)',
                SfCircularChart(
                  tooltipBehavior: _sfTooltip,
                  // smartLabelMode: SmartLabelMode.shift, // 겹치면 자동 이동
                  legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
                  series: <PieSeries<_SFItem, String>>[
                    PieSeries<_SFItem, String>(
                      dataSource: sfData,
                      xValueMapper: (_SFItem d, _) => d.x,
                      yValueMapper: (_SFItem d, _) => d.y,
                      pointColorMapper: (_SFItem d, _) => d.color,
                      explode: true,
                      explodeIndex: 0,
                      startAngle: 90,
                      endAngle: 90,
                      dataLabelMapper: (_SFItem d, _) => '${d.x}\n${_manWon(d.y)}',
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside, // 항상 바깥
                        connectorLineSettings: ConnectorLineSettings(
                          type: ConnectorType.curve,
                          length: '10%',
                          width: 1.5,
                        ),
                        textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      onPointTap: (ChartPointDetails details) {
                        setState(() {
                          // 터치한 조각 explode
                          // (SfPie는 한 번에 하나씩만 터뜨리고 싶으면 selectionBehavior 사용 가능)
                        });
                      },
                    ),
                  ],
                ),
                height: 320,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── fl_chart 섹션(만원 라벨 + 작은 조각 외부라벨 + 배지 살짝 위로)
  List<PieChartSectionData> _sections({
    required List<double> values,
    required List<Color> colors,
    required List<String> labelsForBadge,
    required int touchedIndex,
    required bool donut,
    double outsideLabelThreshold = 0.08,
  }) {
    final safe = values.map((v) => v < 0 ? 0.0 : v).toList();
    final total = safe.fold<double>(0, (a, b) => a + b);
    final norm = total == 0 ? 1.0 : total;

    final out = <PieChartSectionData>[];
    for (var i = 0; i < safe.length; i++) {
      final ratio = safe[i] / norm;
      final isTouched = i == touchedIndex;
      final baseRadius = donut ? 50.0 : 100.0;
      final radius = isTouched ? baseRadius + 10 : baseRadius;
      final fontSize = isTouched ? (donut ? 14.0 : 18.0) : (donut ? 12.0 : 14.0);
      final isOutside = ratio < outsideLabelThreshold;

      out.add(
        PieChartSectionData(
          color: colors[i],
          value: ratio * 100.0,
          title: _manWon(safe[i]), // 만원 단위
          showTitle: true,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: isOutside ? Colors.black : Colors.white,
            shadows: isOutside ? [] : [Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 4, offset: Offset(1.5, 1.5))],
          ),
          titlePositionPercentageOffset: isOutside ? 1.22 : 0.6, // 작으면 바깥
          radius: radius,
          // 배지: 중심보다 살짝 바깥 + 위로 올림(금액 가리지 않게)
          badgeWidget: Transform.translate(
            offset: Offset(0, -6),
            child: _TextBadge(
              label: labelsForBadge[i],
              size: isTouched ? (donut ? 44.0 : 58.0) : (donut ? 36.0 : 44.0),
              background: badgeBg,
              borderColor: badgeBorder,
            ),
          ),
          badgePositionPercentageOffset: donut ? 1.25 : 1.15,
        ),
      );
    }
    return out;
  }

  // ───────── 흰색 카드
  Widget _whiteCard(String title, Widget child, {double height = 260}) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Divider(height: 1),
              SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 텍스트 배지(연하늘 컨테이너 느낌)
class _TextBadge extends StatelessWidget {
  _TextBadge({
    required this.label,
    required this.size,
    required this.background,
    required this.borderColor,
  });

  final String label;
  final double size;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Syncfusion용 간단 데이터 홀더
class _SFItem {
  _SFItem(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

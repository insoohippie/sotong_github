import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_spacing.dart';
import '../../../../model/setting/past_plan_snapshot.dart';
import '../../plan/plan_widgets/plan_celebration/sequential_chart_widget.dart';

/// 지난 플랜 상세: total_plan과 동일한 4개 카드(요약·감정·소비·일지) PageView
class PastPlanDetailPage extends StatefulWidget {
  const PastPlanDetailPage({super.key, required this.snapshot});

  final PastPlanSnapshot snapshot;

  @override
  State<PastPlanDetailPage> createState() => _PastPlanDetailPageState();
}

class _PastPlanDetailPageState extends State<PastPlanDetailPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _emotionPodiumStarted = false;
  bool _categoryPodiumStarted = false;

  // 감정 포디움 애니메이션 (2번 카드)
  late AnimationController _emotionBarThirdController;
  late AnimationController _emotionBarSecondController;
  late AnimationController _emotionBarFirstController;
  late AnimationController _emotionItemThirdController;
  late AnimationController _emotionItemSecondController;
  late AnimationController _emotionItemFirstController;
  late AnimationController _emotionListController;

  // 카테고리 포디움 애니메이션 (3번 카드)
  late AnimationController _categoryBarThirdController;
  late AnimationController _categoryBarSecondController;
  late AnimationController _categoryBarFirstController;
  late AnimationController _categoryItemThirdController;
  late AnimationController _categoryItemSecondController;
  late AnimationController _categoryItemFirstController;
  late AnimationController _categoryListController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    const barDuration = Duration(milliseconds: 600);
    const itemDuration = Duration(milliseconds: 500);
    const listDuration = Duration(milliseconds: 600);

    _emotionBarThirdController = AnimationController(
      duration: barDuration,
      vsync: this,
    );
    _emotionBarSecondController = AnimationController(
      duration: barDuration,
      vsync: this,
    );
    _emotionBarFirstController = AnimationController(
      duration: barDuration,
      vsync: this,
    );
    _emotionItemThirdController = AnimationController(
      duration: itemDuration,
      vsync: this,
    );
    _emotionItemSecondController = AnimationController(
      duration: itemDuration,
      vsync: this,
    );
    _emotionItemFirstController = AnimationController(
      duration: itemDuration,
      vsync: this,
    );
    _emotionListController = AnimationController(
      duration: listDuration,
      vsync: this,
    );

    _categoryBarThirdController = AnimationController(
      duration: barDuration,
      vsync: this,
    );
    _categoryBarSecondController = AnimationController(
      duration: barDuration,
      vsync: this,
    );
    _categoryBarFirstController = AnimationController(
      duration: barDuration,
      vsync: this,
    );
    _categoryItemThirdController = AnimationController(
      duration: itemDuration,
      vsync: this,
    );
    _categoryItemSecondController = AnimationController(
      duration: itemDuration,
      vsync: this,
    );
    _categoryItemFirstController = AnimationController(
      duration: itemDuration,
      vsync: this,
    );
    _categoryListController = AnimationController(
      duration: listDuration,
      vsync: this,
    );
  }

  void _startEmotionPodiumAnimation() {
    if (_emotionPodiumStarted || !mounted) return;
    _emotionPodiumStarted = true;
    _emotionBarThirdController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _emotionBarSecondController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _emotionBarFirstController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _emotionItemThirdController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _emotionItemSecondController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _emotionItemFirstController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) _emotionListController.forward();
    });
  }

  void _startCategoryPodiumAnimation() {
    if (_categoryPodiumStarted || !mounted) return;
    _categoryPodiumStarted = true;
    _categoryBarThirdController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _categoryBarSecondController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _categoryBarFirstController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _categoryItemThirdController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _categoryItemSecondController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _categoryItemFirstController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) _categoryListController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emotionBarThirdController.dispose();
    _emotionBarSecondController.dispose();
    _emotionBarFirstController.dispose();
    _emotionItemThirdController.dispose();
    _emotionItemSecondController.dispose();
    _emotionItemFirstController.dispose();
    _emotionListController.dispose();
    _categoryBarThirdController.dispose();
    _categoryBarSecondController.dispose();
    _categoryBarFirstController.dispose();
    _categoryItemThirdController.dispose();
    _categoryItemSecondController.dispose();
    _categoryItemFirstController.dispose();
    _categoryListController.dispose();
    super.dispose();
  }

  static Color _colorByPercent(int percent) {
    if (percent >= 70) return const Color(0xFF0062FF);
    if (percent >= 40) return const Color(0xFF6BCF7F);
    return const Color(0xFFFF8A8A);
  }

  BoxDecoration _getCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: theme.dividerColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            theme.brightness == Brightness.dark ? 0.2 : 0.08,
          ),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ],
    );
  }

  List<ChartData> _chartsFromSnapshot(PastPlanSnapshot s) {
    return [
      ChartData(
        title: '절제 달성률',
        progress: s.restraintProgress / 100.0,
        color: _colorByPercent(s.restraintProgress),
      ),
      ChartData(
        title: '평균 저축률',
        progress: s.savingProgress / 100.0,
        color: _colorByPercent(s.savingProgress),
      ),
      ChartData(
        title: '목표 달성률',
        progress: s.targetProgress / 100.0,
        color: _colorByPercent(s.targetProgress),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final nf = NumberFormat.decimalPattern('ko_KR');

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        title: const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                if (i == 1) _startEmotionPodiumAnimation();
                if (i == 2) _startCategoryPodiumAnimation();
              },
              children: [
                // 1번 카드: 플랜 요약 (차트 + 평균 페이스/저축)
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: _getCardDecoration(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SequentialChartWidget(
                              charts: _chartsFromSnapshot(snapshot),
                            ),
                            const SizedBox(height: 50),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '평균 페이스',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${snapshot.averagePace ?? '0'}% / 일',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '평균 하루 저축 금액',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${nf.format(snapshot.averageDailySaving ?? 0)}원',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 2번 카드: 감정 포디움
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: 16,
                  ),
                  child: _buildEmotionCard(snapshot),
                ),
                // 3번 카드: 소비 카테고리 포디움
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: 16,
                  ),
                  child: _buildCategoryCard(snapshot, nf),
                ),
                // 4번 카드: 최근 일지
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: 16,
                  ),
                  child: _buildDiariesCard(snapshot, nf),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 270),
            child: _buildPageIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isSelected = _currentPage == i;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 10 : 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        );
      }),
    );
  }

  Widget _buildEmotionCard(PastPlanSnapshot snapshot) {
    if (snapshot.emotionCounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _getCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '감정 기록',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '감정 기록이 없습니다',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = snapshot.emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '감정 기록',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (sorted.length >= 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAnimatedPodiumWithItem(
                  barController: _emotionBarSecondController,
                  itemController: _emotionItemSecondController,
                  title: _buildEmotionItem(sorted[1], 2, total),
                  height: 175 / 1.5,
                  width: 77,
                  backgroundColor: const Color(0xFFC0C0C0),
                  rank: 2,
                ),
                const SizedBox(width: 3),
                _buildAnimatedPodiumWithItem(
                  barController: _emotionBarFirstController,
                  itemController: _emotionItemFirstController,
                  title: _buildEmotionItem(sorted[0], 1, total),
                  height: 175,
                  width: 77,
                  backgroundColor: const Color(0xFFFFD700),
                  rank: 1,
                ),
                const SizedBox(width: 3),
                _buildAnimatedPodiumWithItem(
                  barController: _emotionBarThirdController,
                  itemController: _emotionItemThirdController,
                  title: _buildEmotionItem(sorted[2], 3, total),
                  height: 175 / 2.5,
                  width: 77,
                  backgroundColor: const Color(0xFFCD7F32),
                  rank: 3,
                ),
              ],
            ),
          if (sorted.length > 3) ...[
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _emotionListController,
              builder: (context, child) {
                return Opacity(
                  opacity: _emotionListController.value,
                  child: Column(
                    children: sorted.skip(3).toList().asMap().entries.map((
                        entry,
                        ) {
                      final index = entry.key + 4;
                      final e = entry.value;
                      final pct = total > 0
                          ? (e.value / total * 100).toStringAsFixed(1)
                          : '0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$index',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '${e.value}회 · ${pct}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmotionItem(MapEntry<String, int> e, int rank, int total) {
    final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_getEmotionEmoji(e.key), style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          e.key,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          '${e.value}회 · ${pct}%',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion) {
      case '좋음':
        return '😊';
      case '슬픔':
        return '😢';
      case '스트레스':
        return '😰';
      case '동기부여':
        return '💪';
      case '평온':
        return '😌';
      default:
        return '😊';
    }
  }

  Widget _buildCategoryCard(PastPlanSnapshot snapshot, NumberFormat nf) {
    if (snapshot.categorySpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _getCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '소비 기록',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '소비 기록이 없습니다',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = snapshot.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '소비 기록',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (sorted.length >= 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAnimatedPodiumWithItem(
                  barController: _categoryBarSecondController,
                  itemController: _categoryItemSecondController,
                  title: _buildCategoryItem(sorted[1], 2, nf),
                  height: 175 / 1.5,
                  width: 77,
                  backgroundColor: const Color(0xFFC0C0C0),
                  rank: 2,
                ),
                const SizedBox(width: 3),
                _buildAnimatedPodiumWithItem(
                  barController: _categoryBarFirstController,
                  itemController: _categoryItemFirstController,
                  title: _buildCategoryItem(sorted[0], 1, nf),
                  height: 175,
                  width: 77,
                  backgroundColor: const Color(0xFFFFD700),
                  rank: 1,
                ),
                const SizedBox(width: 3),
                _buildAnimatedPodiumWithItem(
                  barController: _categoryBarThirdController,
                  itemController: _categoryItemThirdController,
                  title: _buildCategoryItem(sorted[2], 3, nf),
                  height: 175 / 2.5,
                  width: 77,
                  backgroundColor: const Color(0xFFCD7F32),
                  rank: 3,
                ),
              ],
            ),
          if (sorted.length > 3) ...[
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _categoryListController,
              builder: (context, child) {
                return Opacity(
                  opacity: _categoryListController.value,
                  child: Column(
                    children: sorted.skip(3).toList().asMap().entries.map((
                        entry,
                        ) {
                      final index = entry.key + 4;
                      final e = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$index',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '${nf.format(e.value.round())}원',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedPodiumWithItem({
    required AnimationController barController,
    required AnimationController itemController,
    required Widget title,
    required double height,
    required double width,
    required Color backgroundColor,
    int? rank,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          child: Center(
            child: AnimatedBuilder(
              animation: itemController,
              builder: (context, child) {
                return Opacity(
                  opacity: itemController.value,
                  child: Transform.scale(
                    scale: 0.5 + (itemController.value * 0.5),
                    child: title,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: barController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - barController.value) * 200),
              child: Opacity(
                opacity: barController.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotatedBox(
                      quarterTurns: 2,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.02)
                          ..rotateX(3.14 / 10),
                        alignment: Alignment.center,
                        child: Container(
                          height: 10,
                          width: width - 3,
                          color: backgroundColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(color: backgroundColor),
                        ),
                        if (rank != null)
                          Text(
                            '$rank',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
      MapEntry<String, double> e,
      int rank,
      NumberFormat nf,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          e.key,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${nf.format(e.value.round())}원',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDiariesCard(PastPlanSnapshot snapshot, NumberFormat nf) {
    if (snapshot.diaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _getCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 일지',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '일지가 없습니다',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = List<Map<String, dynamic>>.from(snapshot.diaries)
      ..sort((a, b) {
        final da = DateTime.tryParse(a['date'] as String? ?? '');
        final db = DateTime.tryParse(b['date'] as String? ?? '');
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 일지',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.take(20).map((d) {
            final dateStr = d['date'] as String? ?? '';
            final date = DateTime.tryParse(dateStr);
            final displayDate = date != null
                ? DateFormat('MM.dd').format(date)
                : dateStr;
            final amount = (d['totalAmount'] as num?)?.toInt();
            final emotion = d['emotion'] as String? ?? '';
            final comment = d['comment'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (emotion.isNotEmpty)
                          Text(
                            emotion,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        if (comment.isNotEmpty) ...[
                          if (emotion.isNotEmpty) const SizedBox(height: 4),
                          Text(
                            comment,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (amount != null && amount > 0)
                    Text(
                      '${nf.format(amount)}원',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

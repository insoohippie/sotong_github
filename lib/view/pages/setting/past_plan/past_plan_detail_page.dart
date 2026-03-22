import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../component/appbars/back_only_app_bar.dart';
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

  // 달력 상태 (4번 카드)
  late int _selectedYear;
  late int _selectedMonth;

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
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final ref = widget.snapshot.endDate ?? widget.snapshot.completedAt;
    _selectedYear = ref.year;
    _selectedMonth = ref.month;

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

  /// 포디움 애니메이션(~2.3초)에 맞춰 쫘라락 햅틱 (12회, 150ms 간격)
  void _playPodiumSequentialHaptic() {
    _hapticTimer?.cancel();
    HapticFeedback.selectionClick();
    int count = 1;
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted || count >= 12) {
        _hapticTimer?.cancel();
        _hapticTimer = null;
        return;
      }
      HapticFeedback.selectionClick();
      count++;
    });
  }

  void _startEmotionPodiumAnimation() {
    if (_emotionPodiumStarted || !mounted) return;
    _emotionPodiumStarted = true;
    _playPodiumSequentialHaptic();
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
    _playPodiumSequentialHaptic();
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
    _hapticTimer?.cancel();
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
      appBar: const BackOnlyAppBar(),
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
                // 4번 카드: 최근 일지 (달력 형태 — totalplan과 동일)
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: 16,
                  ),
                  child: _buildDiaryCalendarCard(snapshot, nf),
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
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Lottie.asset(
                                _lottiePathForEmotion(e.key),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Text(
                                  _getEmotionEmoji(e.key),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
        SizedBox(
          width: 48,
          height: 48,
          child: Lottie.asset(
            _lottiePathForEmotion(e.key),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              _getEmotionEmoji(e.key),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
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

  String _lottiePathForEmotion(String emotion) {
    switch (emotion) {
      case '평온':
        return 'assets/animations/emotion_calm.json';
      case '좋음':
        return 'assets/animations/emotion_good.json';
      case '슬픔':
        return 'assets/animations/emotion_sad.json';
      case '스트레스':
        return 'assets/animations/emotion_stress.json';
      case '동기부여':
        return 'assets/animations/emotion_motivation.json';
      case '아무 감정 없음':
        return 'assets/animations/emotion_none.json';
      default:
        return 'assets/animations/emotion_calm.json';
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

  /// snapshot.diaries에서 (year, month, day) -> diary 맵 생성
  Map<String, Map<String, dynamic>> _diaryMapFor(PastPlanSnapshot snapshot) {
    final map = <String, Map<String, dynamic>>{};
    for (final d in snapshot.diaries) {
      final dateStr = d['date'] as String? ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        final key = '${date.year}-${date.month}-${date.day}';
        map[key] = d;
      }
    }
    return map;
  }

  /// 4번 카드: 달력 형태 (totalplan과 동일)
  Widget _buildDiaryCalendarCard(PastPlanSnapshot snapshot, NumberFormat nf) {
    final theme = Theme.of(context);
    final diaryMap = _diaryMapFor(snapshot);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(context),
      child: _buildDiaryCalendar(diaryMap, nf, theme),
    );
  }

  Widget _buildDiaryCalendar(
      Map<String, Map<String, dynamic>> diaryMap,
      NumberFormat nf,
      ThemeData theme,
      ) {
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 월 선택
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedMonth == 1) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_selectedYear년 $_selectedMonth월',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedMonth == 12) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 달력 그리드
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: ['일', '월', '화', '수', '목', '금', '토']
                      .map(
                        (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: day == '일'
                              ? Colors.red
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const ratio = 1.15;
                    return SizedBox(
                      height: (constraints.maxWidth / 7 / ratio) * 6,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: ratio,
                        ),
                        itemCount: 42,
                        itemBuilder: (context, index) {
                          final day = index - firstWeekday + 1;
                          final isCurrentMonth = day > 0 && day <= daysInMonth;

                          if (!isCurrentMonth) return const SizedBox();

                          final key = '$_selectedYear-$_selectedMonth-$day';
                          final diary = diaryMap[key];
                          final hasEmotion =
                              diary != null &&
                                  (diary['emotion'] as String? ?? '').isNotEmpty;
                          final emoji = hasEmotion
                              ? _getEmotionEmoji(
                            diary['emotion'] as String? ?? '',
                          )
                              : '';

                          return GestureDetector(
                            onTap: () {
                              if (diary != null) {
                                _showPastPlanDiaryModal(context, diary, nf);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (hasEmotion && emoji.isNotEmpty)
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Lottie.asset(
                                        _lottiePathForEmotion(
                                          diary['emotion'] as String? ?? '',
                                        ),
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Text(
                                          emoji,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (!hasEmotion || emoji.isEmpty)
                                    Text(
                                      '$day',
                                      textAlign: TextAlign.center,
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
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPastPlanDiaryModal(
      BuildContext context,
      Map<String, dynamic> diary,
      NumberFormat nf,
      ) {
    final theme = Theme.of(context);
    final dateStr = diary['date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr);
    final displayDate = date != null
        ? DateFormat('yyyy.MM.dd').format(date)
        : dateStr;
    final amount = (diary['totalAmount'] as num?)?.toInt();
    final emotion = diary['emotion'] as String? ?? '';
    final comment = diary['comment'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                displayDate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (emotion.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _getEmotionEmoji(emotion),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      emotion,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (amount != null && amount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${nf.format(amount)}원',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

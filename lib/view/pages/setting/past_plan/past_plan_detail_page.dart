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

class _PastPlanDetailPageState extends State<PastPlanDetailPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static Color _colorByPercent(int percent) {
    if (percent >= 70) return const Color(0xFF0062FF);
    if (percent >= 40) return const Color(0xFF6BCF7F);
    return const Color(0xFFFF8A8A);
  }

  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          snapshot.planName.isEmpty ? '플랜' : snapshot.planName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                // 1번 카드: 플랜 요약 (차트 + 평균 페이스/저축)
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _getCardDecoration(),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '평균 페이스',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.subText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${snapshot.averagePace ?? '0'}% / 일',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '평균 하루 저축 금액',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.subText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${nf.format(snapshot.averageDailySaving ?? 0)}원',
                                    style: const TextStyle(
                                      fontSize: 16,
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
          // 페이지 인디케이터
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == i
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionCard(PastPlanSnapshot snapshot) {
    if (snapshot.emotionCounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _getCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '감정 기록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '감정 기록이 없습니다',
                style: TextStyle(fontSize: 14, color: AppColors.subText),
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
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '감정 기록',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          if (sorted.length >= 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStaticPodiumColumn(
                  height: 175 / 1.5,
                  color: const Color(0xFFC0C0C0),
                  rank: 2,
                  child: _buildEmotionItem(sorted[1], 2, total),
                ),
                const SizedBox(width: 3),
                _buildStaticPodiumColumn(
                  height: 175,
                  color: const Color(0xFFFFD700),
                  rank: 1,
                  child: _buildEmotionItem(sorted[0], 1, total),
                ),
                const SizedBox(width: 3),
                _buildStaticPodiumColumn(
                  height: 175 / 2.5,
                  color: const Color(0xFFCD7F32),
                  rank: 3,
                  child: _buildEmotionItem(sorted[2], 3, total),
                ),
              ],
            ),
          if (sorted.length > 3) ...[
            const SizedBox(height: 24),
            ...sorted.skip(3).toList().asMap().entries.map((entry) {
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.subText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Text(
                      '${e.value}회 · ${pct}%',
                      style: TextStyle(fontSize: 12, color: AppColors.subText),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStaticPodiumColumn({
    required double height,
    required Color color,
    required int rank,
    required Widget child,
  }) {
    const width = 77.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 8),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionItem(MapEntry<String, int> e, int rank, int total) {
    final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_getEmotionEmoji(e.key), style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          e.key,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        Text(
          '${e.value}회 · ${pct}%',
          style: TextStyle(fontSize: 12, color: AppColors.subText),
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
        decoration: _getCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '소비 기록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '소비 기록이 없습니다',
                style: TextStyle(fontSize: 14, color: AppColors.subText),
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
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '소비 기록',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          if (sorted.length >= 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStaticPodiumColumn(
                  height: 175 / 1.5,
                  color: const Color(0xFFC0C0C0),
                  rank: 2,
                  child: _buildCategoryItem(sorted[1], 2, nf),
                ),
                const SizedBox(width: 3),
                _buildStaticPodiumColumn(
                  height: 175,
                  color: const Color(0xFFFFD700),
                  rank: 1,
                  child: _buildCategoryItem(sorted[0], 1, nf),
                ),
                const SizedBox(width: 3),
                _buildStaticPodiumColumn(
                  height: 175 / 2.5,
                  color: const Color(0xFFCD7F32),
                  rank: 3,
                  child: _buildCategoryItem(sorted[2], 3, nf),
                ),
              ],
            ),
          if (sorted.length > 3) ...[
            const SizedBox(height: 24),
            ...sorted.skip(3).toList().asMap().entries.map((entry) {
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.subText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Text(
                      '${nf.format(e.value.round())}원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${nf.format(e.value.round())}원',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildDiariesCard(PastPlanSnapshot snapshot, NumberFormat nf) {
    if (snapshot.diaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _getCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '최근 일지',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '일지가 없습니다',
                style: TextStyle(fontSize: 14, color: AppColors.subText),
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
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 일지',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
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
                      color: AppColors.subText,
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        if (comment.isNotEmpty) ...[
                          if (emotion.isNotEmpty) const SizedBox(height: 4),
                          Text(
                            comment,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.subText,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
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

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:sotong_local/component/theme/app_colors.dart';
import '../../../../component/buttons/period_toggle.dart'; // TwoOptionToggle 사용
import '../../../../view_model/communication/communication_view_model.dart';

class EmotionTop3CarouselSection extends StatefulWidget {
  const EmotionTop3CarouselSection({super.key, required this.vm});
  final CommunicationViewModel vm;

  @override
  State<EmotionTop3CarouselSection> createState() => _EmotionTop3CarouselSectionState();
}

class _EmotionTop3CarouselSectionState extends State<EmotionTop3CarouselSection> {
  final CarouselSliderController _carouselCtrl = CarouselSliderController();

  int _page = 0;

  String _format(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  String _periodLabel(String period) => period == '주간' ? '최근 7일' : '최근 30일';

  @override
  void didUpdateWidget(covariant EmotionTop3CarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm.selectedAnalysisPeriod != widget.vm.selectedAnalysisPeriod) {
      setState(() => _page = 0);
      _carouselCtrl.animateToPage(
        0,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final period = vm.selectedAnalysisPeriod;

    final top3 = vm.emotionTop3Stats(period).map((e) {
      return _RankData(
        emotion: e['emotion'] as String,
        emoji: e['emoji'] as String,
        count: e['count'] as int,
        total: e['total'] as int,
        avg: e['avg'] as int,
      );
    }).toList();

    final slides = <_SlideSpec>[
      _SlideSpec(
        keyId: 'count',
        title: '${_periodLabel(period)} 감정 기록',
        valueBuilder: (d) => '${d.count}일',
        subBuilder: (d) => d.emotion,
      ),
      _SlideSpec(
        keyId: 'total',
        title: '${_periodLabel(period)} 총 지출',
        valueBuilder: (d) => '${_format(d.total)}원',
        subBuilder: (d) => d.emotion,
      ),
      _SlideSpec(
        keyId: 'avg',
        title: '${_periodLabel(period)} 일일 평균 소비',
        valueBuilder: (d) => '${_format(d.avg)}원',
        subBuilder: (d) => d.emotion,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // ── 상단: 타이틀 + 토글 ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '감정별 소비',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                TwoOptionToggle(
                  labels: const ['주간', '월간'],
                  selected: period,
                  onChanged: (v) {
                    if (v == vm.selectedAnalysisPeriod) return;
                    vm.setAnalysisPeriod(v);
                    // notifyListeners는 VM에서
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 본문: 캐러셀 ───────────────────────
          if (top3.isEmpty)
            _EmptyState(periodLabel: _periodLabel(period))
          else
            Column(
              children: [
                CarouselSlider(
                  carouselController: _carouselCtrl,
                  options: CarouselOptions(
                    height: 178,
                    viewportFraction: 1,
                    enableInfiniteScroll: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    autoPlayAnimationDuration: const Duration(milliseconds: 850),
                    autoPlayCurve: Curves.easeInOutCubic,
                    onPageChanged: (index, reason) {
                      if (!mounted) return;
                      setState(() => _page = index);
                    },
                  ),
                  items: slides.map((spec) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _Top3Slide(
                        key: ValueKey('${period}_${spec.keyId}'),
                        title: spec.title,
                        top3: top3,
                        valueBuilder: spec.valueBuilder,
                        subBuilder: spec.subBuilder,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),

                // ── 점 인디케이터 ───────────────────
                AnimatedSmoothIndicator(
                  activeIndex: _page % slides.length,
                  count: slides.length,
                  effect: WormEffect(
                    dotHeight: 7,
                    dotWidth: 7,
                    spacing: 8,
                    dotColor: Colors.grey[300]!,
                    activeDotColor: Colors.grey[800]!,
                  ),
                  onDotClicked: (i) {
                    _carouselCtrl.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/* ───────────────── Models ───────────────── */

class _RankData {
  final String emotion;
  final String emoji;
  final int count;
  final int total;
  final int avg;

  _RankData({
    required this.emotion,
    required this.emoji,
    required this.count,
    required this.total,
    required this.avg,
  });
}

class _SlideSpec {
  final String keyId;
  final String title;
  final String Function(_RankData) valueBuilder;
  final String Function(_RankData) subBuilder;

  _SlideSpec({
    required this.keyId,
    required this.title,
    required this.valueBuilder,
    required this.subBuilder,
  });
}

/* ───────────────── Slide ───────────────── */

class _Top3Slide extends StatelessWidget {
  const _Top3Slide({
    super.key,
    required this.title,
    required this.top3,
    required this.valueBuilder,
    required this.subBuilder,
  });

  final String title;
  final List<_RankData> top3;
  final String Function(_RankData) valueBuilder;
  final String Function(_RankData) subBuilder;

  @override
  Widget build(BuildContext context) {
    // ✅ 오버플로우 방지: 3개 고정이지만 혹시 2개만 있으면 안전하게
    final safeTop3 = top3.length >= 3 ? top3.sublist(0, 3) : top3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(safeTop3.length, (i) {
            final d = safeTop3[i];
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == safeTop3.length - 1 ? 0 : 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 순위
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ✅ 이모지 크게
                    Text(
                      d.emoji,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ✅ 강조 값(오버플로우 방지)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        valueBuilder(d),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 감정 라벨(오버플로우 방지)
                    Text(
                      subBuilder(d),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.subText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/* ───────────────── Empty ───────────────── */

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.periodLabel});
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: Center(child: Text('🙂', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$periodLabel 기준으로 감정 기록이 없어요.\n오늘의 소비를 기록해보세요!',
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

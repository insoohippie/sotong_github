import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../component/buttons/period_toggle.dart'; // TwoOptionToggle 사용
import '../../../../view_model/communication/communication_view_model.dart';

class EmotionTop3CarouselSection extends StatefulWidget {
  const EmotionTop3CarouselSection({super.key, required this.vm});
  final CommunicationViewModel vm;

  @override
  State<EmotionTop3CarouselSection> createState() =>
      _EmotionTop3CarouselSectionState();
}

class _EmotionTop3CarouselSectionState
    extends State<EmotionTop3CarouselSection> {
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
    if (oldWidget.vm.selectedAnalysisPeriod !=
        widget.vm.selectedAnalysisPeriod) {
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

    final theme = Theme.of(context);
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // ── 상단: 타이틀 + 토글 ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '감정별 소비',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TwoOptionToggle(
                  labels: const ['주간', '월간'],
                  selected: period,
                  width: toggleWidth,
                  height: toggleHeight,
                  fontSize: toggleFontSize,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EmptyState(periodLabel: _periodLabel(period)),
            )
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
                    autoPlayAnimationDuration: const Duration(
                      milliseconds: 850,
                    ),
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
                    dotColor: theme.colorScheme.onSurfaceVariant.withOpacity(
                      0.4,
                    ),
                    activeDotColor: theme.colorScheme.primary,
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

/// VM emotionList(기쁨, 혼란 등) + record_diary(평온, 좋음 등) 모두 Lottie 경로로 매핑
String _lottiePathForEmotionLabel(String emotion) {
  switch (emotion) {
    case '평온':
    case '피곤':
      return 'assets/animations/emotion_calm.json';
    case '좋음':
    case '기쁨':
    case '플렉스':
      return 'assets/animations/emotion_good.json';
    case '슬픔':
      return 'assets/animations/emotion_sad.json';
    case '스트레스':
    case '화남':
      return 'assets/animations/emotion_stress.json';
    case '동기부여':
      return 'assets/animations/emotion_motivation.json';
    case '아무 감정 없음':
    case '혼란':
      return 'assets/animations/emotion_none.json';
    default:
      return 'assets/animations/emotion_calm.json';
  }
}

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade50;
    final cardBorder = isDark ? theme.dividerColor : Colors.grey[200]!;
    final safeTop3 = top3.length >= 3 ? top3.sublist(0, 3) : top3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(safeTop3.length, (i) {
            final d = safeTop3[i];
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: i == safeTop3.length - 1 ? 0 : 10,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),

                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Lottie.asset(
                        _lottiePathForEmotionLabel(d.emotion),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              d.emoji,
                              style: const TextStyle(fontSize: 26, height: 1.0),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        valueBuilder(d),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      subBuilder(d),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade50;
    final cardBorder = isDark ? theme.dividerColor : Colors.grey[200]!;
    final viewWidth = MediaQuery.sizeOf(context).width;
    final bodyFontSize = viewWidth <= 386
        ? 11.0
        : viewWidth < 412
            ? 12.0
            : 13.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Lottie.asset(
              'assets/animations/emotion_good.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('🙂', style: TextStyle(fontSize: 24)),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$periodLabel 기준으로 감정 기록이 없어요.\n오늘의 소비를 기록해보세요!',
              style: TextStyle(
                fontSize: bodyFontSize,
                height: 1.3,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

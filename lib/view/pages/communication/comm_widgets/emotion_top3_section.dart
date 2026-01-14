import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import '../../../../component/buttons/period_toggle.dart';
import '../../../../view_model/communication/communication_view_model.dart';

class EmotionTop3Section extends StatefulWidget {
  const EmotionTop3Section({super.key, required this.vm});
  final CommunicationViewModel vm;

  @override
  State<EmotionTop3Section> createState() => _EmotionTop3SectionState();
}

class _EmotionTop3SectionState extends State<EmotionTop3Section> {
  Timer? _ticker;
  int _insightIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _insightIndex++);
    });
  }

  String _format(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  String _insightLine(_RankData d, String period) {
    final p = period == '주간' ? '최근 7일' : '최근 30일';
    return '$p동안 감정 상태가 ${d.emotion}일 때 총 ${_format(d.total)}원을 사용했어요!';
  }

  void _onPeriodChanged(CommunicationViewModel vm, String next) {
    if (vm.selectedAnalysisPeriod == next) return;
    vm.setAnalysisPeriod(next);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final period = vm.selectedAnalysisPeriod;

    // ✅ period 고정 방향
    // 주간: 왼쪽에서 들어옴 / 월간: 오른쪽에서 들어옴
    final inBeginX = (period == '주간') ? -0.18 : 0.18;

    final shown = vm.emotionTop3Stats(period).map((e) {
      return _RankData(
        emotion: e['emotion'],
        emoji: e['emoji'],
        count: e['count'],
        total: e['total'],
        avg: e['avg'],
      );
    }).toList();

    final hasInsight = shown.isNotEmpty;
    final rotating = hasInsight ? shown[_insightIndex % shown.length] : null;

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 타이틀 + 토글
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '감정별 소비',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TwoOptionToggle(
                  labels: const ['주간', '월간'],
                  selected: vm.selectedAnalysisPeriod,
                  onChanged: (v) => _onPeriodChanged(vm, v),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ✅ 들어오는 것만 애니메이션 (나가는 잔상 X)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.linear,
              layoutBuilder: (currentChild, previousChildren) {
                // ✅ previousChildren 렌더링 안 함 = 잔상/겹침 제거
                return currentChild ?? const SizedBox.shrink();
              },
              transitionBuilder: (child, anim) {
                return ClipRect(
                  child: FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(inBeginX, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                );
              },
              child: shown.isEmpty
                  ? const _EmptyState(key: ValueKey('content-empty'))
                  : Column(
                key: ValueKey('content-$period'), // ✅ period 바뀌면 전환
                children: [
                  for (int i = 0; i < shown.length; i++) ...[
                    _RankRow(
                      rank: i + 1,
                      data: shown[i],
                      format: _format,
                    ),
                    if (i != shown.length - 1)
                      Divider(height: 18, color: Colors.grey[200]),
                  ],
                ],
              ),
            ),

            // ✅ 설명 텍스트: 애니메이션 제거 (그냥 바뀜)
            if (hasInsight && rotating != null) ...[
              const SizedBox(height: 14),
              Container(
                key: ValueKey(
                  'insight-$period-${_insightIndex % shown.length}-${rotating.emotion}-${rotating.total}',
                ),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  _insightLine(rotating, period),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
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

/* ───────────────── Rank Row ───────────────── */

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.data,
    required this.format,
  });

  final int rank;
  final _RankData data;
  final String Function(int) format;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ✅ 1) 순위만 고정
        SizedBox(
          width: 22,
          child: Text(
            '$rank',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ✅ 2) 순위 오른쪽 "전체"를 슬라이드
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.linear, // ✅ 나가는 건 그냥 사라지게(겹침 최소화)
            transitionBuilder: (child, anim) {
              final inAnim = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);

              // ✅ 들어오는 것만 슬라이드
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.25, 0), // 기본: 오른쪽에서 들어옴
                    end: Offset.zero,
                  ).animate(inAnim),
                  child: FadeTransition(opacity: inAnim, child: child),
                ),
              );
            },
            // ✅ period 바뀌면 data가 바뀌니까, 값 기반 key로 새 child로 인식시켜야 함
            child: Row(
              key: ValueKey('${data.emotion}-${data.count}-${data.total}-${data.avg}'),
              children: [
                // (기존 왼쪽 감정 영역)
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.greyBackground.withOpacity(0.9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          data.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.emotion,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${data.count}일 기록',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.subText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // (기존 오른쪽 금액 영역)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${format(data.total)}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '평균 ${format(data.avg)}원/일',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* ───────────────── Empty State ───────────────── */

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

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
              '아직 감정 기록이 없어요.\n오늘의 소비를 기록해보세요!',
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

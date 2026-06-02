import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../../component/buttons/period_toggle.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../view_model/communication/communication_view_model.dart';
import 'date_detail_modal.dart';

class EmotionCalendarSection extends StatefulWidget {
  const EmotionCalendarSection({super.key, required this.vm});

  final CommunicationViewModel vm;

  @override
  State<EmotionCalendarSection> createState() => _EmotionCalendarSectionState();
}

class _EmotionCalendarSectionState extends State<EmotionCalendarSection>
    with SingleTickerProviderStateMixin {
  // 감정 / 금액 모드
  String selectedMode = '감정'; // '감정' | '금액'

  // 달 넘어갈 때 슬라이드 방향 (위/아래)
  int _monthSlideDirection = 0;
  // 감정↔금액 토글 시 슬라이드 방향 (1: 감정→금액=오른쪽에서 들어옴, -1: 금액→감정=왼쪽에서 들어옴)
  int _modeSlideDirection = 0;

  void _changeMode(String mode) {
    if (mode == selectedMode) return;
    _modeSlideDirection = (mode == '금액') ? 1 : -1;
    setState(() => selectedMode = mode);
  }

  String _formatWonShort(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}만';
    return '$v';
  }

  String _formatWonFull(int v) {
    return v.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
  }

  // ───────────────── 공휴일/주말 색상 ─────────────────

  static const Set<String> _holidayYmd = {
    // 2026 (대한민국 공휴일 + 대체공휴일 + 지방선거일)
    '2026-01-01', // 신정
    '2026-02-16', // 설 연휴
    '2026-02-17', // 설
    '2026-02-18', // 설 연휴
    '2026-03-01', // 삼일절
    '2026-03-02', // 삼일절 대체공휴일
    '2026-05-05', // 어린이날
    '2026-05-24', // 부처님오신날
    '2026-05-25', // 부처님오신날 대체공휴일
    '2026-06-03', // 지방선거일
    '2026-06-06', // 현충일
    '2026-08-15', // 광복절
    '2026-08-17', // 광복절 대체공휴일
    '2026-09-24', // 추석 연휴
    '2026-09-25', // 추석
    '2026-09-26', // 추석 연휴
    '2026-10-03', // 개천절
    '2026-10-05', // 개천절 대체공휴일
    '2026-10-09', // 한글날
    '2026-12-25', // 성탄절
  };

  String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  bool _isHoliday(DateTime d) => _holidayYmd.contains(_ymd(d));

  Color _weekdayHeaderColor(BuildContext context, String day) {
    if (day == '일') return Colors.red;
    if (day == '토') return Colors.blue;
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _dayNumberColor(BuildContext context, DateTime date) {
    // 공휴일은 빨강
    if (_isHoliday(date)) return Colors.red;

    // 주말: 토=파랑, 일=빨강
    if (date.weekday == DateTime.sunday) return Colors.red;
    if (date.weekday == DateTime.saturday) return Colors.blue;

    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              Text(
                '${vm.selectedYear}년',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              _buildModeToggle(),
            ],
          ),
          const SizedBox(height: 14),
          _buildCalendarWithModeDials(vm),
        ],
      ),
    );
  }

  // ───────────────── 월 선택 다이얼 ─────────────────

  Widget _buildMonthSelector(CommunicationViewModel vm) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이전 달
          GestureDetector(
            onTap: () {
              setState(() {
                _monthSlideDirection = -1;
              });
              vm.changeMonth(-1);
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
            '${vm.selectedMonth}월',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          // 다음 달
          GestureDetector(
            onTap: () {
              setState(() {
                _monthSlideDirection = 1;
              });
              vm.changeMonth(1);
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
    );
  }

  // ──────────────── 달력 + 모드 다이얼 ────────────────

  Widget _buildCalendarWithModeDials(CommunicationViewModel vm) {
    final theme = Theme.of(context);
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
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildMonthSelector(vm),
          ),
          _buildCalendar(vm),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
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
      labels: const ['감정', '금액'],
      selected: selectedMode,
      onChanged: (v) => _changeMode(v),
      width: toggleWidth,
      height: toggleHeight,
      fontSize: toggleFontSize,
    );
  }

  // ───────────────── 달력 본체 ─────────────────

  Widget _buildCalendar(CommunicationViewModel vm) {
    final firstDayOfMonth = DateTime(vm.selectedYear, vm.selectedMonth, 1);
    final lastDayOfMonth = DateTime(vm.selectedYear, vm.selectedMonth + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // ✅ 월요일 시작 offset: 월(1)->0, 화(2)->1, ... 일(7)->6
    final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final key = child.key;
          final isIncoming =
              key is ValueKey<int> && key.value == vm.selectedMonth;

          final incomingOffset = _monthSlideDirection == 1
              ? const Offset(0, 1)
              : _monthSlideDirection == -1
              ? const Offset(0, -1)
              : Offset.zero;
          final outgoingOffset = _monthSlideDirection == 1
              ? const Offset(0, -1)
              : _monthSlideDirection == -1
              ? const Offset(0, 1)
              : Offset.zero;

          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          final Animation<Offset> slideAnimation = isIncoming
              ? Tween<Offset>(
            begin: incomingOffset,
            end: Offset.zero,
          ).animate(curved)
              : Tween<Offset>(
            begin: Offset.zero,
            end: outgoingOffset,
          ).animate(ReverseAnimation(curved));

          return ClipRect(
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        child: Column(
          key: ValueKey<int>(vm.selectedMonth),
          children: [
            Row(
              children: ['월', '화', '수', '목', '금', '토', '일']
                  .map(
                    (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _weekdayHeaderColor(context, day),
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                // 감정→금액: 새 컨텐츠가 오른쪽에서 들어옴. 금액→감정: 왼쪽에서 들어옴
                final incomingOffset = _modeSlideDirection == 1
                    ? const Offset(1, 0)
                    : _modeSlideDirection == -1
                    ? const Offset(-1, 0)
                    : Offset.zero;
                final outgoingOffset = _modeSlideDirection == 1
                    ? const Offset(-1, 0)
                    : _modeSlideDirection == -1
                    ? const Offset(1, 0)
                    : Offset.zero;

                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                );

                // 새 모드(selectedMode) 쪽이 incoming, 이전 모드가 outgoing
                final isIncoming = child.key == ValueKey<String>(selectedMode);
                final slideAnim = isIncoming
                    ? Tween<Offset>(
                  begin: incomingOffset,
                  end: Offset.zero,
                ).animate(curved)
                    : Tween<Offset>(
                  begin: Offset.zero,
                  end: outgoingOffset,
                ).animate(
                  CurvedAnimation(
                    parent: ReverseAnimation(animation),
                    curve: Curves.easeInOutCubic,
                  ),
                );

                return ClipRect(
                  child: SlideTransition(position: slideAnim, child: child),
                );
              },
              child: LayoutBuilder(
                key: ValueKey<String>(selectedMode),
                builder: (context, constraints) {
                  // 7칸 기준 한 칸의 "가로" 길이
                  final cellW = constraints.maxWidth / 7;

                  // childAspectRatio = width / height  -> 값이 커질수록 높이가 줄어듦
                  const ratio = 1.15;

                  // 6주(42칸) 고정이므로 그리드 전체 높이
                  final gridH = (cellW / ratio) * 6;

                  return SizedBox(
                    height: gridH,
                    child: _buildCalendarGrid(
                      vm: vm,
                      firstWeekdayOffset: firstWeekdayOffset,
                      daysInMonth: daysInMonth,
                      showEmotion: selectedMode == '감정',
                      childAspectRatio: ratio,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid({
    required CommunicationViewModel vm,
    required int firstWeekdayOffset,
    required int daysInMonth,
    required bool showEmotion,
    required double childAspectRatio,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = index - firstWeekdayOffset + 1;
        final isCurrentMonth = day > 0 && day <= daysInMonth;

        if (!isCurrentMonth) return const SizedBox();

        final date = DateTime(vm.selectedYear, vm.selectedMonth, day);
        final dayTextColor = _dayNumberColor(context, date);

        final hasEmotion = vm.hasEmotionRecord(day);
        final hasAmount = vm.spendingAmountForDay(day) > 0;
        final amount = vm.spendingAmountForDay(day);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            showDateDetailModal(context: context, vm: vm, day: day);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final bool isOverLimit =
                    vm.dailySpendingLimit > 0 && amount > vm.dailySpendingLimit;

                final showDayText =
                (!showEmotion || (showEmotion && !hasEmotion));

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 금액 모드
                    if (!showEmotion && hasAmount)
                      AmountUnderlineCell(day: day, isOverLimit: isOverLimit),

                    // 감정 모드: Lottie (감정별 JSON)
                    if (showEmotion && hasEmotion)
                      _LottieEmotionForDay(
                        emotionLabel: vm.emotionLabelForDay(day),
                        size: 28,
                      ),

                    // 날짜 텍스트 (토/일/공휴일 색)
                    if (showDayText)
                      Text(
                        '$day',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dayTextColor,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LottieEmotionForDay extends StatelessWidget {
  const _LottieEmotionForDay({required this.emotionLabel, this.size = 28});

  final String emotionLabel;
  final double size;

  static String _path(String emotion) {
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

  @override
  Widget build(BuildContext context) {
    final path = _path(emotionLabel.trim().isEmpty ? '평온' : emotionLabel);
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              '🙂',
              style: TextStyle(fontSize: size * 0.7, height: 1.0),
            ),
          );
        },
      ),
    );
  }
}

class _AmountCircle extends StatelessWidget {
  const _AmountCircle({required this.size, required this.isOverLimit});

  final double size;
  final bool isOverLimit;

  @override
  Widget build(BuildContext context) {
    final base = isOverLimit ? AppColors.redText : AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: base.withOpacity(0.5),
      ),
    );
  }
}

class AmountUnderlineCell extends StatelessWidget {
  const AmountUnderlineCell({
    super.key,
    required this.day,
    required this.isOverLimit,
  });

  final int day;
  final bool isOverLimit;

  @override
  Widget build(BuildContext context) {
    final base = isOverLimit ? AppColors.redText : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color: base.withOpacity(0.5),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class MoneyIconCell extends StatelessWidget {
  const MoneyIconCell({
    super.key,
    required this.amount,
    required this.limit,
    required this.size,
  });

  final int amount;
  final double limit;
  final double size;

  int _level() {
    if (limit <= 0) {
      // limit 없으면 절대값 기반
      if (amount >= 50000) return 4;
      if (amount >= 30000) return 3;
      if (amount >= 10000) return 2;
      return 1;
    }
    final r = amount / limit;
    if (r >= 1.0) return 4;
    if (r >= 0.66) return 3;
    if (r >= 0.33) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level();
    final path = 'assets/images/money$level.png';

    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  }
}

class OutlineCircleCell extends StatelessWidget {
  const OutlineCircleCell({
    super.key,
    required this.day,
    required this.size,
    required this.isOverLimit,
  });

  final int day;
  final double size;
  final bool isOverLimit;

  @override
  Widget build(BuildContext context) {
    final base = isOverLimit ? AppColors.redText : AppColors.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: base.withOpacity(0.8), width: 2),
          ),
        ),
        Text(
          '$day',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

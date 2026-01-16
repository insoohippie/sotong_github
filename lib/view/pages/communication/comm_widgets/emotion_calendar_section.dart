import 'package:flutter/material.dart';

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
  late final PageController _modePageController;

  // 달 넘어갈 때 슬라이드 방향
  int _monthSlideDirection = 0;

  @override
  void initState() {
    super.initState();
    _modePageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _modePageController.dispose();
    super.dispose();
  }

  void _changeMode(String mode) {
    if (mode == selectedMode) return;
    setState(() {
      selectedMode = mode;
    });
    final targetIndex = mode == '감정' ? 0 : 1;
    _modePageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${vm.selectedYear}년',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _buildModeToggle(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildCalendarWithModeDials(vm),
        ],
      ),
    );
  }

  // ───────────────── 월 선택 다이얼 ─────────────────

  Widget _buildMonthSelector(CommunicationViewModel vm) {
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
                color: Colors.grey[700],
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${vm.selectedMonth}월',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
                color: Colors.grey[700],
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
    return TwoOptionToggle(
      labels: const ['감정', '금액'],
      selected: selectedMode,
      onChanged: (v) => _changeMode(v),
    );
  }

  // ───────────────── 달력 본체 ─────────────────

  Widget _buildCalendar(CommunicationViewModel vm) {
    final firstDayOfMonth =
    DateTime(vm.selectedYear, vm.selectedMonth, 1);
    final lastDayOfMonth =
    DateTime(vm.selectedYear, vm.selectedMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

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
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .map(
                    (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: day == '일' ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                // 7칸 기준 한 칸의 "가로" 길이
                final cellW = constraints.maxWidth / 7;

                // ✅ 타이트하게 만들고 싶으면 1.10~1.25 사이로 조절
                // childAspectRatio = width / height  -> 값이 커질수록 높이가 줄어듦
                const ratio = 1.15;

                // 6주(42칸) 고정이므로 그리드 전체 높이
                final gridH = (cellW / ratio) * 6;

                return SizedBox(
                  height: gridH,
                  child: PageView(
                    controller: _modePageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      final mode = index == 0 ? '감정' : '금액';
                      if (mode != selectedMode) {
                        setState(() => selectedMode = mode);
                      }
                    },
                    children: [
                      _buildCalendarGrid(
                        vm: vm,
                        firstWeekday: firstWeekday,
                        daysInMonth: daysInMonth,
                        showEmotion: true,
                        childAspectRatio: ratio,
                      ),
                      _buildCalendarGrid(
                        vm: vm,
                        firstWeekday: firstWeekday,
                        daysInMonth: daysInMonth,
                        showEmotion: false,
                        childAspectRatio: ratio,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid({
    required CommunicationViewModel vm,
    required int firstWeekday,
    required int daysInMonth,
    required bool showEmotion,
    required double childAspectRatio,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: childAspectRatio
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        final isCurrentMonth = day > 0 && day <= daysInMonth;

        if (!isCurrentMonth) return const SizedBox();

        final hasEmotion = vm.hasEmotionRecord(day);
        final hasAmount = vm.spendingAmountForDay(day) > 0;
        final hasRecord = hasEmotion || hasAmount;
        final amount = vm.spendingAmountForDay(day);

        return GestureDetector(
          onTap: () {
            showDateDetailModal(
              context: context,
              vm: vm,
              day: day,
            );
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final size =
                    (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) * 0.75;

                final bool isOverLimit =
                    vm.dailySpendingLimit > 0 && amount > vm.dailySpendingLimit;

                final showDayText = (!showEmotion || (showEmotion && !hasEmotion));
                // final showDayText =
                //     (showEmotion && !hasEmotion) || (!showEmotion && !hasAmount);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // if (!showEmotion && hasAmount)
                    //   _AmountCircle( size: size, isOverLimit: isOverLimit, ),
                    // 금액 모드
                    if (!showEmotion && hasAmount)
                      AmountUnderlineCell(
                        day: day,
                        isOverLimit: isOverLimit,
                      ),
                    // if (!showEmotion && hasAmount)
                    //   OutlineCircleCell(
                    //     day: day,
                    //     size: size,
                    //     isOverLimit: isOverLimit,
                    //   ),
                    // if (!showEmotion && hasAmount)
                    //   MoneyIconCell(
                    //     amount: amount,
                    //     limit: vm.dailySpendingLimit,
                    //     size: size * 1.0,
                    //   ),

                    // 감정 모드: 이모지
                    if (showEmotion && hasEmotion)
                      Text(
                        vm.emotionEmojiForDay(day),
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),

                    // 날짜 텍스트
                    if (showDayText)
                      Text(
                        '$day',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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

class _AmountCircle extends StatelessWidget {
  const _AmountCircle({
    required this.size,
    required this.isOverLimit,
  });

  final double size;
  final bool isOverLimit;

  @override Widget build(BuildContext context) {
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

    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
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
            border: Border.all(
              color: base.withOpacity(0.8),
              width: 2,
            ),
          ),
        ),
        Text(
          '$day',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
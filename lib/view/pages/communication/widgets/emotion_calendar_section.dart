import 'package:flutter/material.dart';

import '../../../../view_model/communication/communication_view_model.dart';

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
          // 월 선택 다이얼
          _buildMonthSelector(vm),
          const SizedBox(height: 16),

          // 달력 + 감정/금액 모드 다이얼
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
          // 상단: 연도 + 감정/금액 토글
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${vm.selectedYear}년',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _buildModeToggle(),
              ],
            ),
          ),

          // 실제 달력
          _buildCalendar(vm),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      width: 100,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: selectedMode == '감정'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeMode('감정'),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '감정',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedMode == '감정'
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeMode('금액'),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '금액',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedMode == '금액'
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                final cellSize = constraints.maxWidth / 7;
                final estimatedHeight = cellSize * 6 + 16;

                return SizedBox(
                  height: estimatedHeight,
                  child: PageView(
                    controller: _modePageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      final mode = index == 0 ? '감정' : '금액';
                      if (mode != selectedMode) {
                        setState(() {
                          selectedMode = mode;
                        });
                      }
                    },
                    children: [
                      _buildCalendarGrid(
                        vm: vm,
                        firstWeekday: firstWeekday,
                        daysInMonth: daysInMonth,
                        showEmotion: true,
                      ),
                      _buildCalendarGrid(
                        vm: vm,
                        firstWeekday: firstWeekday,
                        daysInMonth: daysInMonth,
                        showEmotion: false,
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
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        final isCurrentMonth = day > 0 && day <= daysInMonth;

        if (!isCurrentMonth) return const SizedBox();

        final hasEmotion = vm.hasEmotionRecord(day);
        final hasAmount = vm.spendingAmountForDay(day) > 0;
        final hasRecord = hasEmotion || hasAmount;

        return GestureDetector(
          onTap: () {
            _showDateDetailModal(vm, day, hasRecord);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showEmotion && hasEmotion) const SizedBox(height: 2),
                  Text(
                    '$day',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (showEmotion && hasEmotion)
                    Text(
                      vm.emotionEmojiForDay(day),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    )
                  else if (!showEmotion && hasAmount)
                    Text(
                      '${vm.spendingAmountForDay(day)}원',
                      style: TextStyle(
                        fontSize: 10,
                        color: vm.spendingAmountForDay(day) >
                            vm.dailySpendingLimit
                            ? Colors.red
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ──────────────── 날짜 상세 모달 ────────────────

  void _showDateDetailModal(
      CommunicationViewModel vm,
      int day,
      bool hasRecord,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final mediaQuery = MediaQuery.of(context);

        final content = hasRecord
            ? _buildRecordedDateContent(vm, day)
            : _buildEmptyDateContent(day);

        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordedDateContent(CommunicationViewModel vm, int day) {
    final emoji = vm.emotionEmojiForDay(day);
    final amount = vm.spendingAmountForDay(day);
    final diary = vm.diaryForDay(day);

    String _formatAmount(int value) {
      return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${vm.selectedMonth}월 ${day}일',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 수정 페이지로 이동
              },
              icon: const Icon(Icons.edit, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (emoji.isNotEmpty) ...[
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                vm.emotionNameFromEmoji(emoji),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // 소비 목록 (임시 분배)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '소비 목록',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSpendingItem('식비', (amount * 0.6).round(), _formatAmount),
              _buildSpendingItem('교통비', (amount * 0.2).round(), _formatAmount),
              _buildSpendingItem('카페', (amount * 0.2).round(), _formatAmount),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '총 합산',
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_formatAmount(amount)}원',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '소비 일지',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                diary,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingItem(
      String category,
      int amount,
      String Function(int) formatter,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category, style: const TextStyle(fontSize: 13)),
          Text(
            '${formatter(amount)}원',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDateContent(int day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.vm.selectedMonth}월 ${day}일',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          '소비를 기록해주세요',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 소비 입력 페이지로 이동
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '소비입력하러 가기',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

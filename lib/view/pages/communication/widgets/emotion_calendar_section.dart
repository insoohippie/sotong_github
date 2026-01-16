import 'package:flutter/material.dart';

import '../../../../../model/emotion_spending_diary.dart';
import '../../../../../view_model/communication/communication_view_model.dart';
import '../../../../component/theme/app_colors.dart';

/// --------------------------------------------------
/// 1. 섹션 + 카드 + 감정/금액 토글
///    (테스트 페이지 _buildCalendarWithModeDials 스타일)
/// --------------------------------------------------
class EmotionCalendarSection extends StatefulWidget {
  final CommunicationViewModel vm;

  const EmotionCalendarSection({super.key, required this.vm});

  @override
  State<EmotionCalendarSection> createState() => _EmotionCalendarSectionState();
}

class _EmotionCalendarSectionState extends State<EmotionCalendarSection> {
  /// 'emotion' or 'amount'
  String _selectedMode = 'emotion';

  /// 하루 소비 경고 기준 (원)
  static const int _dailySpendingLimit = 10000;

  @override
  Widget build(BuildContext context) {
    // Map<DateTime, List<Diary>> -> Map<DateTime, Diary> (첫 번째 것만 사용)
    final map = <DateTime, EmotionSpendingDiary>{};
    widget.vm.byDay.forEach((day, list) {
      if (list.isNotEmpty) {
        map[day] = list.first;
      }
    });

    return Container(
      width: double.infinity,
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
          // 상단 감정/금액 토글 (테스트 페이지와 비슷하게)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeChip('감정', 'emotion'),
                      _buildModeChip('금액', 'amount'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 실제 달력
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: EmotionCalendarWidget(
              diaryEntries: map,
              mode: _selectedMode,
              dailyLimit: _dailySpendingLimit,
              onDateSelected: (_) {},
              onDateTapped: (date) => _handleDateTapped(context, date),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, String value) {
    final bool isSelected = _selectedMode == value;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedMode = value;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _handleDateTapped(BuildContext context, DateTime date) {
    final vm = widget.vm;
    final entry = vm.firstEntryFor(date);

    if (entry != null) {
      // 기록 있는 날: 상세 다이얼로그
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '${date.month}월 ${date.day}일 소비/감정',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('감정: ${entry.emotion}'),
              const SizedBox(height: 8),
              Text('소비 금액: ${entry.spendingAmount.toStringAsFixed(0)}원'),
              if (entry.memo != null && entry.memo!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '메모',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(entry.memo!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } else {
      // 기록 없는 날: 소비 입력 유도
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '${date.month}월 ${date.day}일',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('아직 소비/감정 기록이 없어요.\n기록하러 갈까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true)
                    .pushNamed('/record_spending');
              },
              child: const Text('기록하러 가기'),
            ),
          ],
        ),
      );
    }
  }
}

/// --------------------------------------------------
/// 2. 실제 캘린더 위젯
///    - 테스트 페이지 달력 레이아웃 + ViewModel 데이터
///    - BOTTOM OVERFLOW 안 나게 높이/폰트 조정
/// --------------------------------------------------
class EmotionCalendarWidget extends StatefulWidget {
  final Map<DateTime, EmotionSpendingDiary> diaryEntries;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onDateTapped;

  /// 'emotion' or 'amount'
  final String mode;

  /// 금액 모드에서 경고 기준
  final int dailyLimit;

  const EmotionCalendarWidget({
    Key? key,
    required this.diaryEntries,
    required this.onDateSelected,
    required this.onDateTapped,
    required this.mode,
    required this.dailyLimit,
  }) : super(key: key);

  @override
  State<EmotionCalendarWidget> createState() => _EmotionCalendarWidgetState();
}

class _EmotionCalendarWidgetState extends State<EmotionCalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth =
    DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
    DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0=일
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: [
        // 상단 월/이전/다음
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                    1,
                  );
                });
              },
              icon: const Icon(Icons.chevron_left, size: 20),
            ),
            const SizedBox(width: 4),
            Text(
              '${_focusedMonth.month}월',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                    1,
                  );
                });
              },
              icon: const Icon(Icons.chevron_right, size: 20),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 요일 헤더
        Row(
          children: ['일', '월', '화', '수', '목', '금', '토']
              .map(
                (day) => Expanded(
              child: SizedBox(
                height: 20,
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: day == '일'
                          ? Colors.red
                          : (day == '토'
                          ? Colors.blue
                          : Colors.grey[700]),
                    ),
                  ),
                ),
              ),
            ),
          )
              .toList(),
        ),

        const SizedBox(height: 4),

        // 달력 그리드 (overflow 안 나게 childAspectRatio + 폰트 조정)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            // 살짝 세로로 여유를 줘서 overflow 방지
            childAspectRatio: 0.85,
          ),
          itemCount: 42, // 6주 * 7일
          itemBuilder: (context, index) {
            final day = index - firstWeekday + 1;
            final isCurrentMonth = day > 0 && day <= daysInMonth;

            if (!isCurrentMonth) {
              return const SizedBox();
            }

            final date = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              day,
            );
            final normalized = DateTime(date.year, date.month, date.day);
            final hasEntry = widget.diaryEntries.containsKey(normalized);
            final entry = widget.diaryEntries[normalized];

            return _buildDayCell(
              day: day,
              date: date,
              hasEntry: hasEntry && entry != null,
              entry: entry,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime date,
    required bool hasEntry,
    required EmotionSpendingDiary? entry,
  }) {
    final now = DateTime.now();
    final isToday = now.year == date.year &&
        now.month == date.month &&
        now.day == day;

    final weekday = date.weekday % 7; // 0=일, 6=토
    final isSunday = weekday == 0;
    final isSaturday = weekday == 6;

    Color dayColor;
    if (isSunday) {
      dayColor = Colors.red;
    } else if (isSaturday) {
      dayColor = Colors.blue;
    } else if (isToday) {
      dayColor = AppColors.primary;
    } else {
      dayColor = Colors.black87;
    }

    Widget? bottomWidget;
    if (hasEntry && entry != null) {
      if (widget.mode == 'emotion') {
        // 감정 이모지 / 아이콘 표시 모드
        bottomWidget = Text(
          _emojiFromEmotion(entry.emotion),
          style: const TextStyle(fontSize: 16),
        );
      } else {
        // 금액 텍스트 모드
        final amount = entry.spendingAmount.toInt();
        bottomWidget = Text(
          _formatAmount(amount),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: amount > widget.dailyLimit ? Colors.red : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    return GestureDetector(
      onTap: () {
        final normalized = DateTime(date.year, date.month, date.day);
        widget.onDateSelected(normalized);
        widget.onDateTapped(normalized);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? AppColors.primary
                : Colors.grey.withOpacity(0.2),
            width: isToday ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: dayColor,
              ),
            ),
            if (bottomWidget != null) ...[
              const SizedBox(height: 2),
              bottomWidget,
            ],
          ],
        ),
      ),
    );
  }

  String _emojiFromEmotion(String emotion) {
    switch (emotion) {
      case '기쁨':
      case '행복':
        return '😊';
      case '슬픔':
      case '우울':
        return '😢';
      case '화남':
      case '짜증':
        return '😠';
      case '피곤':
        return '😴';
      case '혼란':
      case '스트레스':
        return '😵‍💫';
      case '플렉스':
        return '😎';
      default:
        return '😐';
    }
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
  }
}

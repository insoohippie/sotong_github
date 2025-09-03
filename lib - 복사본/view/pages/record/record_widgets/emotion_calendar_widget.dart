import 'package:flutter/material.dart';
import '../../../../../model/emotion_spending_diary.dart';
import '../../../../component/theme/app_colors.dart';

class EmotionCalendarWidget extends StatefulWidget {
  final Map<DateTime, EmotionSpendingDiary> diaryEntries;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onDateTapped;

  const EmotionCalendarWidget({
    Key? key,
    required this.diaryEntries,
    required this.onDateSelected,
    required this.onDateTapped,
  }) : super(key: key);

  @override
  State<EmotionCalendarWidget> createState() => _EmotionCalendarWidgetState();
}

class _EmotionCalendarWidgetState extends State<EmotionCalendarWidget> {
  late DateTime _focusedDay;
  late PageController _monthPageController;
  int _currentMonthIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    // 2025년 8월부터 시작하도록 초기 인덱스 설정
    final currentDate = DateTime.now();
    final targetDate = DateTime(2025, 1, 1); // 2025년 1월부터 시작
    final monthDifference =
        (currentDate.year - targetDate.year) * 12 +
        (currentDate.month - targetDate.month);
    // 2025년 8월이 8번째 인덱스가 되도록 조정 (1월=0, 2월=1, ..., 8월=7)
    _currentMonthIndex = 7; // 2025년 8월 인덱스
    _monthPageController = PageController(initialPage: _currentMonthIndex);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(children: [_buildCalendarHeader(), _buildCalendarGrid()]),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              _monthPageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_focusedDay.year}년 ${_focusedDay.month}월',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              _monthPageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map(
                  (day) => Expanded(
                    child: Container(
                      height: 25,
                      alignment: Alignment.center,
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 0),
          // 달력 그리드
          SizedBox(
            height: 285,
            child: PageView.builder(
              controller: _monthPageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentMonthIndex = index;
                  // 2025년 1월부터 시작하여 월 계산
                  final targetDate = DateTime(2025, 1, 1);
                  _focusedDay = DateTime(
                    targetDate.year,
                    targetDate.month + index,
                    1,
                  );
                });
              },
              itemBuilder: (context, index) {
                // 2025년 1월부터 시작하여 월 계산
                final targetDate = DateTime(2025, 1, 1);
                final monthDate = DateTime(
                  targetDate.year,
                  targetDate.month + index,
                  1,
                );
                return _buildMonthCalendar(monthDate);
              },
              // 2025년 1월부터 12월까지 총 12개월
              itemCount: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(DateTime monthDate) {
    return Container(
      height: 285,
      child: Column(children: _buildCalendarRows(monthDate)),
    );
  }

  List<Widget> _buildCalendarRows(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> rows = [];
    int day = 1;
    int currentWeekday = firstWeekday;

    while (day <= daysInMonth) {
      List<Widget> week = [];

      for (int i = 0; i < 7; i++) {
        if (currentWeekday > 0) {
          week.add(const Expanded(child: SizedBox()));
          currentWeekday--;
        } else if (day <= daysInMonth) {
          final currentDate = DateTime(monthDate.year, monthDate.month, day);
          final normalizedDate = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
          );
          final hasEntry = widget.diaryEntries.containsKey(normalizedDate);

          week.add(Expanded(child: _buildDayCell(day, currentDate, hasEntry)));
          day++;
        } else {
          week.add(const Expanded(child: SizedBox()));
        }
      }

      rows.add(Row(children: week));
      // 마지막 줄 밑에는 여백을 추가하지 않음
    }

    return rows;
  }

  Widget _buildDayCell(int day, DateTime date, bool hasEntry) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final entry = widget.diaryEntries[normalizedDate];
    final isToday =
        DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == day;

    // 요일 확인 (0=일요일, 6=토요일)
    final weekday = date.weekday % 7;
    final isSunday = weekday == 0;
    final isSaturday = weekday == 6;

    // 공휴일 확인 (간단한 예시 - 실제로는 더 많은 공휴일을 추가해야 함)
    final isHoliday = _isHoliday(date);

    // 디버그 정보 출력
    if (hasEntry && entry != null) {
      print(
        '감정 데이터 발견: ${entry.emotion} - ${entry.date} - ${entry.spendingAmount}원',
      );
    }

    // 날짜 텍스트 색상 결정
    Color textColor;
    if (isHoliday) {
      textColor = Colors.green;
    } else if (isSunday) {
      textColor = Colors.red;
    } else if (isSaturday) {
      textColor = Colors.blue;
    } else if (isToday) {
      textColor = AppColors.primary;
    } else {
      textColor = Colors.black87;
    }

    return GestureDetector(
      onTap: () {
        widget.onDateTapped(normalizedDate);
      },
      child: Container(
        height: 45,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isToday ? AppColors.primary : Colors.grey.withOpacity(0.3),
            width: isToday ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (hasEntry && entry != null) ...[
              const SizedBox(height: 0),
              Container(
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: _getEmotionColor(entry.emotion).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getEmotionIcon(entry.emotion),
                  size: 12,
                  color: _getEmotionColor(entry.emotion),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 공휴일 확인 메서드
  bool _isHoliday(DateTime date) {
    // 2025년 공휴일 목록 (간단한 예시)
    final holidays = [
      DateTime(2025, 1, 1), // 신정
      DateTime(2025, 2, 9), // 설날
      DateTime(2025, 2, 10), // 설날
      DateTime(2025, 2, 11), // 설날
      DateTime(2025, 3, 1), // 삼일절
      DateTime(2025, 5, 5), // 어린이날
      DateTime(2025, 5, 15), // 부처님 오신 날
      DateTime(2025, 6, 6), // 현충일
      DateTime(2025, 8, 15), // 광복절
      DateTime(2025, 9, 28), // 추석
      DateTime(2025, 9, 29), // 추석
      DateTime(2025, 9, 30), // 추석
      DateTime(2025, 10, 3), // 개천절
      DateTime(2025, 10, 9), // 한글날
      DateTime(2025, 12, 25), // 크리스마스
    ];

    final normalizedDate = DateTime(date.year, date.month, date.day);
    return holidays.any(
      (holiday) =>
          holiday.year == normalizedDate.year &&
          holiday.month == normalizedDate.month &&
          holiday.day == normalizedDate.day,
    );
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case '기쁨':
        return Icons.sentiment_very_satisfied;
      case '슬픔':
        return Icons.sentiment_very_dissatisfied;
      case '화남':
        return Icons.sentiment_dissatisfied;
      case '평온':
        return Icons.sentiment_satisfied;
      case '혼란':
        return Icons.sentiment_neutral;
      case '만족':
        return Icons.sentiment_satisfied_alt;
      case '우울':
        return Icons.sentiment_dissatisfied;
      case '행복':
        return Icons.sentiment_very_satisfied;
      case '짜증':
        return Icons.sentiment_dissatisfied;
      case '감사':
        return Icons.favorite;
      case '스트레스':
        return Icons.sentiment_neutral;
      case '편안':
        return Icons.sentiment_satisfied;
      default:
        return Icons.favorite;
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case '기쁨':
      case '행복':
        return Colors.yellow[700]!;
      case '슬픔':
      case '우울':
        return Colors.blue[700]!;
      case '화남':
      case '짜증':
        return Colors.red[700]!;
      case '평온':
      case '편안':
      case '만족':
        return Colors.green[700]!;
      case '혼란':
      case '스트레스':
        return Colors.orange[700]!;
      case '감사':
        return Colors.pink[700]!;
      default:
        return AppColors.primary;
    }
  }
}

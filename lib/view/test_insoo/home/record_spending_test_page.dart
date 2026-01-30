import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../component/appbars/custom_app_bar_title_subtitle.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../view_model/record/record_view_model.dart';

class RecordSpendingTestPage extends StatefulWidget {
  const RecordSpendingTestPage({super.key});

  @override
  State<RecordSpendingTestPage> createState() => _RecordSpendingTestPageState();
}

class _RecordSpendingTestPageState extends State<RecordSpendingTestPage> {
  int _selectedTab = 1; // 0: 수입, 1: 소비 (기본값: 소비)
  late DateTime _selectedDate;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // 기본값으로 초기화
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is DateTime) {
        _selectedDate = args;
      }
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RecordViewModel>().resetSpending();
        // context.read<RecordViewModel>().resetIncome();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  // 수입/소비 다이얼 토글 버튼 (소통창 스타일)
  Widget _buildIncomeSpendingToggle() {
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
            alignment: _selectedTab == 0
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
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '수입',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 0
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '소비',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 1
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

  void _onPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _onNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _openDatePickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DatePickerModal(
        initialDate: _selectedDate,
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecordViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBarTitleSubtitle(
              title: '',
              subtitle: '',
              onBack: () => Navigator.pop(context),
            ),
            // 날짜 선택 버튼 (< 1월 12일 >)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 이전 날짜 버튼
                  GestureDetector(
                    onTap: _onPreviousDay,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 날짜 버튼
                  GestureDetector(
                    onTap: _openDatePickerModal,
                    child: Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 다음 날짜 버튼
                  GestureDetector(
                    onTap: _onNextDay,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 수입/소비 다이얼 버튼 (소통창 스타일)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_buildIncomeSpendingToggle()],
              ),
            ),
            // Expanded(
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: AppSpacing.screenPadding,
            //     ),
            //     child: SingleChildScrollView(
            //       child: Column(
            //         children: [
            //           // 수입 탭
            //           if (_selectedTab == 0) ...[
            //             ...viewModel.incomeEntries.map((entry) {
            //               return SpendingInputEntry(
            //                 entry: entry,
            //                 categoryItems: incomePresets
            //                     .map((p) => p.name)
            //                     .toList(),
            //                 presets: incomePresets,
            //                 enabledStates:
            //                     CategoryStateManager.incomeEnabledStates,
            //                 customCategories:
            //                     CategoryStateManager.customIncomeCategories,
            //                 categoryEmojis:
            //                     CategoryStateManager.incomeCategoryEmojis,
            //                 onDelete: () =>
            //                     viewModel.removeIncomeEntryByRef(entry),
            //               );
            //             }).toList(),
            //             const SizedBox(height: 12),
            //             SmallRoundedButton(
            //               text: '추가',
            //               backgroundColor: AppColors.greyBackground,
            //               textColor: AppColors.text,
            //               onPressed: () {
            //                 viewModel.addIncomeEntry();
            //               },
            //             ),
            //           ],
            //           // 소비 탭
            //           if (_selectedTab == 1) ...[
            //             ...viewModel.spendingEntries.map((entry) {
            //               return SpendingInputEntry(
            //                 entry: entry,
            //                 categoryItems: ['식비', '교통비', '문화비'],
            //                 onDelete: () => viewModel.removeEntryByRef(entry),
            //               );
            //             }).toList(),
            //             const SizedBox(height: 12),
            //             SmallRoundedButton(
            //               text: '추가',
            //               backgroundColor: AppColors.greyBackground,
            //               textColor: AppColors.text,
            //               onPressed: () {
            //                 viewModel.addEntry();
            //               },
            //             ),
            //           ],
            //           const SizedBox(height: AppSpacing.bottomSpacing),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.fieldSpacing),
                    ParagraphText(
                      text: _selectedTab == 0 ? '총 수입 금액' : '총 소비 금액',
                    ),
                    const SizedBox(height: AppSpacing.itemSpacing),
                    // Selector<RecordViewModel, String>(
                    //   selector: (_, vm) => _selectedTab == 0
                    //       // ? vm.formattedIncomeTotal
                    //       : vm.formattedTotal,
                    //   builder: (_, formattedTotal, __) {
                    //     return ParagraphText(
                    //       text: '$formattedTotal원',
                    //       fontWeight: FontWeight.bold,
                    //       color: AppColors.primary,
                    //     );
                    //   },
                    // ),
                    const SizedBox(height: AppSpacing.fieldSpacing),
                  ],
                ),
              ),
            ),
            CustomButton(
              text: '다음 단계',
              enabled: true,
              onPressed: () {
                // 수입 탭일 때는 amount_change_choice 페이지로 이동
                if (_selectedTab == 0) {
                  // 총 수입 금액 계산
                  // final totalIncome = viewModel.totalIncome;
                  // final formattedTotal = totalIncome
                  //     .toString()
                  //     .replaceAllMapped(
                  //       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  //       (Match m) => '${m[1]},',
                  //     );

                  // Navigator.pushNamed(
                  //   context,
                  //   '/amount_change_choice',
                  //   arguments: '$formattedTotal원',
                  // );
                } else {
                  // 소비 탭일 때는 기존처럼 record_diary로 이동
                  Navigator.pushNamed(
                    context,
                    '/record_diary',
                    arguments: _selectedDate,
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }
}

// 날짜 선택 모달
class _DatePickerModal extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const _DatePickerModal({
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_DatePickerModal> createState() => _DatePickerModalState();
}

class _DatePickerModalState extends State<_DatePickerModal> {
  late DateTime _selectedDate;
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentYear = _selectedDate.year;
    _currentMonth = _selectedDate.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth += delta;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final lastDayOfMonth = DateTime(_currentYear, _currentMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // 월요일부터 시작하도록 조정 (weekday: 1=월요일, 7=일요일)
    final startOffset = (firstWeekday == 7) ? 0 : firstWeekday - 1;

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      children: [
        // 요일 헤더
        Row(
          children: weekdays.map((day) {
            return Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: day == '토'
                      ? Colors.blue
                      : day == '일'
                      ? Colors.red
                      : Colors.black87,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // 달력 그리드
        LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / 7;
            return Column(
              children: [
                for (int week = 0; week < 6; week++)
                  Row(
                    children: [
                      for (int day = 0; day < 7; day++)
                        Builder(
                          builder: (context) {
                            final dayNumber = week * 7 + day - startOffset + 1;
                            final isCurrentMonth =
                                dayNumber > 0 && dayNumber <= daysInMonth;
                            final date = isCurrentMonth
                                ? DateTime(
                                    _currentYear,
                                    _currentMonth,
                                    dayNumber,
                                  )
                                : null;
                            final isSelected =
                                date != null &&
                                date.year == _selectedDate.year &&
                                date.month == _selectedDate.month &&
                                date.day == _selectedDate.day;
                            final isToday =
                                date != null &&
                                date.year == DateTime.now().year &&
                                date.month == DateTime.now().month &&
                                date.day == DateTime.now().day;

                            return Expanded(
                              child: GestureDetector(
                                onTap: isCurrentMonth && date != null
                                    ? () {
                                        widget.onDateSelected(date);
                                      }
                                    : null,
                                child: Container(
                                  width: cellSize,
                                  height: cellSize,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: isCurrentMonth
                                        ? Text(
                                            '$dayNumber',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.white
                                                  : isToday
                                                  ? AppColors.primary
                                                  : Colors.black87,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 이전 달
                GestureDetector(
                  onTap: () => _changeMonth(-1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.grey[700],
                      size: 24,
                    ),
                  ),
                ),
                // 년월 표시
                Text(
                  '$_currentYear년 $_currentMonth월',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // 다음 달
                GestureDetector(
                  onTap: () => _changeMonth(1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.grey[700],
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 달력
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCalendarGrid(),
            ),
          ),
        ],
      ),
    );
  }
}

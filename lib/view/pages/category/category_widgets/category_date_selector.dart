import 'package:flutter/material.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_text_styles.dart';

class CategoryDateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapDate;

  const CategoryDateSelector({
    super.key,
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${date.month}월 ${date.day}일';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, color: AppColors.subText),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onTapDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formattedDate,
                style: AppTextStyles.paragraph.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: AppColors.subText),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// ✅ 날짜 모달(기존 _DatePickerModal을 공개 위젯으로)
class CategoryDatePickerModal extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final DateTime initialDate;
  final void Function(DateTime) onDateSelected;

  const CategoryDatePickerModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CategoryDatePickerModal> createState() => _CategoryDatePickerModalState();
}

class _CategoryDatePickerModalState extends State<CategoryDatePickerModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _scrimFade;
  static const _kSlideMs = 300;

  DateTime _selectedDate = DateTime.now();
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;

  late final PageController _pageController;
  int _currentPage = 0;

  Map<String, dynamic>? _selectedChange;

  // TODO: 나중에 VM에서 가져오기
  final List<Map<String, dynamic>> _budgetChanges = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentYear = widget.initialDate.year;
    _currentMonth = widget.initialDate.month;
    _pageController = PageController();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kSlideMs),
      reverseDuration: const Duration(milliseconds: _kSlideMs),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scrimFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
    }
  }

  @override
  void didUpdateWidget(covariant CategoryDatePickerModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (widget.isOpen) {
        _selectedDate = widget.initialDate;
        _currentYear = widget.initialDate.year;
        _currentMonth = widget.initialDate.month;
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _closeWithAnimation() {
    _ctrl.reverse().then((_) {
      if (mounted) widget.onClose();
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      final newDate = DateTime(_currentYear, _currentMonth + delta, 1);
      _currentYear = newDate.year;
      _currentMonth = newDate.month;
    });
  }

  Widget _buildMonthSelector() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _changeMonth(-1),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.chevron_left, color: Colors.grey[700], size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_currentMonth월',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _changeMonth(1),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.chevron_right, color: Colors.grey[700], size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final lastDayOfMonth = DateTime(_currentYear, _currentMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday; // 1~7
    final daysInMonth = lastDayOfMonth.day;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                    color: day == '토'
                        ? Colors.blue
                        : day == '일'
                        ? Colors.red
                        : Colors.black87,
                  ),
                ),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cellW = constraints.maxWidth / 7;
              const ratio = 1.3;
              final gridH = ((cellW / ratio) * 6).clamp(0.0, 200.0);

              return SizedBox(
                height: gridH,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: ratio,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final day = index - (firstWeekday - 1) + 1;
                    final isCurrentMonth = day > 0 && day <= daysInMonth;
                    if (!isCurrentMonth) return const SizedBox();

                    final date = DateTime(_currentYear, _currentMonth, day);
                    final isSelected =
                        date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;

                    final weekday = date.weekday;
                    final isSat = weekday == 6;
                    final isSun = weekday == 7;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          widget.onDateSelected(date);
                          _closeWithAnimation();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isSun
                                    ? Colors.red
                                    : isSat
                                    ? Colors.blue
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarAndListPage() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildMonthSelector(),
                ),
                _buildCalendarGrid(),
              ],
            ),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade200),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: SizedBox(height: 140, child: _buildBudgetChangeList()),
        ),
      ],
    );
  }

  Widget _buildChangeDetailPage() {
    if (_selectedChange == null) {
      return const Center(child: Text('변경 정보를 불러올 수 없습니다.'));
    }
    return const SizedBox.shrink(); // TODO: 너 기존 상세 페이지 붙이면 됨
  }

  Widget _buildBudgetChangeList() {
    if (_budgetChanges.isEmpty) {
      return Center(
        child: Text(
          '예산 변경 내역이 없습니다.',
          style: AppTextStyles.subtext.copyWith(color: AppColors.subText),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen && _ctrl.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        FadeTransition(
          opacity: _scrimFade,
          child: GestureDetector(
            onTap: _closeWithAnimation,
            child: Container(color: Colors.black54),
          ),
        ),
        Positioned.fill(
          child: SlideTransition(
            position: _slide,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 1.0,
                heightFactor: 0.85,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _currentPage == 0
                                  ? Text(
                                '날짜 선택',
                                style: AppTextStyles.header.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                                  : IconButton(
                                onPressed: () {
                                  setState(() => _currentPage = 0);
                                  _pageController.animateToPage(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                icon: const Icon(Icons.arrow_back),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                onPressed: _closeWithAnimation,
                                icon: const Icon(Icons.close),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (index) => setState(() => _currentPage = index),
                            children: [
                              _buildCalendarAndListPage(),
                              _buildChangeDetailPage(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

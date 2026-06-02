import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wheel_picker/wheel_picker.dart';

import '../buttons/custom_button.dart';
import '../theme/app_text_styles.dart';

class WheelDateSelector extends StatelessWidget {
  final String selectedDate;
  final String hintText;
  final void Function(DateTime) onDateSelected;
  final double height;

  const WheelDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.hintText = '날짜를 선택하세요',
    this.height = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isEmpty = selectedDate.isEmpty;
    final Color bgColor = isEmpty
        ? (isDark ? theme.colorScheme.surface : const Color(0xFFEDEDED))
        : (isDark ? theme.colorScheme.surface : const Color(0xFFEDF4FF));

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
        _showWheelDatePicker(context);
      },
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          isEmpty ? hintText : selectedDate,
          style: AppTextStyles.paragraph.copyWith(
            color: isEmpty
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _showWheelDatePicker(BuildContext context) {
    int selectedYear = 2000;
    int selectedMonth = 1;
    int selectedDay = 1;

    if (selectedDate.isNotEmpty) {
      final parsed = DateTime.tryParse(selectedDate);
      if (parsed != null) {
        final now = DateTime.now();
        selectedYear = parsed.year.clamp(1900, now.year);
        selectedMonth = parsed.month.clamp(1, 12);
        final lastDay = DateTime(selectedYear, selectedMonth + 1, 0).day;
        selectedDay = parsed.day.clamp(1, lastDay);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (ctx) => _WheelDatePickerModal(
        initialYear: selectedYear,
        initialMonth: selectedMonth,
        initialDay: selectedDay,
        onConfirm: (date) {
          onDateSelected(date);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// 시간 휠(TimeWheelModal)과 동일한 스타일: 중앙 1개 강조, 위아래 1개씩 회색 처리.
class _WheelDatePickerModal extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int initialDay;
  final void Function(DateTime) onConfirm;

  const _WheelDatePickerModal({
    required this.initialYear,
    required this.initialMonth,
    required this.initialDay,
    required this.onConfirm,
  });

  @override
  State<_WheelDatePickerModal> createState() => _WheelDatePickerModalState();
}

class _WheelDatePickerModalState extends State<_WheelDatePickerModal> {
  late WheelPickerController _yearController;
  late WheelPickerController _monthController;
  late WheelPickerController _dayController;

  int _selectedYear = 2000;
  int _selectedMonth = 1;
  int _selectedDay = 1;

  static const double _itemExtent = 36.0;
  static final WheelPickerStyle _wheelStyle = WheelPickerStyle(
    itemExtent: _itemExtent,
    squeeze: 1.25,
    diameterRatio: .8,
    surroundingOpacity: .25,
    magnification: 1.2,
  );

  int get _daysInMonth => DateTime(_selectedYear, _selectedMonth + 1, 0).day;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _selectedDay = widget.initialDay;
    _initControllers();
  }

  void _initControllers() {
    final now = DateTime.now();
    final yearCount = now.year - 1900 + 1;
    final yearIndex = (widget.initialYear - 1900).clamp(0, yearCount - 1);
    final monthIndex = (widget.initialMonth - 1).clamp(0, 11);
    final lastDay = DateTime(
      widget.initialYear,
      widget.initialMonth + 1,
      0,
    ).day;
    final dayIndex = (widget.initialDay - 1).clamp(0, lastDay - 1);

    _yearController = WheelPickerController(
      itemCount: yearCount,
      initialIndex: yearIndex,
    );
    _monthController = WheelPickerController(
      itemCount: 12,
      initialIndex: monthIndex,
    );
    _dayController = WheelPickerController(
      itemCount: lastDay,
      initialIndex: dayIndex,
    );
  }

  void _onYearChanged(int index) {
    setState(() => _selectedYear = 1900 + index);
    _onYearOrMonthChanged();
  }

  void _onMonthChanged(int index) {
    setState(() => _selectedMonth = index + 1);
    _onYearOrMonthChanged();
  }

  void _onDayChanged(int index) {
    setState(() => _selectedDay = index + 1);
  }

  void _onYearOrMonthChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final daysInMonth = _daysInMonth;
      if (_dayController.itemCount != daysInMonth) {
        final clampedDay = _selectedDay.clamp(1, daysInMonth);
        setState(() => _selectedDay = clampedDay);
        _dayController.dispose();
        _dayController = WheelPickerController(
          itemCount: daysInMonth,
          initialIndex: clampedDay - 1,
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    HapticFeedback.selectionClick();
    final date = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    widget.onConfirm(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final textStyle = TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      fontFamily: 'Pretendard Variable',
      color: textColor,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.3 : 0.1,
            ),
            offset: const Offset(0, -4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: _itemExtent * 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 년
                    SizedBox(
                      width: 64,
                      child: WheelPicker(
                        builder: (context, index) =>
                            Text('${1900 + index}', style: textStyle),
                        controller: _yearController,
                        looping: false,
                        selectedIndexColor: textColor,
                        onIndexChanged: (index, _) {
                          HapticFeedback.selectionClick();
                          _onYearChanged(index);
                        },
                        style: _wheelStyle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('년', style: textStyle.copyWith(fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: _itemExtent * 2,
                      color: theme.dividerColor,
                    ),
                    const SizedBox(width: 8),
                    // 월
                    SizedBox(
                      width: 56,
                      child: WheelPicker(
                        builder: (context, index) =>
                            Text('${index + 1}월', style: textStyle),
                        controller: _monthController,
                        looping: false,
                        selectedIndexColor: textColor,
                        onIndexChanged: (index, _) {
                          HapticFeedback.selectionClick();
                          _onMonthChanged(index);
                        },
                        style: _wheelStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: _itemExtent * 2,
                      color: theme.dividerColor,
                    ),
                    const SizedBox(width: 8),
                    // 일
                    SizedBox(
                      width: 56,
                      child: WheelPicker(
                        builder: (context, index) =>
                            Text('${index + 1}', style: textStyle),
                        controller: _dayController,
                        looping: false,
                        selectedIndexColor: textColor,
                        onIndexChanged: (index, _) {
                          HapticFeedback.selectionClick();
                          _onDayChanged(index);
                        },
                        style: _wheelStyle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('일', style: textStyle.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomButton(text: '확인', onPressed: _onConfirm),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

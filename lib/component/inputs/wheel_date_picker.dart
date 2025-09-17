import 'package:flutter/material.dart';

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
    final bool isEmpty = selectedDate.isEmpty;
    final Color bgColor = isEmpty
        ? const Color(0xFFEDEDED)
        : const Color(0xFFEDF4FF);

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
            color: isEmpty ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }

  void _showWheelDatePicker(BuildContext context) {
    DateTime tempPickedDate = DateTime(2000, 1, 1);
    int selectedYear = 2000;
    int selectedMonth = 1;
    int selectedDay = 1;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: 400,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 제목
                  Text(
                    '생년월일 선택',
                    style: AppTextStyles.header.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 날짜 선택기
                  Expanded(
                    child: Row(
                      children: [
                        // 년도 선택
                        Expanded(
                          child: _buildYearPicker(selectedYear, (year) {
                            setState(() {
                              selectedYear = year;
                              tempPickedDate = DateTime(
                                selectedYear,
                                selectedMonth,
                                selectedDay,
                              );
                            });
                          }),
                        ),
                        // 월 선택
                        Expanded(
                          child: _buildMonthPicker(selectedMonth, (month) {
                            setState(() {
                              selectedMonth = month;
                              tempPickedDate = DateTime(
                                selectedYear,
                                selectedMonth,
                                selectedDay,
                              );
                            });
                          }),
                        ),
                        // 일 선택
                        Expanded(
                          child: _buildDayPicker(
                            selectedDay,
                            selectedYear,
                            selectedMonth,
                            (day) {
                              setState(() {
                                selectedDay = day;
                                tempPickedDate = DateTime(
                                  selectedYear,
                                  selectedMonth,
                                  selectedDay,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 확인 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CustomButton(
                      onPressed: () {
                        onDateSelected(tempPickedDate);
                        Navigator.pop(context);
                      },
                      text: '확인',
                      height: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildYearPicker(int selectedYear, Function(int) onChanged) {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1900 + 1,
      (index) => 1900 + index,
    );

    return Column(
      children: [
        Text(
          '년',
          style: AppTextStyles.paragraph.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: years.length,
            itemExtent: 50,
            controller: ScrollController(
              initialScrollOffset: (years.indexOf(selectedYear)) * 50.0 - 100.0,
            ),
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = year == selectedYear;

              return GestureDetector(
                onTap: () => onChanged(year),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF0F0F0)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    year.toString(),
                    style: AppTextStyles.paragraph.copyWith(
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthPicker(int selectedMonth, Function(int) onChanged) {
    final months = List.generate(12, (index) => index + 1);

    return Column(
      children: [
        Text(
          '월',
          style: AppTextStyles.paragraph.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: months.length,
            itemExtent: 50,
            controller: ScrollController(
              initialScrollOffset:
                  (months.indexOf(selectedMonth)) * 50.0 - 100.0,
            ),
            itemBuilder: (context, index) {
              final month = months[index];
              final isSelected = month == selectedMonth;

              return GestureDetector(
                onTap: () => onChanged(month),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF0F0F0)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$month월',
                    style: AppTextStyles.paragraph.copyWith(
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayPicker(
    int selectedDay,
    int year,
    int month,
    Function(int) onChanged,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = List.generate(daysInMonth, (index) => index + 1);

    return Column(
      children: [
        Text(
          '일',
          style: AppTextStyles.paragraph.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: days.length,
            itemExtent: 50,
            controller: ScrollController(
              initialScrollOffset: (days.indexOf(selectedDay)) * 50.0 - 100.0,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = day == selectedDay;

              return GestureDetector(
                onTap: () => onChanged(day),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF0F0F0)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    day.toString(),
                    style: AppTextStyles.paragraph.copyWith(
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

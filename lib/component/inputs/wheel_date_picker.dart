import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sotong_local/component/buttons/small_rounded_button.dart';

import '../buttons/custom_button.dart';
import '../theme/app_colors.dart';
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
    DateTime tempPickedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: DateTime(2000, 1, 1),
                  minimumYear: 1900,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (date) {
                    tempPickedDate = date;
                  },
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    ).whenComplete(() {
      Future.microtask(() {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    });
  }
}

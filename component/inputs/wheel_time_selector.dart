import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class WheelTimeSelector extends StatelessWidget {
  final String selectedTime;
  final String hintText;
  final void Function(TimeOfDay) onTimeSelected;
  final double height;

  const WheelTimeSelector({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
    this.hintText = '시간을 선택하세요',
    this.height = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = selectedTime.isEmpty;
    final Color bgColor = isEmpty
        ? const Color(0xFFEDEDED)
        : const Color(0xFFEDF4FF);

    return GestureDetector(
      onTap: () => _showWheelTimePicker(context),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          isEmpty ? hintText : selectedTime,
          style: AppTextStyles.paragraph.copyWith(
            color: isEmpty ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }

  void _showWheelTimePicker(BuildContext context) {
    Duration tempPickedDuration = const Duration(hours: 12, minutes: 0);

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: tempPickedDuration,
                  onTimerDurationChanged: (duration) {
                    tempPickedDuration = duration;
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  final pickedTime = TimeOfDay(
                    hour: tempPickedDuration.inHours,
                    minute: tempPickedDuration.inMinutes % 60,
                  );
                  onTimeSelected(pickedTime);
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }
}

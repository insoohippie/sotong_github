import 'package:flutter/material.dart';
import 'package:wheel_picker/wheel_picker.dart';

import '../buttons/custom_button.dart';

/// 알림 시간 선택 모달 (오전/오후 | 시간 1~12 | 분 5분 단위).
/// 바텀시트로 띄울 내용 위젯.
class TimeWheelModal extends StatefulWidget {
  final bool initialIsAm;
  final int initialHour12;
  final int initialMinute;
  final void Function(bool isAm, int hour12, int minute) onConfirm;
  final VoidCallback onCancel;

  const TimeWheelModal({
    super.key,
    required this.initialIsAm,
    required this.initialHour12,
    required this.initialMinute,
    required this.onConfirm,
    required this.onCancel,
  });

  /// 현재 시간을 바텀시트로 띄우고 선택된 [TimeOfDay]를 반환. 취소 시 null.
  static Future<TimeOfDay?> show(
    BuildContext context,
    TimeOfDay current,
  ) async {
    final hour12 = current.hour == 0
        ? 12
        : (current.hour > 12 ? current.hour - 12 : current.hour);
    final isAm = current.hour < 12;
    const minuteOptions = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
    final minute = minuteOptions.reduce(
      (a, b) => (current.minute - a).abs() < (current.minute - b).abs() ? a : b,
    );

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return TimeWheelModal(
          initialIsAm: isAm,
          initialHour12: hour12,
          initialMinute: minute,
          onConfirm: (isAm, hour12, minute) {
            final h = isAm
                ? (hour12 == 12 ? 0 : hour12)
                : (hour12 == 12 ? 12 : hour12 + 12);
            Navigator.pop(ctx, TimeOfDay(hour: h, minute: minute));
          },
          onCancel: () => Navigator.pop(ctx),
        );
      },
    );
  }

  @override
  State<TimeWheelModal> createState() => _TimeWheelModalState();
}

class _TimeWheelModalState extends State<TimeWheelModal> {
  static const List<int> _minuteOptions = [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
  ];

  late final WheelPickerController _amPmController;
  late final WheelPickerController _hourController;
  late final WheelPickerController _minuteController;

  static const double _itemExtent = 36.0;

  @override
  void initState() {
    super.initState();
    final minuteIdx = _minuteOptions.indexOf(widget.initialMinute);
    final minuteIndex = minuteIdx >= 0 ? minuteIdx : 0;

    _amPmController = WheelPickerController(
      itemCount: 2,
      initialIndex: widget.initialIsAm ? 0 : 1,
    );
    _hourController = WheelPickerController(
      itemCount: 12,
      initialIndex: (widget.initialHour12.clamp(1, 12) - 1),
    );
    _minuteController = WheelPickerController(
      itemCount: _minuteOptions.length,
      initialIndex: minuteIndex,
    );
  }

  @override
  void dispose() {
    _amPmController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final isAm = _amPmController.selected == 0;
    final hour12 = _hourController.selected + 1;
    final minute = _minuteOptions[_minuteController.selected];
    widget.onConfirm(isAm, hour12, minute);
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
    final mediaQuery = MediaQuery.of(context);
    final wheelStyle = WheelPickerStyle(
      itemExtent: _itemExtent,
      squeeze: 1.25,
      diameterRatio: .8,
      surroundingOpacity: .25,
      magnification: 1.2,
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
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
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
                    SizedBox(
                      width: 72,
                      child: WheelPicker(
                        builder: (context, index) =>
                            Text(index == 0 ? '오전' : '오후', style: textStyle),
                        controller: _amPmController,
                        looping: false,
                        selectedIndexColor: textColor,
                        onIndexChanged: (index, _) {},
                        style: wheelStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: _itemExtent * 2,
                      color: theme.dividerColor,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 56,
                      child: WheelPicker(
                        builder: (context, index) =>
                            Text('${index + 1}', style: textStyle),
                        controller: _hourController,
                        selectedIndexColor: textColor,
                        onIndexChanged: (index, _) {},
                        style: wheelStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: _itemExtent * 2,
                      color: theme.dividerColor,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 56,
                      child: WheelPicker(
                        builder: (context, index) => Text(
                          _minuteOptions[index].toString().padLeft(2, '0'),
                          style: textStyle,
                        ),
                        controller: _minuteController,
                        selectedIndexColor: textColor,
                        onIndexChanged: (index, _) {},
                        style: wheelStyle,
                      ),
                    ),
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

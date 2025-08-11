import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../component/theme/app_border_radius.dart';
import '../../../model/alarm.dart';
import '../../../view_model/setting/alarm_view_model.dart';

class NotificationSettingPage extends StatefulWidget {
  const NotificationSettingPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingPage> createState() =>
      _NotificationSettingPageState();
}

class _NotificationSettingPageState extends State<NotificationSettingPage> {
  // 출석 알림 설정
  bool _attendanceEnabled = false;
  TimeOfDay _attendanceTime = const TimeOfDay(hour: 9, minute: 0);

  // 동기부여 알림 설정
  bool _motivationEnabled = false;
  TimeOfDay _motivationTime = const TimeOfDay(hour: 18, minute: 0);

  // 주간 리포트 알림 설정
  bool _weeklyReportEnabled = false;
  bool _emotionReportEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '알림 설정',
          style: TextStyle(
            fontFamily: 'Pretendard Variable',
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 데일리 알림 섹션
              const Text(
                '데일리 알림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // 출석 알림 설정 영역
              _buildNotificationCard(
                title: '출석알림',
                emoji: '✍️',
                description: '매일 설정한 시간에, 소비 기록을 도와드려요!',
                purpose: '소비 기록 습관을 만들 수 있도록, 정해진 시간에 푸시로 리마인드해드립니다.',
                enabled: _attendanceEnabled,
                onToggle: (value) => setState(() => _attendanceEnabled = value),
                timeEnabled: _attendanceEnabled,
                selectedTime: _attendanceTime,
                onTimeChanged: (time) => setState(() => _attendanceTime = time),
                examples: [
                  '오늘 소비를 기록하셨나요? 지금 입력해보세요!',
                  '어제 소비를 깜빡하신 것 같아요! 지금 추가해볼까요?',
                  '하루 한 줄 기록이 습관을 만듭니다. 오늘도 출석 고고 🙌',
                ],
              ),

              const SizedBox(height: 12),

              // 동기부여 알림 설정 영역
              _buildNotificationCard(
                title: '동기부여 알림',
                emoji: '⏱',
                description: '매일 설정한 시간에, 절약 시간과 소비 피드백을 전달해드려요!',
                purpose: '소비 패턴과 플랜 도달 시간을 계산해, 사용자에게 동기를 줄 수 있는 실천 목표를 제안합니다.',
                enabled: _motivationEnabled,
                onToggle: (value) => setState(() => _motivationEnabled = value),
                timeEnabled: _motivationEnabled,
                selectedTime: _motivationTime,
                onTimeChanged: (time) => setState(() => _motivationTime = time),
                examples: [
                  '이번 주 절약한 시간: 총 3시간 20분 ⏱',
                  '식비 지출이 많았어요! 이번 주는 도시락 한번 도전해보는 건 어때요? 🍱',
                  '목표까지 4시간 남았어요. 오늘도 소비 통제 파이팅 💪',
                ],
              ),

              const SizedBox(height: 24),

              // 주간 알림 섹션
              const Text(
                '주간 알림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // 주간 소비 리포트 알림 영역
              _buildWeeklyReportCard(
                title: '소비통계레포트',
                emoji: '📊',
                description: '매주 일요일 저녁, 소비 패턴을 분석해 알려드려요.',
                purpose: '한 주 동안의 소비 데이터를 바탕으로, 반복된 습관이나 특이 패턴을 정리해드립니다.',
                enabled: _weeklyReportEnabled,
                onToggle: (value) =>
                    setState(() => _weeklyReportEnabled = value),
                examples: [
                  '이번 주 \'배달🍕\'에 가장 많이 쓰셨어요! 반복된 습관일까요?',
                  '무지출일이 1일 있었어요! 다음 주는 2일 도전 어때요? 🔒',
                  '이번 주 총 소비는 184,500원! 지난 주보다 12% 줄었어요 🎉',
                ],
              ),

              const SizedBox(height: 12),

              // 감정 분석 리포트 알림 영역
              _buildWeeklyReportCard(
                title: '감정 분석 레포트',
                emoji: '💬',
                description: '매주 일요일 저녁, 소비일지의 감정 기록을 분석해드립니다.',
                purpose: '소비에 기록된 감정과 소비일지를 바탕으로, 소비와 감정의 흐름을 사용자에게 알려드립니다.',
                enabled: _emotionReportEnabled,
                onToggle: (value) =>
                    setState(() => _emotionReportEnabled = value),
                examples: [
                  '이번 주 \'짜증😤\'과 쇼핑이 자주 함께 있었어요. 감정 소비 조심해볼까요?',
                  '\'기쁨😊\'이 많은 날, 소비도 안정적이었어요!',
                  '\'불안\'한 날엔 식비 지출이 많았어요. 감정에 끌린 소비였을 수도 있어요 😟',
                ],
              ),

              const SizedBox(height: 20),

              // 하단 안내 문구
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppBorderRadius.card,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '알림 안내',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '설정한 시간에 맞춰 푸시 알림이 발송됩니다.\n모든 알림은 알림 센터에서도 확인하실 수 있어요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Pretendard Variable',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String emoji,
    required String description,
    required String purpose,
    required bool enabled,
    required Function(bool) onToggle,
    required bool timeEnabled,
    required TimeOfDay selectedTime,
    required Function(TimeOfDay) onTimeChanged,
    required List<String> examples,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.card,
        border: Border.all(
          color: enabled ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 스위치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                  color: Colors.black,
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: const Color(0xFF2563EB),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (!enabled) ...[
            // 알림 설정 전 안내 문구
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$emoji ', style: const TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ', style: const TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    '목적',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                purpose,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Pretendard Variable',
                  height: 1.4,
                ),
              ),
            ),
          ] else ...[
            // 시간 설정
            Row(
              children: [
                Text(
                  '시간 설정: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay?
                    picked = await showCupertinoModalPopup<TimeOfDay>(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppBorderRadius.modalTop,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppBorderRadius.modalTop,
                                  border: const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        '취소',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontFamily: 'Pretendard Variable',
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '시간 선택',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Pretendard Variable',
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, selectedTime),
                                      child: const Text(
                                        '확인',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontFamily: 'Pretendard Variable',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.time,
                                  initialDateTime: DateTime(
                                    2024,
                                    1,
                                    1,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  ),
                                  onDateTimeChanged: (DateTime newDateTime) {
                                    setState(() {
                                      onTimeChanged(
                                        TimeOfDay.fromDateTime(newDateTime),
                                      );
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  use24hFormat: false,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    if (picked != null) {
                      onTimeChanged(picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: AppBorderRadius.button,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard Variable',
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 예시 메시지
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💬 ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    '예시 메시지',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...examples.map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '- $example',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontFamily: 'Pretendard Variable',
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyReportCard({
    required String title,
    required String emoji,
    required String description,
    required String purpose,
    required bool enabled,
    required Function(bool) onToggle,
    required List<String> examples,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.card,
        border: Border.all(
          color: enabled ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '매주 일요일 오후 8시',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ],
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: const Color(0xFF2563EB),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (!enabled) ...[
            // 알림 설정 전 안내 문구
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$emoji ', style: const TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ', style: const TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    '목적',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                purpose,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Pretendard Variable',
                  height: 1.4,
                ),
              ),
            ),
          ] else ...[
            // 예시 메시지
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💬 ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    '예시 메시지',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...examples.map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '- $example',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontFamily: 'Pretendard Variable',
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

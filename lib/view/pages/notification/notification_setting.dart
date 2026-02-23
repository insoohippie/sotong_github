import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../component/buttons/custom_button.dart';
import '../../../component/inputs/time_wheel_modal.dart';
import '../../../component/buttons/period_toggle.dart';
import '../../../component/theme/app_border_radius.dart';
import '../../../component/theme/app_colors.dart';
import '../../../model/notification/alarm.dart';
import '../../../view_model/setting/alarm_view_model.dart';

class NotificationSettingPage extends StatefulWidget {
  const NotificationSettingPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingPage> createState() =>
      _NotificationSettingPageState();
}

class _NotificationSettingPageState extends State<NotificationSettingPage> {
  // Design A (unused): "자세히" 펼침
  final List<bool> _expandedPurposeA = [false, false, false, false];
  bool _expandedGuideC = false;

  // 출석 알림 설정
  bool _attendanceEnabled = false;
  TimeOfDay _attendanceTime = const TimeOfDay(hour: 9, minute: 0);

  // 동기부여 알림 설정
  bool _motivationEnabled = false;
  TimeOfDay _motivationTime = const TimeOfDay(hour: 18, minute: 0);

  // 주간 리포트 알림 설정
  bool _weeklyReportEnabled = false;
  bool _emotionReportEnabled = false;

  // 일간 / 주간 토글 (일간: 데일리 알림만, 주간: 주간 알림만)
  String _alertRange = '일간';

  static const _sectionTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard Variable',
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 앱바 밑: 일간 / 주간 토글 (오른쪽 정렬)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TwoOptionToggle(
                    labels: const ['일간', '주간'],
                    selected: _alertRange,
                    onChanged: (value) => setState(() => _alertRange = value),
                    width: 100,
                    height: 30,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: _buildDesignB(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNotice(),
    );
  }

  /// 시간 선택: C 배치(한 줄) + B 스타일(회색 칩)
  Widget _buildTimeSelector(
      BuildContext context,
      TimeOfDay selectedTime,
      void Function(TimeOfDay) onTimeChanged,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chipBg = isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6);
    final chipText = isDark ? AppColors.darkText : Colors.black87;
    final onTap = () => _showTimePicker(context, selectedTime, onTimeChanged);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  '알림 시간',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedTime.format(context),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: chipText,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignA() {
    final isDaily = _alertRange == '일간';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDaily) ...[
          const Text('일간 알림', style: _sectionTitleStyle),
          const SizedBox(height: 8),
          _cardA(
            index: 0,
            title: '출석알림',
            oneLine: '매일 정해진 시간에 소비 기록 리마인드',
            purpose: '소비 기록 습관을 만들 수 있도록, 정해진 시간에 푸시로 리마인드해드립니다.',
            enabled: _attendanceEnabled,
            onToggle: (v) => setState(() => _attendanceEnabled = v),
            isDaily: true,
            selectedTime: _attendanceTime,
            onTimeChanged: (t) => setState(() => _attendanceTime = t),
          ),
          const SizedBox(height: 8),
          _cardA(
            index: 1,
            title: '동기부여 알림',
            oneLine: '매일 절약 시간·소비 피드백 전달',
            purpose: '소비 패턴과 플랜 도달 시간을 계산해, 실천 목표를 제안합니다.',
            enabled: _motivationEnabled,
            onToggle: (v) => setState(() => _motivationEnabled = v),
            isDaily: true,
            selectedTime: _motivationTime,
            onTimeChanged: (t) => setState(() => _motivationTime = t),
          ),
        ] else ...[
          const Text('주간 알림', style: _sectionTitleStyle),
          const SizedBox(height: 8),
          _cardA(
            index: 2,
            title: '소비통계레포트',
            oneLine: '매주 일요일 저녁, 소비 패턴 분석',
            purpose: '한 주 소비 데이터로 반복 습관·특이 패턴을 정리해드립니다.',
            enabled: _weeklyReportEnabled,
            onToggle: (v) => setState(() => _weeklyReportEnabled = v),
            isDaily: false,
          ),
          const SizedBox(height: 8),
          _cardA(
            index: 3,
            title: '감정 분석 레포트',
            oneLine: '매주 일요일 저녁, 소비일지 감정 분석',
            purpose: '소비에 기록된 감정과 소비일지를 바탕으로 소비·감정 흐름을 알려드립니다.',
            enabled: _emotionReportEnabled,
            onToggle: (v) => setState(() => _emotionReportEnabled = v),
            isDaily: false,
          ),
        ],
      ],
    );
  }

  Widget _cardA({
    required int index,
    required String title,
    required String oneLine,
    required String purpose,
    required bool enabled,
    required Function(bool) onToggle,
    required bool isDaily,
    TimeOfDay? selectedTime,
    Function(TimeOfDay)? onTimeChanged,
  }) {
    final expanded = _expandedPurposeA[index];
    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard Variable',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oneLine,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                    if (isDaily && enabled && selectedTime != null) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _showTimePicker(
                          context,
                          selectedTime!,
                          onTimeChanged!,
                        ),
                        child: Text(
                          '시간: ${selectedTime.format(context)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      ),
                    ],
                    if (!isDaily && enabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '매주 일요일 오후 8시',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      ),
                  ],
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
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expandedPurposeA[index] = !expanded),
            child: Row(
              children: [
                Text(
                  expanded ? '접기' : '자세히',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            Text(
              purpose,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontFamily: 'Pretendard Variable',
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesignB() {
    final isDaily = _alertRange == '일간';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDaily) ...[
          const SizedBox(height: 8),
          _cardB(
            index: 0,
            icon: Icons.touch_app,
            title: '출석알림',
            description: '매일 설정한 시간에 소비 기록을 도와드려요!',
            purpose: '소비 기록 습관을 만들 수 있도록, 정해진 시간에 푸시로 리마인드해드립니다.',
            enabled: _attendanceEnabled,
            onToggle: (v) => setState(() => _attendanceEnabled = v),
            isDaily: true,
            selectedTime: _attendanceTime,
            onTimeChanged: (t) => setState(() => _attendanceTime = t),
            examples: const [
              '오늘 소비를 기록하셨나요? 지금 입력해보세요!',
              '어제 소비를 깜빡하신 것 같아요! 지금 추가해볼까요?',
              '하루 한 줄 기록이 습관을 만듭니다. 오늘도 출석 고고 🙌',
            ],
          ),
          const SizedBox(height: 8),
          _cardB(
            index: 1,
            icon: Icons.schedule,
            title: '동기부여 알림',
            description: '매일 설정한 시간에 절약 시간과 소비 피드백을 전달해드려요!',
            purpose: '소비 패턴과 플랜 도달 시간을 계산해, 실천 목표를 제안합니다.',
            enabled: _motivationEnabled,
            onToggle: (v) => setState(() => _motivationEnabled = v),
            isDaily: true,
            selectedTime: _motivationTime,
            onTimeChanged: (t) => setState(() => _motivationTime = t),
            examples: const [
              '이번 주 절약한 시간: 총 3시간 20분 ⏱',
              '식비 지출이 많았어요! 이번 주는 도시락 한번 도전해보는 건 어때요? 🍱',
              '목표까지 4시간 남았어요. 오늘도 소비 통제 파이팅 💪',
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          _cardB(
            index: 2,
            icon: Icons.bar_chart,
            title: '소비통계레포트',
            description: '매주 일요일 저녁, 소비 패턴을 분석해 알려드려요.',
            purpose: '한 주 동안의 소비 데이터를 바탕으로 반복된 습관이나 특이 패턴을 정리해드립니다.',
            enabled: _weeklyReportEnabled,
            onToggle: (v) => setState(() => _weeklyReportEnabled = v),
            isDaily: false,
            examples: const [
              '이번 주 \'배달🍕\'에 가장 많이 쓰셨어요! 반복된 습관일까요?',
              '무지출일이 1일 있었어요! 다음 주는 2일 도전 어때요? 🔒',
              '이번 주 총 소비는 184,500원! 지난 주보다 12% 줄었어요 🎉',
            ],
          ),
          const SizedBox(height: 8),
          _cardB(
            index: 3,
            icon: Icons.chat_bubble_outline,
            title: '감정 분석 레포트',
            description: '매주 일요일 저녁, 소비일지의 감정 기록을 분석해드립니다.',
            purpose: '소비에 기록된 감정과 소비일지를 바탕으로 소비와 감정의 흐름을 알려드립니다.',
            enabled: _emotionReportEnabled,
            onToggle: (v) => setState(() => _emotionReportEnabled = v),
            isDaily: false,
            examples: const [
              '이번 주 \'짜증😤\'과 쇼핑이 자주 함께 있었어요. 감정 소비 조심해볼까요?',
              '\'기쁨😊\'이 많은 날, 소비도 안정적이었어요!',
              '\'불안\'한 날엔 식비 지출이 많았어요. 감정에 끌린 소비였을 수도 있어요 😟',
            ],
          ),
        ],
      ],
    );
  }

  Widget _cardB({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required String purpose,
    required bool enabled,
    required Function(bool) onToggle,
    required bool isDaily,
    required List<String> examples,
    TimeOfDay? selectedTime,
    Function(TimeOfDay)? onTimeChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppBorderRadius.card,
        border: Border.all(
          color: enabled ? AppColors.primary : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard Variable',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: Colors.white,
                activeTrackColor: isDark ? Colors.white.withOpacity(0.5) : null,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // OFF일 때: 설명만 그냥 표시
          if (!enabled) ...[
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Pretendard Variable',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              purpose,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Pretendard Variable',
                height: 1.4,
              ),
            ),
          ],
          // ON일 때: 시간(한 줄 + 회색 칩) + 예시 메시지
          if (enabled) ...[
            if (isDaily && selectedTime != null && onTimeChanged != null)
              _buildTimeSelector(context, selectedTime, onTimeChanged),
            if (!isDaily)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '매주 일요일 오후 8시',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
            if (examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '예시 메시지',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              const SizedBox(height: 6),
              ...examples.map(
                    (example) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $example',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDesignC() {
    final isDaily = _alertRange == '일간';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDaily) ...[
          const Text('일간 알림', style: _sectionTitleStyle),
          const SizedBox(height: 8),
          _cardC(
            title: '출석알림',
            oneLine: '매일 정해진 시간에 소비 기록 리마인드',
            enabled: _attendanceEnabled,
            onToggle: (v) => setState(() => _attendanceEnabled = v),
            isDaily: true,
            selectedTime: _attendanceTime,
            onTimeChanged: (t) => setState(() => _attendanceTime = t),
          ),
          const SizedBox(height: 6),
          _cardC(
            title: '동기부여 알림',
            oneLine: '매일 절약 시간·소비 피드백 전달',
            enabled: _motivationEnabled,
            onToggle: (v) => setState(() => _motivationEnabled = v),
            isDaily: true,
            selectedTime: _motivationTime,
            onTimeChanged: (t) => setState(() => _motivationTime = t),
          ),
        ] else ...[
          const Text('주간 알림', style: _sectionTitleStyle),
          const SizedBox(height: 8),
          _cardC(
            title: '소비통계레포트',
            oneLine: '매주 일요일 저녁, 소비 패턴 분석',
            enabled: _weeklyReportEnabled,
            onToggle: (v) => setState(() => _weeklyReportEnabled = v),
            isDaily: false,
          ),
          const SizedBox(height: 6),
          _cardC(
            title: '감정 분석 레포트',
            oneLine: '매주 일요일 저녁, 감정 기록 분석',
            enabled: _emotionReportEnabled,
            onToggle: (v) => setState(() => _emotionReportEnabled = v),
            isDaily: false,
          ),
        ],
        const SizedBox(height: 16),
        // 알림 설정 가이드 (펼침)
        GestureDetector(
          onTap: () => setState(() => _expandedGuideC = !_expandedGuideC),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: AppBorderRadius.card,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '알림 설정 가이드',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard Variable',
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  _expandedGuideC
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 22,
                  color: Colors.grey[700],
                ),
              ],
            ),
          ),
        ),
        if (_expandedGuideC) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppBorderRadius.card,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isDaily
                  ? [
                _guideRow(
                  '출석알림',
                  '소비 기록 습관을 만들 수 있도록, 정해진 시간에 푸시로 리마인드해드립니다.',
                ),
                const SizedBox(height: 10),
                _guideRow(
                  '동기부여 알림',
                  '소비 패턴과 플랜 도달 시간을 계산해, 실천 목표를 제안합니다.',
                ),
              ]
                  : [
                _guideRow('소비통계레포트', '한 주 소비 데이터로 반복 습관·특이 패턴을 정리해드립니다.'),
                const SizedBox(height: 10),
                _guideRow(
                  '감정 분석 레포트',
                  '소비·감정 기록을 바탕으로 소비와 감정의 흐름을 알려드립니다.',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _guideRow(String title, String purpose) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard Variable',
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          purpose,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontFamily: 'Pretendard Variable',
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _cardC({
    required String title,
    required String oneLine,
    required bool enabled,
    required Function(bool) onToggle,
    required bool isDaily,
    TimeOfDay? selectedTime,
    Function(TimeOfDay)? onTimeChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.card,
        border: Border.all(
          color: enabled ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard Variable',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  oneLine,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
                if (isDaily && enabled && selectedTime != null)
                  GestureDetector(
                    onTap: () =>
                        _showTimePicker(context, selectedTime!, onTimeChanged!),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '시간: ${selectedTime.format(context)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                    ),
                  ),
                if (!isDaily && enabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '매주 일요일 오후 8시',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
              ],
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
    );
  }

  /// 네비게이션 바용 알림 안내 (테두리 없음)
  Widget _buildBottomNotice() {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
        color: theme.scaffoldBackgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '알림 안내',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '설정한 시간에 맞춰 푸시 알림이 발송됩니다.\n모든 알림은 알림 센터에서도 확인하실 수 있어요.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Pretendard Variable',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(
      BuildContext context,
      TimeOfDay current,
      Function(TimeOfDay) onTimeChanged,
      ) async {
    final picked = await TimeWheelModal.show(context, current);
    if (picked != null && mounted) setState(() => onTimeChanged(picked));
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
      padding: const EdgeInsets.all(16),
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
                  fontSize: 13,
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

          const SizedBox(height: 8),

          if (!enabled) ...[
            // 알림 설정 전 안내 문구
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$emoji ', style: const TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ', style: const TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    '목적',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                purpose,
                style: TextStyle(
                  fontSize: 11,
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
                    fontSize: 13,
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
                                        fontSize: 13,
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
                                  backgroundColor: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
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
                            fontSize: 13,
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

            const SizedBox(height: 12),

            // 예시 메시지
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💬 ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    '예시 메시지',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...examples.map(
                  (example) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '- $example',
                  style: const TextStyle(
                    fontSize: 11,
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
      padding: const EdgeInsets.all(16),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '매주 일요일 오후 8시',
                    style: TextStyle(
                      fontSize: 11,
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

          const SizedBox(height: 8),

          if (!enabled) ...[
            // 알림 설정 전 안내 문구
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$emoji ', style: const TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ', style: const TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    '목적',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                purpose,
                style: TextStyle(
                  fontSize: 11,
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
                const Text('💬 ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Text(
                    '예시 메시지',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...examples.map(
                  (example) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '- $example',
                  style: const TextStyle(
                    fontSize: 11,
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

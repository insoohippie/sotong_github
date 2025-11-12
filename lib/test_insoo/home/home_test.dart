import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/header_text.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/appbars/custom_app_bar_home.dart';
import 'package:sotong_local/component/buttons/small_rounded_button.dart';
import 'package:sotong_local/component/containers/rounded_info_container.dart';

import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/theme/app_spacing.dart';
import 'package:sotong_local/component/chart/half_donut_chart.dart';

class HomeTestPage extends StatefulWidget {
  const HomeTestPage({super.key});

  @override
  State<HomeTestPage> createState() => _HomeTestPageState();
}

class _HomeTestPageState extends State<HomeTestPage> {
  // Test data
  String _userName = '테스트 사용자';
  String _planName = '테스트 플랜';
  final double _savingPerSec = 50.5;
  final double _currentRate = 0.65;
  final double _baseRate = 0.50;
  String _fixedSpending = '7,000원';

  // Live saving amount (simulated)
  double _liveSavedAmount = 345132.0;

  // D-Day 텍스트 (목표일까지 남은 일수)
  String get _dDayText {
    if (_goalDate == null) {
      return '';
    }
    final now = DateTime.now();
    final remainingDays = _goalDate!.difference(now).inDays;
    return 'D-${remainingDays.abs()}';
  }

  // 플랜 날짜 데이터 (테스트용)
  final DateTime _planStartDate = DateTime.now().subtract(
    const Duration(days: 28),
  );
  final DateTime? _goalDate = DateTime.now().add(const Duration(days: 52));

  // Selected date
  DateTime _selectedDate = DateTime.now();

  // Simulated spending data (date -> amount)
  final Map<String, double> _spendingData = {
    '${DateTime.now().month}/${DateTime.now().day}':
        10000.0, // 현재 날짜: 10,000원 (한도 초과)
    '11/2': 20000.0, // 11월 2일: 20,000원 (한도 초과)
    '11/3': 5000.0, // 11월 3일: 5,000원 (한도 미만)
  };

  @override
  void initState() {
    super.initState();
    // Simulate live updates every second
    _startLiveUpdates();
  }

  void _startLiveUpdates() {
    // Simulate live saving amount updates
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _liveSavedAmount += _savingPerSec;
        });
        _startLiveUpdates();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _getSpendingForDate(DateTime date) {
    final key = '${date.month}/${date.day}';
    final amount = _spendingData[key] ?? 0.0;
    return '${amount.toStringAsFixed(0)}원';
  }

  // 금액 문자열에서 숫자 추출
  double _parseAmount(String amountStr) {
    final cleaned = amountStr.replaceAll(RegExp(r'[원,\s]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // 한도 금액 숫자 추출
  double get _dailyLimitAmount {
    return _parseAmount(_fixedSpending);
  }

  // 실제 사용 금액 숫자 추출
  double _getActualSpentAmount(DateTime date) {
    final key = '${date.month}/${date.day}';
    return _spendingData[key] ?? 0.0;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  // 반원 그래프 빌드 메서드
  Widget _buildHalfDonutChart() {
    if (_goalDate == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final remainingDays = _goalDate!.difference(now).inDays;
    final totalDays = _goalDate!.difference(_planStartDate).inDays;

    // 진행률 계산 (0-100)
    final elapsedDays = now.difference(_planStartDate).inDays;
    final progressPercentage = totalDays > 0
        ? ((elapsedDays / totalDays) * 100).round().clamp(0, 100)
        : 0;

    // 목표 금액 달성률 (예: 현재 저축액 / 목표 금액)
    // 테스트용 목표 금액 설정
    final targetAmount = 5000000.0; // 500만원
    final achievementPercentage = targetAmount > 0
        ? ((_liveSavedAmount / targetAmount) * 100).round().clamp(0, 100)
        : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 모인 금액 텍스트 (왼쪽 정렬)
        ParagraphText(text: '모인 금액', fontWeight: FontWeight.bold),
        SizedBox(height: AppSpacing.fieldSpacing),
        // 금액 표시 (큰 크기, 파란색)
        Text(
          _liveSavedAmount
                  .toStringAsFixed(0)
                  .replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  ) +
              '원',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: AppSpacing.sectionSpacing2),
        // 반원 그래프 (중앙 정렬)
        Center(
          child: HalfDonutChart(
            outerProgress: 100, // 외부는 항상 100%
            innerProgress: progressPercentage, // 내부는 진행률
            state: true, // 파란색
            width: 300, // 크기 증가
            height: 180, // 크기 증가
            showLegend: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = _formatDate(_selectedDate);
    final todaySpending = _getSpendingForDate(_selectedDate);
    final bool hasSpendingRecord = todaySpending != '0원';

    // 금액 비교
    final actualSpent = _getActualSpentAmount(_selectedDate);
    final dailyLimit = _dailyLimitAmount;
    final isOverLimit = actualSpent > dailyLimit;

    // 배경색과 실제 사용 금액 텍스트 색상 결정
    final containerBackgroundColor = !hasSpendingRecord
        ? Colors.grey[200]! // 라이트그레이 (기록 없음)
        : isOverLimit
        ? const Color(0xFFFFEFEF) // 분홍색 (한도 초과)
        : const Color(0xFFEFF5FF); // 연한 파란색 (한도 미만/동일)

    final actualSpentTextColor = isOverLimit
        ? const Color(0xFFFF5F5F) // 빨간색 (한도 초과)
        : const Color(0xFF0062FF); // 파란색 (한도 미만/동일)

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
            CustomAppBarHome(
              text: '$_userName 님',
              unreadCount: 3,
              onNotifications: () =>
                  Navigator.pushNamed(context, '/notification'),
              onSettings: () => Navigator.pushNamed(context, '/setting'),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RoundedInfoContainer(
                        backgroundColor: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 플랜 이름과 D-Day를 나란히 배치
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.planTagBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ParagraphText(
                                        text: _planName,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () async {
                                          // Test: Show a simple dialog instead of the actual modal
                                          final controller =
                                              TextEditingController(
                                                text: _planName,
                                              );
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('플랜 이름 수정'),
                                              content: TextField(
                                                controller: controller,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: '플랜 이름을 입력하세요',
                                                    ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('취소'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    if (controller
                                                        .text
                                                        .isNotEmpty) {
                                                      setState(() {
                                                        _planName =
                                                            controller.text;
                                                      });
                                                    }
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('저장'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // D-Day 표시
                                ParagraphText(
                                  text: _dDayText,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.fieldSpacing),
                            // 반원 그래프 (안에 금액 포함)
                            _buildHalfDonutChart(),
                            SizedBox(height: AppSpacing.sectionSpacing2),
                            SubText(
                              text: '1초씩 $_savingPerSec원이 증가해요',
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.fieldSpacing),
                      RoundedInfoContainer(
                        backgroundColor: containerBackgroundColor,
                        padding: 20,
                        child: Column(
                          crossAxisAlignment: hasSpendingRecord
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ParagraphText(
                                      text: displayDate,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const SizedBox(width: 8),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/add_income_edit',
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        onTap: () => _changeDate(-1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.chevron_left,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        onTap: () => _changeDate(1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.chevron_right,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.fieldSpacing),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!hasSpendingRecord) ...[
                                  SmallRoundedButton(
                                    text: "소비 기록하러 가기",
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/record_spending',
                                      );
                                    },
                                  ),
                                ] else ...[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/today_spending',
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            // 실제 사용 금액 (조건부 색상)
                                            Text(
                                              todaySpending,
                                              style: TextStyle(
                                                color: actualSpentTextColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              ' / ',
                                              style: TextStyle(
                                                color: AppColors.text,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            // 한도 금액 (검은색)
                                            Text(
                                              _fixedSpending,
                                              style: TextStyle(
                                                color: AppColors.text,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 롤링 숫자 애니메이션 위젯 (자릿수별로 롤링 효과)
class _RollingNumberWidget extends StatefulWidget {
  final double value;
  final double? fontSize;
  final Color? color;

  const _RollingNumberWidget({required this.value, this.fontSize, this.color});

  @override
  State<_RollingNumberWidget> createState() => _RollingNumberWidgetState();
}

class _RollingNumberWidgetState extends State<_RollingNumberWidget>
    with TickerProviderStateMixin {
  List<AnimationController> _controllers = [];
  List<Animation<double>> _animations = [];
  List<int> _previousDigits = [];
  List<int> _currentDigits = [];

  @override
  void initState() {
    super.initState();
    _initializeDigits(widget.value.toInt());
  }

  void _initializeDigits(int value) {
    // 숫자를 문자열로 변환하고 각 자릿수 추출
    final valueStr = value.toString();
    _currentDigits = valueStr.split('').map((e) => int.parse(e)).toList();
    _previousDigits = List.from(_currentDigits);

    // 각 자릿수마다 애니메이션 컨트롤러 생성
    _controllers = List.generate(
      _currentDigits.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(_RollingNumberWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newValue = widget.value.toInt();
      final newValueStr = newValue.toString();
      final newDigits = newValueStr.split('').map((e) => int.parse(e)).toList();

      // 자릿수가 변경되면 재초기화
      if (newDigits.length != _currentDigits.length) {
        for (var controller in _controllers) {
          controller.dispose();
        }
        _initializeDigits(newValue);
      } else {
        _previousDigits = List.from(_currentDigits);
        _currentDigits = newDigits;

        // 각 자릿수별로 애니메이션 실행
        for (int i = 0; i < _currentDigits.length; i++) {
          if (_previousDigits[i] != _currentDigits[i]) {
            final diff = _currentDigits[i] - _previousDigits[i];
            // 자릿수 롤오버 고려 (예: 9 -> 0은 -9가 아니라 +1로 처리)
            final normalizedDiff = diff < 0 ? diff + 10 : diff;

            _animations[i] =
                Tween<double>(
                  begin: _previousDigits[i].toDouble(),
                  end:
                      _currentDigits[i].toDouble() +
                      (normalizedDiff > 5 ? -10 : 0).toDouble(),
                ).animate(
                  CurvedAnimation(
                    parent: _controllers[i],
                    curve: Curves.easeOutCubic,
                  ),
                );

            _controllers[i].reset();
            _controllers[i].forward();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _formatAmount(widget.value.toInt());

    // 각 자릿수를 개별적으로 애니메이션 처리하여 표시
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      textBaseline: TextBaseline.alphabetic,
      children: formattedAmount.split('').asMap().entries.map((entry) {
        final index = entry.key;
        final char = entry.value;

        // 숫자인 경우에만 애니메이션 적용
        if (RegExp(r'[0-9]').hasMatch(char)) {
          // 현재 위치까지의 숫자 개수를 세어 인덱스 계산
          final digitIndex = formattedAmount
              .substring(0, index)
              .replaceAll(RegExp(r'[^0-9]'), '')
              .length;

          if (digitIndex < _animations.length &&
              digitIndex < _currentDigits.length) {
            return AnimatedBuilder(
              animation: _animations[digitIndex],
              builder: (context, child) {
                final animatedValue = _animations[digitIndex].value;
                final displayDigit = (animatedValue.round() % 10).abs();
                return Text(
                  displayDigit.toString(),
                  style: TextStyle(
                    fontSize: widget.fontSize ?? 24,
                    fontWeight: FontWeight.bold,
                    color: widget.color ?? Colors.black,
                  ),
                );
              },
            );
          }
        }

        // 숫자가 아닌 문자 (콤마, 원 등)는 그대로 표시
        return Text(
          char,
          style: TextStyle(
            fontSize: widget.fontSize ?? 24,
            fontWeight: FontWeight.bold,
            color: widget.color ?? Colors.black,
          ),
        );
      }).toList(),
    );
  }
}

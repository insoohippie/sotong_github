import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/texts/paragraph_text.dart';
import '../../../component/appbars/custom_app_bar_home.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/chart/semi_gauge_chart.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import '../../../view_model/home/home_view_model.dart';
import '../../../view_model/services/saving_calculator.dart';
import 'home_widgets/plan_name_edit_widget.dart';

/// 반원 테두리 그리기 (ClipPath 밖에 그리기)
class SemiCircleBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 반원 호 그리기
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.width),
      math.pi, // 180도 (왼쪽에서 시작)
      math.pi, // 180도 (반원)
      false,
      paint,
    );

    // 하단 직경 테두리 선
    canvas.drawLine(
      Offset(0, size.height), // 왼쪽 하단
      Offset(size.width, size.height), // 오른쪽 하단
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 반원 클리퍼 (반원 모양으로 자르기)
class SemiCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // 반원 그리기: 하단 직경을 기준으로 위쪽 반원
    path.moveTo(0, size.height); // 왼쪽 하단
    path.lineTo(size.width, size.height); // 오른쪽 하단
    // 반원 호 그리기 (하단에서 시작해서 위쪽으로)
    path.addArc(
      Rect.fromLTWH(0, 0, size.width, size.width),
      math.pi, // 180도 (왼쪽에서 시작)
      math.pi, // 180도 (반원)
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HomeCopyPage extends StatefulWidget {
  const HomeCopyPage({super.key});

  @override
  State<HomeCopyPage> createState() => _HomeCopyPageState();
}

class _HomeCopyPageState extends State<HomeCopyPage>
    with TickerProviderStateMixin {
  // 중앙 컨테이너 모드: 'saving' (저축 정보) 또는 'alarm' (알람 설정)
  String _centerMode = 'saving';
  // 플랜 그래프 퍼센트 (0~100)
  int _planProgressPercent = 60;
  // 사용자 그래프 퍼센트 (0~100)
  int _userProgressPercent = 40;
  // 입력 컨트롤러
  final TextEditingController _planProgressController = TextEditingController();
  final TextEditingController _userProgressController = TextEditingController();

  // 모달 내부 진행률 바용 (기존 코드 호환성)
  int _inputProgressPercent = 0;
  int _appliedProgressPercent = 0;
  final TextEditingController _progressInputController =
      TextEditingController();
  // 노란색 기준선 입력 퍼센트 (0~100)
  int _inputYellowLinePercent = 40;
  // 노란색 기준선에 적용된 퍼센트
  int _appliedYellowLinePercent = 40;
  // 노란색 기준선 입력 컨트롤러
  final TextEditingController _yellowLineInputController =
      TextEditingController();

  // 클릭된 섹션 관리 ('plan': 플랜 그래프, 'user': 사용자 그래프, null: 팝업 없음)
  String? _clickedSection;

  // 레이아웃 애니메이션용
  late AnimationController _greenAnimationController;
  late AnimationController _blueAnimationController;
  late Animation<double> _greenAnimation;
  late Animation<double> _blueAnimation;

  // 알람 시간 리스트 (테스트용, 나중에 저장소에서 불러오기)
  List<int> _alarmHours = [8, 18]; // 오전 8시, 오후 6시

  // 모달 관련
  bool _showCountdownModal = false;
  late AnimationController _modalController;
  late Animation<Offset> _modalSlideAnimation;
  late Animation<double> _modalScrimFade;

  @override
  void initState() {
    super.initState();

    // 레이아웃 애니메이션 초기화
    // 초록색 애니메이션 (먼저 시작)
    _greenAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 하드코딩: 초록색 0% ~ 40% 구간 (0.0 → 1.0으로 정규화)
    _greenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _greenAnimationController, curve: Curves.easeOut),
    );

    // 파란색 애니메이션 (초록색과 동시에 시작)
    _blueAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 하드코딩: 파란색 40% ~ 65% 구간 (0.0 → 1.0으로 정규화)
    _blueAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blueAnimationController, curve: Curves.easeOut),
    );

    // 초록색 애니메이션 리스너
    _greenAnimationController.addListener(() {
      setState(() {});
    });

    // 초록색 애니메이션 완료 시 파란색 애니메이션 시작
    _greenAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blueAnimationController.forward();
      }
    });

    // 파란색 애니메이션 리스너
    _blueAnimationController.addListener(() {
      setState(() {});
    });

    // 초기 로드 시 초록색 애니메이션만 시작 (파란색은 초록색 완료 후 시작)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _greenAnimationController.forward();
    });

    // 로그인 없이도 작동하도록 load() 호출 제거
    // Future.microtask(() {
    //   context.read<HomeViewModel>().load();
    // });

    // 노란색 기준선 입력칸 초기값 설정
    _yellowLineInputController.text = _appliedYellowLinePercent.toString();
    // 플랜/사용자 그래프 입력칸 초기값 설정
    _planProgressController.text = _planProgressPercent.toString();
    _userProgressController.text = _userProgressPercent.toString();

    // 모달 애니메이션 초기화
    _modalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 500),
    );

    _modalSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1), // 아래서 시작
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _modalController, curve: Curves.easeOutCubic),
        );

    _modalScrimFade = CurvedAnimation(
      parent: _modalController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _modalController.dispose();
    _greenAnimationController.dispose();
    _blueAnimationController.dispose();
    _planProgressController.dispose();
    _userProgressController.dispose();
    _progressInputController.dispose();
    _yellowLineInputController.dispose();
    super.dispose();
  }

  // 소비 입력 컨테이너에서 날짜 관련 함수
  DateTime _selectedDate = DateTime.now(); // 오늘 날짜

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    context.read<HomeViewModel>().loadDailySpending(_selectedDate);
  }

  /// D-Day 표시
  String _buildDDayText(HomeViewModel vm) {
    final remain = vm.liveRemaining;
    if (remain == null) return '목표일 없음';
    if (remain.isNegative) return 'D-Day 달성';
    return 'D-${remain.inDays}';
  }

  /// 플랜/사용자 그래프 입력 컨테이너
  Widget _buildProgressInputContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // 플랜 그래프 입력
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '플랜 그래프',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _planProgressController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '퍼센트',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF0062FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (value) {
                    final num = int.tryParse(value);
                    if (num != null) {
                      setState(() {
                        _planProgressPercent = num.clamp(0, 100);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 사용자 그래프 입력
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '사용자 그래프',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _userProgressController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '퍼센트',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF7DAFFF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (value) {
                    final num = int.tryParse(value);
                    if (num != null) {
                      setState(() {
                        _userProgressPercent = num.clamp(0, 100);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 적용하기 버튼
          SizedBox(
            width: 80,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  // 애니메이션 재시작
                  _greenAnimationController.reset();
                  _blueAnimationController.reset();
                  _greenAnimationController.forward();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0062FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '적용',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 차트 빌드 (동적 퍼센트 사용)
  Widget _buildChart(HomeViewModel vm) {
    // 입력된 퍼센트를 0.0~1.0 범위로 변환
    final userProgress = _userProgressPercent / 100.0;
    final planProgress = _planProgressPercent / 100.0;

    // 두 수치가 같으면 차트 표시 안 함
    if (_userProgressPercent == _planProgressPercent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                size: const Size(300, 300),
                painter: SemiGaugePainter(
                  progress: 1.0,
                  backgroundColor: const Color(0xFFF1F1F1),
                  progressColorStart: const Color(0xFFF1F1F1),
                  progressColorEnd: const Color(0xFFF1F1F1),
                  strokeWidth: 22,
                  isFullCircle: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '플랜 그래프와 사용자 그래프 수치가 같습니다',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 두 수치 중 작은 것이 기점
    final minProgress = userProgress < planProgress
        ? userProgress
        : planProgress;
    final maxProgress = userProgress > planProgress
        ? userProgress
        : planProgress;

    // 어떤 그래프가 더 큰지 판단
    final isUserLarger = userProgress > planProgress;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 중복 원형 게이지 (같은 크기에 3개 레이어)
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 배경 회색 원차트 (가장 아래, 전체) - 모든 섹션의 기본 배경
                CustomPaint(
                  size: const Size(300, 300),
                  painter: SemiGaugePainter(
                    progress: 1.0, // 전체 배경
                    backgroundColor: const Color(0xFFF1F1F1),
                    progressColorStart: const Color(0xFFF1F1F1),
                    progressColorEnd: const Color(0xFFF1F1F1),
                    strokeWidth: 22, // 다른 차트와 동일한 두께
                    isFullCircle: true,
                  ),
                ),
                // 차트 2 (중간) - 기점부터 큰 수치까지 (실선)
                CustomPaint(
                  size: const Size(300, 300),
                  painter: SemiGaugePainter(
                    startProgress: minProgress,
                    progress:
                        minProgress +
                        (_blueAnimation.value * (maxProgress - minProgress)),
                    backgroundColor: Colors.transparent,
                    progressColorStart: isUserLarger
                        ? const Color(0xFF7DAFFF) // 사용자가 크면 연한 파랑
                        : const Color(0xFF0062FF), // 플랜이 크면 진한 파랑
                    progressColorEnd: isUserLarger
                        ? const Color(0xFF7DAFFF)
                        : const Color(0xFF0062FF),
                    strokeWidth: 22,
                    isFullCircle: true,
                    isDashed: false, // 실선
                  ),
                ),
                // 차트 1 (가장 위) - 0부터 기점까지 (점선)
                CustomPaint(
                  size: const Size(300, 300),
                  painter: SemiGaugePainter(
                    startProgress: 0.0,
                    progress: _greenAnimation.value * minProgress,
                    backgroundColor: Colors.transparent,
                    progressColorStart: isUserLarger
                        ? const Color(0xFF0062FF) // 사용자가 크면 진한 파랑
                        : const Color(0xFF7DAFFF), // 플랜이 크면 연한 파랑
                    progressColorEnd: isUserLarger
                        ? const Color(0xFF0062FF)
                        : const Color(0xFF7DAFFF),
                    strokeWidth: 22,
                    isFullCircle: true,
                    isDashed: true, // 점선
                    dashWidth: 12.0,
                    dashGap: 6.0,
                  ),
                ),
                // 전체 게이지를 감싸는 GestureDetector (클릭 위치에 따라 구역 판단)
                GestureDetector(
                  onTapDown: (details) {
                    // 클릭 위치를 상대 좌표로 변환
                    final size = const Size(300, 300);
                    final center = Offset(size.width / 2, size.height / 2);
                    final localPosition = details.localPosition;

                    // 원의 중심으로부터의 거리 계산
                    final dx = localPosition.dx - center.dx;
                    final dy = localPosition.dy - center.dy;
                    final distance = math.sqrt(dx * dx + dy * dy);

                    // 원의 반지름 (게이지의 중간 지점)
                    final radius = size.width / 2;
                    final strokeWidth = 22.0;
                    final innerRadius = radius - strokeWidth / 2;
                    final outerRadius = radius + strokeWidth / 2;

                    // 클릭이 게이지 영역 내에 있는지 확인
                    if (distance < innerRadius || distance > outerRadius) {
                      // 게이지 영역 밖이면 클릭 무시
                      return;
                    }

                    // 각도 계산 (atan2는 -π ~ π 범위)
                    double angle = math.atan2(dy, dx);

                    // 원형 게이지는 12시 방향(-π/2)부터 시작하므로 각도 정규화
                    // -π/2를 0으로 만들고, 음수 각도를 양수로 변환
                    angle = angle + math.pi / 2;
                    if (angle < 0) {
                      angle = angle + 2 * math.pi;
                    }

                    // 각도를 0.0 ~ 1.0 범위로 정규화
                    final normalizedProgress = angle / (2 * math.pi);

                    // 어느 구역인지 판단
                    String? clickedSection;
                    if (normalizedProgress >= 0.0 &&
                        normalizedProgress < minProgress) {
                      // 0~기점 구역
                      clickedSection = isUserLarger ? 'plan' : 'user';
                    } else if (normalizedProgress >= minProgress &&
                        normalizedProgress < maxProgress) {
                      // 기점~큰 수치 구역
                      clickedSection = isUserLarger ? 'user' : 'plan';
                    }

                    setState(() {
                      if (clickedSection != null) {
                        // 같은 구역을 다시 클릭하면 닫기, 다른 구역을 클릭하면 전환
                        _clickedSection = _clickedSection == clickedSection
                            ? null
                            : clickedSection;
                      }
                    });
                  },
                  child: Container(
                    width: 300,
                    height: 300,
                    color: Colors.transparent, // 투명한 영역으로 클릭 감지
                  ),
                ),
                // 중앙 원형 버튼 (클릭 상태에 따라 색상과 내용 변경)
                _buildCircularButton(vm),
              ],
            ),
          ),
          // 범례 (Legend)
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 플랜 그래프 (진한 파란색)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0062FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '플랜 그래프',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0062FF)),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // 사용자 그래프 (연한 파란색)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7DAFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '사용자 그래프',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7DAFFF)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 호버 팝업 위젯
  Widget _buildHoverPopup(HomeViewModel vm, String section) {
    final isPlan = section == 'plan';

    // 플랜 그래프 정보
    String title = '플랜 그래프';
    Color borderColor = const Color(0xFF0062FF);
    String targetAmountText = '0원';
    String targetProgressText = '55%';
    String goalDateText = '목표일 없음';
    String dailySavingText = '0원/일';
    String startDateText = '시작일 없음';

    // 사용자 그래프 정보
    if (!isPlan) {
      title = '${vm.name}님 그래프';
      borderColor = const Color(0xFF7DAFFF);
      targetAmountText = SavingPlanCalculator.formatAmount(vm.liveSavedAmount);
      targetProgressText = '40%';
      dailySavingText = '0원/일';
      goalDateText = '예상 완료일 없음';
      startDateText = '시작일 없음';
    }

    // 플랜 정보 계산
    if (isPlan && vm.latestPlan != null) {
      final plan = vm.latestPlan!;
      if (plan.targetAmount != null) {
        targetAmountText = SavingPlanCalculator.formatAmount(
          plan.targetAmount!.toDouble(),
        );
      }

      // 목표 진행률: 55%
      targetProgressText = '55%';

      // 목표일
      final remain = vm.liveRemaining;
      if (remain != null) {
        if (remain.isNegative) {
          goalDateText = 'D-Day 달성';
        } else {
          goalDateText = 'D-${remain.inDays}';
        }
      }

      // 일일 저축액
      if (vm.calc != null && vm.calc!.dailySaving > 0) {
        dailySavingText =
            '${SavingPlanCalculator.formatAmount(vm.calc!.dailySaving)}원/일';
      }

      // 시작일
      if (plan.startDate != null) {
        final date = plan.startDate!;
        startDateText =
            '${date.year.toString().substring(2)}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
      }
    }

    // 사용자 정보 계산
    if (!isPlan) {
      // 현재 모인 금액
      targetAmountText = SavingPlanCalculator.formatAmount(vm.liveSavedAmount);

      // 현재 진행률: 40%
      targetProgressText = '40%';

      // 실제 일일 저축액 (평균 계산)
      if (vm.latestPlan?.startDate != null && vm.liveSavedAmount > 0) {
        final startDate = vm.latestPlan!.startDate!;
        final daysElapsed = DateTime.now().difference(startDate).inDays;
        if (daysElapsed > 0) {
          final avgDailySaving = vm.liveSavedAmount / daysElapsed;
          dailySavingText =
              '${SavingPlanCalculator.formatAmount(avgDailySaving)}원/일';
        }
      }

      // 예상 완료일 계산 (실제 일일 저축액 기준)
      if (vm.latestPlan?.targetAmount != null &&
          vm.latestPlan?.startDate != null) {
        final targetAmount = vm.latestPlan!.targetAmount!.toDouble();
        final remaining = targetAmount - vm.liveSavedAmount;
        final startDate = vm.latestPlan!.startDate!;
        final daysElapsed = DateTime.now().difference(startDate).inDays;

        if (remaining > 0 && daysElapsed > 0 && vm.liveSavedAmount > 0) {
          // 실제 평균 일일 저축액 사용
          final avgDailySaving = vm.liveSavedAmount / daysElapsed;
          if (avgDailySaving > 0) {
            final daysToGoal = (remaining / avgDailySaving).ceil();
            final projectedDate = DateTime.now().add(
              Duration(days: daysToGoal),
            );
            goalDateText =
                '${projectedDate.year.toString().substring(2)}.${projectedDate.month.toString().padLeft(2, '0')}.${projectedDate.day.toString().padLeft(2, '0')}';

            // 플랜 대비 차이 계산
            if (vm.calc?.goalDateTime != null) {
              final planGoalDate = vm.calc!.goalDateTime!;
              final planTotalDays = planGoalDate.difference(startDate).inDays;
              final planProgress = daysElapsed / planTotalDays;
              final userProgress = (vm.liveSavedAmount / targetAmount);
              final diffDays = ((userProgress - planProgress) * planTotalDays)
                  .round();
              if (diffDays != 0) {
                goalDateText += diffDays > 0
                    ? ' (${diffDays.abs()}일 빠름)'
                    : ' (${diffDays.abs()}일 느림)';
              }
            }
          }
        }
      }
    }

    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _clickedSection == section ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 12),
                // 정보 항목들
                _buildInfoRow('목표 금액', targetAmountText),
                _buildInfoRow('진행률', targetProgressText),
                _buildInfoRow('일일 저축액', dailySavingText),
                _buildInfoRow('목표일', goalDateText),
                if (isPlan) _buildInfoRow('시작일', startDateText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 반원 D-Day 버튼 (레이아웃 1용)
  Widget _buildDDayButton(HomeViewModel vm) {
    return ValueListenableBuilder<int>(
      valueListenable: vm.secondTick,
      builder: (_, __, ___) {
        final remain = vm.liveRemaining;
        String dDayText = '목표일 없음';
        if (remain != null) {
          if (remain.isNegative) {
            dDayText = 'D-Day 달성';
          } else {
            dDayText = 'D-${remain.inDays}';
          }
        }

        // 남은 금액 계산
        String remainingAmountText = '0원';
        if (vm.latestPlan?.targetAmount != null) {
          final targetAmount = vm.latestPlan!.targetAmount!.toDouble();
          final currentAmount = vm.liveSavedAmount;
          final remaining = (targetAmount - currentAmount).clamp(
            0.0,
            double.infinity,
          );
          remainingAmountText = SavingPlanCalculator.formatAmount(remaining);
        }

        return InkWell(
          onTap: () => _showCountdownDialog(vm),
          child: Stack(
            children: [
              // 테두리 (ClipPath 밖에 그리기)
              CustomPaint(
                size: const Size(200, 100),
                painter: SemiCircleBorderPainter(),
              ),
              // 반원 버튼 내용
              ClipPath(
                clipper: SemiCircleClipper(),
                child: Container(
                  width: 200, // 반원 버튼 지름
                  height: 100, // 반원의 반지름
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // D-Day
                      Text(
                        dDayText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2962FF),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 남은 금액 라벨
                      const Text(
                        '남은 금액',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 남은 금액
                      Text(
                        remainingAmountText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2962FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 중앙 원형 버튼 (클릭 상태에 따라 색상과 내용 변경)
  Widget _buildCircularButton(HomeViewModel vm, {Color? buttonColor}) {
    return ValueListenableBuilder<int>(
      valueListenable: vm.secondTick,
      builder: (_, __, ___) {
        // AnimatedSwitcher로 버튼 전환 애니메이션 구현 (옵션 3: 미묘한 수직 슬라이드)
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            // AnimatedSwitcher는 나가는 위젯에 대해 reverse animation을 사용합니다
            final isExiting = animation.status == AnimationStatus.reverse;

            // 나가는 버튼: 왼쪽으로 사라짐 (2배 더 길게)
            // 들어오는 버튼: 오른쪽에서 나타남 (미묘한 움직임)
            final slideAnimation =
                Tween<Offset>(
                  begin: isExiting ? Offset.zero : const Offset(0.1, 0),
                  end: isExiting
                      ? const Offset(-0.2, 0)
                      : Offset.zero, // -0.1 * 2 = -0.2
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: isExiting ? Curves.easeInCubic : Curves.easeOutCubic,
                  ),
                );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
          child: _buildButtonContent(vm, buttonColor),
        );
      },
    );
  }

  /// 버튼 내용 위젯 (상태에 따라 다른 위젯 반환)
  Widget _buildButtonContent(HomeViewModel vm, Color? buttonColor) {
    // 클릭된 구역에 따라 색상과 정보 결정
    final isUserSection = _clickedSection == 'user';
    final isPlanSection = _clickedSection == 'plan';

    // 버튼 배경 색상
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isUserSection) {
      // 구역 1: 연한 파랑
      backgroundColor = const Color(0xFF7DAFFF);
      textColor = Colors.white;
      borderColor = const Color(0xFF7DAFFF);
    } else if (isPlanSection) {
      // 구역 2: 진한 파랑
      backgroundColor = const Color(0xFF0062FF);
      textColor = Colors.white;
      borderColor = const Color(0xFF0062FF);
    } else {
      // 기본: 흰색
      backgroundColor = Colors.white;
      textColor = buttonColor ?? const Color(0xFF2962FF);
      borderColor = Colors.grey[300]!;
    }

    // 표시할 정보 가져오기
    String title = '';
    List<Map<String, String>> infoItems = [];

    if (isUserSection) {
      // 사용자 그래프 정보
      title = '${vm.name}님 그래프';

      // 현재까지 모은 금액
      final currentAmountText = SavingPlanCalculator.formatAmount(
        vm.liveSavedAmount,
      );

      // 실제 저축률 계산
      String actualProgressText = '0%';
      if (vm.latestPlan?.targetAmount != null &&
          vm.latestPlan!.targetAmount! > 0) {
        final targetAmount = vm.latestPlan!.targetAmount!.toDouble();
        final actualProgress = (vm.liveSavedAmount / targetAmount * 100);
        actualProgressText = '${actualProgress.toStringAsFixed(1)}%';
      }

      // 하루 저축금액 (실제 평균)
      String dailySavingText = '0원/일';
      if (vm.latestPlan?.startDate != null && vm.liveSavedAmount > 0) {
        final startDate = vm.latestPlan!.startDate!;
        final daysElapsed = DateTime.now().difference(startDate).inDays;
        if (daysElapsed > 0) {
          final avgDailySaving = vm.liveSavedAmount / daysElapsed;
          dailySavingText =
              '${SavingPlanCalculator.formatAmount(avgDailySaving)}원/일';
        }
      }

      infoItems = [
        {'label': '현재까지 모은 금액', 'value': currentAmountText},
        {'label': '실제저축률', 'value': actualProgressText},
        {'label': '하루저축금액', 'value': dailySavingText},
      ];
    } else if (isPlanSection) {
      // 플랜 그래프 정보
      title = '플랜 그래프';

      // 목표금액
      String targetAmountText = '0원';
      if (vm.latestPlan?.targetAmount != null) {
        targetAmountText = SavingPlanCalculator.formatAmount(
          vm.latestPlan!.targetAmount!.toDouble(),
        );
      }

      // 저축률 (플랜 목표 진행률)
      String progressText = '0%';
      if (vm.latestPlan?.targetAmount != null &&
          vm.latestPlan!.targetAmount! > 0) {
        // 플랜 목표 진행률: 55% (하드코딩된 값)
        progressText = '55%';
      }

      // 하루저축금액 (플랜 기준)
      String dailySavingText = '0원/일';
      if (vm.calc != null && vm.calc!.dailySaving > 0) {
        dailySavingText =
            '${SavingPlanCalculator.formatAmount(vm.calc!.dailySaving)}원/일';
      }

      infoItems = [
        {'label': '목표금액', 'value': targetAmountText},
        {'label': '저축률', 'value': progressText},
        {'label': '하루저축금액', 'value': dailySavingText},
      ];
    } else {
      // 기본 상태: 모인 금액 표시
      final remain = vm.liveRemaining;
      String dDayText = '목표일 없음';
      if (remain != null) {
        if (remain.isNegative) {
          dDayText = 'D-Day 달성';
        } else {
          dDayText = 'D-${remain.inDays}';
        }
      }

      return InkWell(
        key: const ValueKey('home-button'),
        onTap: () => _showCountdownDialog(vm),
        child: Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // D-Day
              Text(
                dDayText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              // 모인 금액 라벨
              Text(
                '모인 금액',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              // 모인 금액 (AnimatedSwitcher 사용)
              ValueListenableBuilder<int>(
                valueListenable: vm.secondTick,
                builder: (_, __, ___) {
                  final formattedAmount = SavingPlanCalculator.formatAmount(
                    vm.liveSavedAmount,
                  );
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Text(
                      formattedAmount,
                      key: ValueKey(formattedAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    // 클릭된 상태: 정보 표시
    return GestureDetector(
      key: ValueKey(_clickedSection), // 각 섹션별 고유 key
      onTap: () {
        setState(() {
          _clickedSection = null; // 다시 클릭하면 닫기
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 210,
        height: 210,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // 정보 항목들
                ...infoItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${item['label']}: ${item['value']}',
                      style: TextStyle(fontSize: 10, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 알람 설정 버튼
  Widget _buildAlarmSettingButton() {
    return Center(
      child: InkWell(
        onTap: () => _showAlarmSettingModal(),
        child: Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Colors.white, // 흰색 배경
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⏰', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              const Text(
                '알림설정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 알람 설정 모달 (Bottom Sheet)
  void _showAlarmSettingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.7,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '알림 설정',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _alarmHours.length,
                  itemBuilder: (context, index) {
                    final hour = _alarmHours[index];
                    final timeText = hour < 12
                        ? '오전 ${hour}시'
                        : hour == 12
                        ? '오후 12시'
                        : '오후 ${hour - 12}시';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('📢', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Text(
                                timeText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Switch(
                                value: true, // 나중에 실제 알람 상태로 변경
                                onChanged: (value) {
                                  // 알람 ON/OFF 로직
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    _alarmHours.removeAt(index);
                                  });
                                  Navigator.pop(context);
                                  _showAlarmSettingModal();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // 시간 선택 다이얼로그
                  _showTimePicker();
                },
                icon: const Icon(Icons.add),
                label: const Text('알림 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0062FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 시간 선택 다이얼로그
  void _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final hour = picked.hour;
        if (!_alarmHours.contains(hour)) {
          _alarmHours.add(hour);
          _alarmHours.sort();
        }
      });
    }
  }

  // 기준선 정보 계산 (현재 페이스 vs 목표 페이스)
  Map<String, dynamic> _calculateTargetLineInfo(
    HomeViewModel vm,
    double currentRate,
    double? targetLinePosition,
  ) {
    if (vm.latestPlan?.startDate == null ||
        vm.calc?.goalDateTime == null ||
        vm.latestPlan?.targetAmount == null ||
        targetLinePosition == null) {
      return {'hasData': false};
    }

    final planStartDate = vm.latestPlan!.startDate!;
    final goalDate = vm.calc!.goalDateTime!;
    final targetAmount = vm.latestPlan!.targetAmount!.toDouble();

    final totalDays = goalDate.difference(planStartDate).inDays;

    if (totalDays <= 0) {
      return {'hasData': false};
    }

    // 현재 페이스 = currentRate (0.0~1.0)
    // 목표 페이스 = targetLinePosition (0.0~1.0)
    // 차이 = currentRate - targetLinePosition

    final paceDiff = currentRate - targetLinePosition;

    // 금액 차이 = 차이 비율 * 목표 금액
    final amountDiff = paceDiff * targetAmount;

    // 일수 차이 = 차이 비율 * 총 일수
    final daysDiff = paceDiff * totalDays;

    // 차이가 거의 없으면 (0.5% 이내) 같다고 간주
    final isSame = paceDiff.abs() < 0.005;

    return {
      'hasData': true,
      'amountDiff': amountDiff,
      'daysDiff': daysDiff,
      'isAboveTarget': paceDiff >= 0,
      'isSame': isSame,
    };
  }

  /// 목표 페이스 컨테이너 (입력된 그래프 퍼센트 기반)
  Widget _buildGoalPaceContainer() {
    // 플랜과 사용자 그래프 퍼센트 차이 계산
    final planPercent = _planProgressPercent;
    final userPercent = _userProgressPercent;
    final diff = (planPercent - userPercent).abs();

    // 어떤 그래프가 더 큰지 판단
    final isUserLarger = userPercent > planPercent;

    // 목표 금액이 있다면 금액 차이 계산 (예시: 목표 금액 5,000,000원 기준)
    final targetAmount = 5000000.0; // TODO: 실제 목표 금액과 연동
    final amountDiff = (diff / 100.0) * targetAmount;

    // 일수 차이 계산 (예시: 총 목표 일수 180일 기준)
    final totalDays = 180; // TODO: 실제 목표 일수와 연동
    final daysDiff = (diff / 100.0) * totalDays;

    // 금액 텍스트 및 색상
    String amountText;
    Color amountColor;
    if (isUserLarger) {
      // 사용자가 플랜보다 앞서 있음
      amountText = '${SavingPlanCalculator.formatAmount(amountDiff)}원 더 모았어요!';
      amountColor = const Color(0xFF0062FF);
    } else if (planPercent > userPercent) {
      // 플랜이 사용자보다 앞서 있음
      amountText = '${SavingPlanCalculator.formatAmount(amountDiff)}원 부족해요!';
      amountColor = const Color(0xFFFF6B6B);
    } else {
      // 같음
      amountText = '목표 달성!';
      amountColor = const Color(0xFF4CAF50);
    }

    // 일수 텍스트 및 색상
    String daysText;
    Color daysColor;
    if (isUserLarger) {
      daysText = '${daysDiff.round()}일 빨라요!';
      daysColor = const Color(0xFF0062FF);
    } else if (planPercent > userPercent) {
      daysText = '${daysDiff.round()}일 느려요!';
      daysColor = const Color(0xFFFF6B6B);
    } else {
      daysText = '목표 달성!';
      daysColor = const Color(0xFF4CAF50);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 노란색 점 + "목표 페이스" (중앙 정렬)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '목표 페이스',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777777),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 하단: 금액 / 일수 (세로 구분선)
          Row(
            children: [
              // 왼쪽: 금액
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                      '금액',
                      style: TextStyle(fontSize: 11, color: Color(0xFF777777)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // 세로 구분선
              Container(width: 1, height: 50, color: Colors.grey[300]),
              // 오른쪽: 일수
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFFFF5F5F),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '일수',
                      style: TextStyle(fontSize: 11, color: Color(0xFF777777)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: daysColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 기준선 정보 위젯
  Widget _buildTargetLineInfo(
    HomeViewModel vm,
    double currentRate,
    double? targetLinePosition,
  ) {
    final info = _calculateTargetLineInfo(vm, currentRate, targetLinePosition);

    if (!info['hasData']) {
      return const SizedBox.shrink();
    }

    final amountDiff = info['amountDiff'] as double;
    final daysDiff = info['daysDiff'] as double;
    final isSame = info['isSame'] as bool;
    final isAboveTarget = info['isAboveTarget'] as bool;

    // 같으면 "잘 하고 있어요!" 표시
    if (isSame) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단: 노란색 점 + "목표 페이스" (중앙 정렬)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '목표 페이스',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 하단: 금액 / 일수 (세로 구분선)
            Row(
              children: [
                // 왼쪽: 금액
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text(
                        '금액',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          // 노란선 기준 -1% 계산
                          final yellowLinePosition =
                              _appliedYellowLinePercent / 100.0;
                          const tolerance = 0.01;
                          final threshold =
                              yellowLinePosition - tolerance; // 노란선 기준 -1%

                          final inputProgress = _appliedProgressPercent / 100.0;
                          final isBlue = inputProgress > threshold;

                          String amountText;
                          Color amountColor;

                          if (isBlue) {
                            amountText = '12,000원 더 모았어요!';
                            amountColor = const Color(0xFF0062FF);
                          } else {
                            amountText = '34,000원 부족해요!';
                            amountColor = const Color(0xFFFF6B6B);
                          }

                          return Text(
                            amountText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: amountColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // 세로 구분선
                Container(width: 1, height: 50, color: Colors.grey[300]),
                // 오른쪽: 일수
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFFFF5F5F),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '일수',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          // 그래프 퍼센트와 기준선 퍼센트 차이 계산
                          final graphPercent = _appliedProgressPercent;
                          final yellowLinePercent = _appliedYellowLinePercent;
                          final diff = (graphPercent - yellowLinePercent).abs();

                          // 그래프가 기준선 전이면 느려요, 기준선 이상이면 빨라요
                          final isAhead = graphPercent >= yellowLinePercent;

                          String daysText;
                          Color daysColor;

                          if (isAhead) {
                            daysText = '${diff}일 빨라요!';
                            daysColor = const Color(0xFF0062FF);
                          } else {
                            daysText = '${diff}일 느려요!';
                            daysColor = const Color(0xFFFF6B6B);
                          }

                          return Text(
                            daysText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: daysColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 다르면 차이 표시
    final amountColor = isAboveTarget
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF5F5F);
    final amountText = isAboveTarget
        ? '${SavingPlanCalculator.formatAmount(amountDiff.abs())}원 더'
        : '${SavingPlanCalculator.formatAmount(amountDiff.abs())}원 덜';

    final days = daysDiff.abs().round();
    final daysText = isAboveTarget ? '$days일 더 빨라요' : '$days일 더 느려요';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 노란색 점 + "목표 페이스" (중앙 정렬)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '목표 페이스',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777777),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 하단: 금액 / 일수 (세로 구분선)
          Row(
            children: [
              // 왼쪽: 금액
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                      '금액',
                      style: TextStyle(fontSize: 11, color: Color(0xFF777777)),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        String displayAmountText;
                        Color displayAmountColor;

                        // 노란선 기준 -1% 계산
                        final yellowLinePosition =
                            _appliedYellowLinePercent / 100.0;
                        const tolerance = 0.01;
                        final threshold =
                            yellowLinePosition - tolerance; // 노란선 기준 -1%

                        final inputProgress = _appliedProgressPercent / 100.0;
                        final isBlue = inputProgress > threshold;

                        if (isBlue) {
                          displayAmountText = '12,000원 더 모았어요!';
                          displayAmountColor = const Color(0xFF0062FF);
                        } else {
                          displayAmountText = '34,000원 부족해요!';
                          displayAmountColor = const Color(0xFFFF6B6B);
                        }

                        return Text(
                          displayAmountText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: displayAmountColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // 세로 구분선
              Container(width: 1, height: 50, color: Colors.grey[300]),
              // 오른쪽: 일수
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFFFF5F5F),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '일수',
                      style: TextStyle(fontSize: 11, color: Color(0xFF777777)),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        String displayDaysText;
                        Color displayDaysColor;

                        // 그래프 퍼센트와 기준선 퍼센트 차이 계산
                        final graphPercent = _appliedProgressPercent;
                        final yellowLinePercent = _appliedYellowLinePercent;
                        final diff = (graphPercent - yellowLinePercent).abs();

                        // 그래프가 기준선 전이면 느려요, 기준선 이상이면 빨라요
                        final isAhead = graphPercent >= yellowLinePercent;

                        if (isAhead) {
                          displayDaysText = '${diff}일 빨라요!';
                          displayDaysColor = const Color(0xFF0062FF);
                        } else {
                          displayDaysText = '${diff}일 느려요!';
                          displayDaysColor = const Color(0xFFFF6B6B);
                        }

                        return Text(
                          displayDaysText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: displayDaysColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// D-Day 카운트다운 상세 보기 (밑에서 올라오는 모달)
  void _showCountdownDialog(HomeViewModel vm) {
    setState(() {
      _showCountdownModal = true;
    });
    _modalController.forward();
  }

  void _closeCountdownModal() {
    _modalController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showCountdownModal = false;
        });
      }
    });
  }

  Widget _buildCountdownModal(HomeViewModel vm) {
    if (!_showCountdownModal) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: _modalController.status == AnimationStatus.dismissed,
      child: Stack(
        children: [
          // 스크림 (배경)
          FadeTransition(
            opacity: _modalScrimFade,
            child: GestureDetector(
              onTap: _closeCountdownModal,
              child: Container(color: Colors.black54),
            ),
          ),
          // 모달
          Positioned.fill(
            child: SlideTransition(
              position: _modalSlideAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  heightFactor: 0.7,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.98, end: 1.0),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                        bottom: Radius.zero,
                      ),
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            // 헤더 (닫기 버튼만)
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: _closeCountdownModal,
                                  ),
                                ],
                              ),
                            ),
                            // 내용
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    ValueListenableBuilder<int>(
                                      valueListenable: vm.secondTick,
                                      builder: (_, __, ___) {
                                        final remain =
                                            vm.liveRemaining ?? Duration.zero;
                                        final clamped = remain.isNegative
                                            ? Duration.zero
                                            : remain;

                                        final days = clamped.inDays;
                                        final hours = clamped.inHours % 24;
                                        final minutes = clamped.inMinutes % 60;
                                        final seconds = clamped.inSeconds % 60;

                                        String twoDigits(int v) =>
                                            v.toString().padLeft(2, '0');

                                        return Text(
                                          '$days일 ${twoDigits(hours)}:'
                                          '${twoDigits(minutes)}:${twoDigits(seconds)}',
                                          style: const TextStyle(
                                            fontFamily: 'RobotoMono',
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      '1초마다 ${vm.perSecondSaving}원이 증가해요',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // 목표 페이스 정보 컨테이너 (입력된 그래프 퍼센트 기반)
                                    _buildGoalPaceContainer(),
                                    const SizedBox(height: 24),
                                    // 목표 페이스 정보 컨테이너 (기존)
                                    ValueListenableBuilder<int>(
                                      valueListenable: vm.secondTick,
                                      builder: (_, __, ___) {
                                        // 현재 페이스 재계산 (실시간 업데이트)
                                        double currentRateValue = 0.0;
                                        double? targetLinePositionValue;

                                        if (vm.latestPlan?.targetAmount !=
                                                null &&
                                            vm.latestPlan!.targetAmount! > 0) {
                                          final targetAmount = vm
                                              .latestPlan!
                                              .targetAmount!
                                              .toDouble();
                                          final currentAmount =
                                              vm.liveSavedAmount;
                                          currentRateValue =
                                              (currentAmount / targetAmount)
                                                  .clamp(0.0, 1.0);
                                        }

                                        // 목표 페이스 계산
                                        if (vm.latestPlan?.startDate != null &&
                                            vm.calc?.goalDateTime != null &&
                                            vm.latestPlan?.targetAmount !=
                                                null &&
                                            vm.latestPlan!.targetAmount! > 0) {
                                          final planStartDate =
                                              vm.latestPlan!.startDate!;
                                          final goalDate =
                                              vm.calc!.goalDateTime!;
                                          final now = DateTime.now();
                                          final totalDays = goalDate
                                              .difference(planStartDate)
                                              .inDays;
                                          final elapsedDays = now
                                              .difference(planStartDate)
                                              .inDays;

                                          if (totalDays > 0 &&
                                              elapsedDays >= 0) {
                                            targetLinePositionValue =
                                                (elapsedDays / totalDays).clamp(
                                                  0.0,
                                                  1.0,
                                                );
                                          }
                                        }

                                        return Column(
                                          children: [
                                            _buildTargetLineInfo(
                                              vm,
                                              currentRateValue,
                                              targetLinePositionValue,
                                            ),
                                            const SizedBox(height: 24),
                                            // 저축 목표 진행률 막대 그래프
                                            _buildProgressBar(
                                              vm,
                                              currentRateValue,
                                              targetLinePositionValue,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }

  /// 저축 목표 진행률 막대 그래프
  Widget _buildProgressBar(
    HomeViewModel vm,
    double currentRate,
    double? targetLinePosition,
  ) {
    // 진행률 계산 (퍼센트)
    final progressPercent = (currentRate * 100).toStringAsFixed(1);

    // 현재 시점 기준 금액 (목표 페이스 기준)
    String targetAmountText = '0원';
    double? targetAmount;
    if (vm.latestPlan?.targetAmount != null && targetLinePosition != null) {
      targetAmount = vm.latestPlan!.targetAmount! * targetLinePosition;
      targetAmountText = SavingPlanCalculator.formatAmount(targetAmount);
    }

    // 기준 미달 금액 (현재 모인 금액과 목표 페이스 금액의 차이)
    String shortfallAmountText = '0원';
    final currentAmount = vm.liveSavedAmount;
    if (targetAmount != null && currentAmount < targetAmount) {
      final shortfall = targetAmount - currentAmount;
      shortfallAmountText = SavingPlanCalculator.formatAmount(shortfall);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 날짜
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '저축 목표 진행률',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              // 어제 날짜 텍스트
              Builder(
                builder: (context) {
                  final yesterday = DateTime.now().subtract(
                    const Duration(days: 1),
                  );
                  final dateText =
                      '${yesterday.year.toString().substring(2)}.${yesterday.month.toString().padLeft(2, '0')}.${yesterday.day.toString().padLeft(2, '0')}일자 기준';
                  return Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF777777),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 진행 바
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              // 노란선 위치: 적용된 퍼센트로 동적 설정
              final yellowLinePosition = _appliedYellowLinePercent / 100.0;
              final yellowLineX = barWidth * yellowLinePosition;

              // 노란선 기준 -1% 계산
              const tolerance = 0.01; // 1%
              final threshold = yellowLinePosition - tolerance; // 노란선 기준 -1%

              // 입력된 진행률 (0.0 ~ 1.0)
              final inputProgress = _appliedProgressPercent / 100.0;

              // 그래프 색상 결정: 노란선 기준 -1% 미만이면 빨간색, 초과하면 파란색
              final isBlue = inputProgress > threshold;
              final graphColor = isBlue
                  ? const Color(0xFF0062FF)
                  : const Color(0xFFFF6B6B);

              return Stack(
                children: [
                  // 배경 바
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // 진행 바 (입력된 퍼센트만큼)
                  if (_appliedProgressPercent > 0)
                    FractionallySizedBox(
                      widthFactor: inputProgress.clamp(0.0, 1.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: graphColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  // 노란선 마커 (40% 위치에 고정)
                  Positioned(
                    left: yellowLineX - 1,
                    top: -4,
                    child: Container(
                      width: 2,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // 노란색 기준선 입력칸과 적용 버튼 (왼쪽)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 노란색 기준선 입력칸
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _yellowLineInputController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '기준선',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFC107),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    final num = int.tryParse(value);
                    if (num != null) {
                      setState(() {
                        _inputYellowLinePercent = num.clamp(0, 100);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 적용 버튼
              InkWell(
                onTap: () {
                  final input = int.tryParse(_yellowLineInputController.text);
                  if (input != null && input >= 0 && input <= 100) {
                    setState(() {
                      _appliedYellowLinePercent = input;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '적용',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 그래프 입력칸 (오른쪽)
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _progressInputController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '그래프',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFF0062FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    final num = int.tryParse(value);
                    if (num != null) {
                      setState(() {
                        _inputProgressPercent = num.clamp(0, 100);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 적용 버튼
              InkWell(
                onTap: () {
                  final input = int.tryParse(_progressInputController.text);
                  if (input != null && input >= 0 && input <= 100) {
                    setState(() {
                      _appliedProgressPercent = input;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0062FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '적용',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 정보 라인 (목표보다 ㅇㅇ일 빨라요/느려요)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  // 그래프 퍼센트와 기준선 퍼센트 차이 계산
                  final graphPercent = _appliedProgressPercent;
                  final yellowLinePercent = _appliedYellowLinePercent;
                  // 절댓값 차이 계산
                  final diff = (graphPercent - yellowLinePercent).abs();

                  // 그래프가 기준선 전이면 느려요, 기준선 이상이면 빨라요
                  final isAhead = graphPercent >= yellowLinePercent;

                  Color dotColor;
                  String text;

                  if (isAhead) {
                    dotColor = const Color(0xFF0062FF);
                    text = '플랜보다 ${diff}일 빨라요';
                  } else {
                    dotColor = const Color(0xFFFF6B6B);
                    text = '플랜보다 ${diff}일 느려요';
                  }

                  return Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 뷰모델 받아오기
    final vm = context.watch<HomeViewModel>();

    // 로그인 없이도 화면 표시 (에러 무시)
    // if (vm.isLoading) {
    //   return const Scaffold(
    //     body: SafeArea(child: Center(child: CircularProgressIndicator())),
    //   );
    // }
    // if (vm.error != null) {
    //   return Scaffold(
    //     body: SafeArea(child: Center(child: Text('오류: ${vm.error}'))),
    //   );
    // }

    // 뷰 모델 변수 받아오기 (기본값 설정)
    final userName = vm.name.isNotEmpty ? vm.name : '테스트 사용자';
    final planName = vm.planTitle.isNotEmpty ? vm.planTitle : '테스트 플랜';
    final fixedSpending = vm.dailyLimitText.isNotEmpty
        ? vm.dailyLimitText
        : '7,000원';

    // 현재 페이스 계산 (현재 모인 금액 / 목표 금액)
    double currentRate = 0.0;
    if (vm.latestPlan?.targetAmount != null &&
        vm.latestPlan!.targetAmount! > 0) {
      final targetAmount = vm.latestPlan!.targetAmount!.toDouble();
      final currentAmount = vm.liveSavedAmount;
      currentRate = (currentAmount / targetAmount).clamp(0.0, 1.0);
    }

    // 목표 페이스 계산 (시간 경과 비율 = 기준선 위치)
    double? targetLinePosition;
    if (vm.latestPlan?.startDate != null &&
        vm.calc?.goalDateTime != null &&
        vm.latestPlan?.targetAmount != null &&
        vm.latestPlan!.targetAmount! > 0) {
      final planStartDate = vm.latestPlan!.startDate!;
      final goalDate = vm.calc!.goalDateTime!;

      final now = DateTime.now();
      final totalDays = goalDate.difference(planStartDate).inDays;
      final elapsedDays = now.difference(planStartDate).inDays;

      if (totalDays > 0 && elapsedDays >= 0) {
        // 시간 경과 비율로 기준선 위치 계산 (목표 페이스)
        targetLinePosition = (elapsedDays / totalDays).clamp(0.0, 1.0);
      }
    }

    final displayDate = _formatDate(_selectedDate);
    final actualSpent = vm.todaySpending.toDouble();
    final todaySpending = '${vm.todaySpending}원';
    final dailyLimit =
        double.tryParse(fixedSpending.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    final hasRecord = actualSpent > 0;
    final isOverLimit = hasRecord && dailyLimit > 0 && actualSpent > dailyLimit;

    final containerBackgroundColor = !hasRecord
        ? Colors.grey[200]!
        : isOverLimit
        ? const Color(0xFFFFEFEF)
        : const Color(0xFFEFF5FF);

    final spentTextColor = !hasRecord
        ? AppColors.text
        : isOverLimit
        ? const Color(0xFFFF5F5F)
        : const Color(0xFF0062FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                CustomAppBarHome(
                  text: '$userName 님',
                  unreadCount: 3,
                  onNotifications: () =>
                      Navigator.pushNamed(context, '/notification'),
                  onSettings: () => Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('/setting'),
                ),

                // 플랜/사용자 그래프 입력 컨테이너 (앱 바로 아래)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: _buildProgressInputContainer(),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: Column(
                        children: [
                          /// 🔹 플랜 정보 + 목표 진행률
                          RoundedInfoContainer(
                            backgroundColor: Colors.white, // 흰색
                            child: Column(
                              children: [
                                // 상단 정보 영역
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F0FF),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ParagraphText(
                                            text: planName,
                                            color: const Color(0xFF2962FF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () async =>
                                              await showPlanNameEditSheet(
                                                context,
                                              ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Color(0xFF2962FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // 메인 게이지 영역 (화면의 시각적 중심)
                                _buildChart(vm),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// 오늘 지출 UI
                          RoundedInfoContainer(
                            backgroundColor: containerBackgroundColor,
                            padding: 20,
                            child: Column(
                              crossAxisAlignment: hasRecord
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        ParagraphText(
                                          text: displayDate,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pushNamed('/add_income_edit'),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _changeDate(-1),
                                          child: const Icon(Icons.chevron_left),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _changeDate(1),
                                          child: const Icon(
                                            Icons.chevron_right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                if (!hasRecord)
                                  SmallRoundedButton(
                                    text: "소비 기록하러 가기",
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pushNamed(
                                        '/record_spending',
                                        arguments: _selectedDate,
                                      );
                                    },
                                  )
                                else
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pushNamed('/today_spending');
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          todaySpending,
                                          style: TextStyle(
                                            color: spentTextColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          ' / ',
                                          style: TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          fixedSpending,
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
              ],
            ),
          ),
          // 모달
          _buildCountdownModal(vm),
        ],
      ),
    );
  }
}

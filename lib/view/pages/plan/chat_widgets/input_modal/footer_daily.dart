import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// 앱 공용 컴포넌트/테마
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/theme/app_spacing.dart';

// 요약 계산용 (목표/보유 읽기)
import '../../../../../view_model/plan/chat_plan_viewmodel.dart';

class FooterDaily extends StatefulWidget {
  final double total;
  final VoidCallback onComplete;
  final bool isOverBudget;   // (일×30 > monthlyIncome) 등 외부 계산 결과
  final double monthlyIncome;
  final bool isEdit;         // ✅ 수정 모드면 경고/흔들림/비활성화 모두 비활성

  const FooterDaily({
    Key? key,
    required this.total,
    required this.onComplete,
    this.isOverBudget = false,
    this.monthlyIncome = 0,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<FooterDaily> createState() => _FooterDailyState();
}

class _FooterDailyState extends State<FooterDaily> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shake;

  // ✨ 추가: 에러 배너용 컨트롤러
  late AnimationController _errCtrl;
  late Animation<Offset> _errSlide;
  late Animation<double> _errFade;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shake = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // ✨ 추가: 에러 배너 애니
    _errCtrl = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _errSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _errCtrl, curve: Curves.easeOutCubic));
    _errFade = CurvedAnimation(parent: _errCtrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant FooterDaily oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 기존: 예산 초과 흔들림
    final shouldShake = !widget.isEdit && widget.isOverBudget && !oldWidget.isOverBudget;
    if (shouldShake) {
      _shakeController.forward().then((_) => _shakeController.reverse());
    }

    // ✨ 추가: "월수입 > 목표금액"으로 바뀌는 순간 에러 배너 등장
    final vm = context.read<ChatPlanViewModel>();
    final target = vm.planInfo.targetAmount;
    final bool incomeExceedsTargetNow =
        !widget.isEdit && target != null && target > 0 && widget.monthlyIncome > target;

    final bool incomeExceedsTargetBefore = () {
      final t = vm.planInfo.targetAmount;
      return !oldWidget.isEdit && t != null && t > 0 && oldWidget.monthlyIncome > t;
    }();

    if (incomeExceedsTargetNow && !incomeExceedsTargetBefore) {
      _errCtrl.forward();  // 슬라이드+페이드 인
    } else if (!incomeExceedsTargetNow && incomeExceedsTargetBefore) {
      _errCtrl.reverse();  // 슬라이드+페이드 아웃 (조건 해제 시)
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _errCtrl.dispose(); // ✨ 추가
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern('ko_KR');
    final monthlySpending = (widget.total * 30).toInt();
    final over = widget.isOverBudget && !widget.isEdit;

    final vm = context.watch<ChatPlanViewModel>();
    final target = vm.planInfo.targetAmount;
    final current = vm.planInfo.currentAsset ?? 0.0;
    final monthlySaving = (widget.monthlyIncome - monthlySpending).toDouble();

    // ✨ 조건: 월수입이 목표금액을 초과 (isEdit면 표시하지 않음)
    final bool incomeExceedsTarget =
        !widget.isEdit && target != null && target > 0 && widget.monthlyIncome > target;

    String helperLine = '';
    if (!widget.isEdit) {
      if (over) {
        helperLine = '월 잔여 예산 ${nf.format(widget.monthlyIncome)}원을 초과했어요.';
      } else if (target != null && target > 0) {
        final remaining = target - current;
        if (remaining <= 0) {
          helperLine = '🎉 이미 목표를 달성했어요!';
        } else if (monthlySaving > 0) {
          final monthsRaw = remaining / monthlySaving;
          final monthsNeeded = monthsRaw.isFinite && monthsRaw > 0 ? monthsRaw.round() : 0;
          helperLine = '목표 금액까지 약 ${monthsNeeded}개월 소요!';
        } else {
          helperLine = '⚠️ 현재 금액으로는 저축이 어려워요. \n일일 소비를 조금 줄여볼까요?';
        }
      } else {
        helperLine = '목표 금액을 입력하면 예상 소요 기간을 계산해드려요.';
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          // ✨ 에러 배너 (슬라이드+페이드)
          if (incomeExceedsTarget)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding).copyWith(bottom: 8),
              child: SlideTransition(
                position: _errSlide,
                child: FadeTransition(
                  opacity: _errFade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE1E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: Color(0xFFF02121)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '월수입이 목표금액을 초과했어요. 목표를 재설정해 주세요.',
                            style: const TextStyle(
                              fontFamily: 'Pretendard Variable',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF02121),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // 금액 요약 + (필요 시) 흔들림
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: AnimatedBuilder(
              animation: _shake,
              builder: (_, __) {
                final double dx = over ? _shake.value : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ParagraphText(
                                  text: '${nf.format(widget.total.toInt())}원',
                                  fontWeight: FontWeight.bold,
                                  color: over ? const Color(0xFFF02121) : null,
                                ),
                                const SubText(text: '일일 총합', fontWeight: FontWeight.bold),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(width: 2, height: 36, color: AppColors.greyBackground),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ParagraphText(
                                  text: '${nf.format(monthlySpending)}원',
                                  fontWeight: FontWeight.bold,
                                  color: over ? const Color(0xFFF02121) : null,
                                ),
                                const SubText(text: '월별 총합(30일 기준)', fontWeight: FontWeight.bold),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // 안내/경고 문구 (isEdit=false일 때만)
          if (helperLine.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Center(
                child: Text(
                  helperLine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: over || monthlySaving <= 0 ? AppColors.redText : AppColors.subText,
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.sectionSpacing),

          // 버튼: isEdit=true면 항상 활성 + 라벨 '완료'
          CustomButton(
            text: over ? (widget.isEdit ? '완료' : '예산을 초과했어요') : '완료',
            onPressed: widget.onComplete,
            enabled: widget.isEdit ? true : !over,
          ),
        ],
      ),
    );
  }
}

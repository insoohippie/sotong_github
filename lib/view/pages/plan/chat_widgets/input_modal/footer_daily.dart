import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/theme/app_spacing.dart';

import '../../../../../view_model/plan/chat_plan_viewmodel.dart';

class FooterDaily extends StatefulWidget {
  final double total;           // 일일 합계
  final VoidCallback onComplete;
  final bool isOverBudget;      // 예산 초과 여부 (일×30 > monthlyIncome)
  final double monthlyIncome;   // 월 잔여 예산(= 수입 - 고정비)
  final bool isEdit;            // true if editing an existing plan

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
  }

  @override
  void didUpdateWidget(covariant FooterDaily oldWidget) {
    super.didUpdateWidget(oldWidget);
    // false -> true로 넘어갈 때 흔들림
    if (widget.isOverBudget && !oldWidget.isOverBudget) {
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthlySpending = (widget.total * 30).toInt(); // 월환산 소비
    final over = widget.isOverBudget;

    // ✅ ViewModel에서 목표/보유금액 읽기
    final vm = context.watch<ChatPlanViewModel>();
    final target = vm.totalPlan.targetAmount?.toDouble();
    final current = vm.totalPlan.currentAsset.toDouble();
    final monthlySaving = (widget.monthlyIncome - monthlySpending).toDouble();

    // ✅ 예상 소요 기간 문구 조립
    String? helperLine;
    if (over) {
      // 예산 초과
      helperLine =
      '월 잔여 예산 ${NumberFormat('#,###').format(widget.monthlyIncome)}원을 초과했어요.';
    } else if (target != null && target > 0) {
      final remaining = target - current;
      if (remaining <= 0) {
        helperLine = '🎉 이미 목표를 달성했어요!';
      } else if (monthlySaving > 0) {
        // 개월 수 = 남은금액 / 월저축액 → 올림
        final monthsNeeded = (remaining / monthlySaving).ceil();
        helperLine = '목표 금액까지 약 ${monthsNeeded}개월 소요!';
      } else if (monthlySaving < 0) {
        // 저축 불가(0 이하)
        helperLine = '⚠️ 현재 금액으로는 저축이 어려워요. 일일 소비를 조금 줄여볼까요?';
      }
    } else {
      // 목표 미입력 시 가벼운 안내
      helperLine = '목표 금액을 입력하면 예상 소요 기간을 계산해드려요.';
    }

    final bool showTargetWarning =
        !widget.isEdit && target != null && target > 0 && widget.monthlyIncome > target;
    final String? targetWarningText = showTargetWarning
        ? '월 잔여 예산 ${NumberFormat('#,###').format(widget.monthlyIncome.toInt())}원이 '
            '목표 금액 ${NumberFormat('#,###').format(target!.toInt())}원을 초과했어요.\n'
            '목표를 조금 올리거나 예산을 다시 조정해볼까요?'
        : null;

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: AnimatedBuilder(
              animation: _shake,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(_shake.value, 0),
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
                                  text: '${NumberFormat('#,###').format(widget.total.toInt())}원',
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
                                  text: '${NumberFormat('#,###').format(monthlySpending)}원',
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
            child: showTargetWarning
                ? Padding(
                    key: const ValueKey('target-warning'),
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.redText.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: AppColors.redText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              targetWarningText ?? '',
                              style: const TextStyle(
                                fontFamily: 'Pretendard Variable',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.redText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('target-warning-empty')),
          ),
          if (showTargetWarning) const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Center(
              child: Text(
                helperLine ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: over || monthlySaving <= 0
                      ? AppColors.redText
                      : AppColors.subText,
                ),
              ),
            ),
          ),


          const SizedBox(height: AppSpacing.sectionSpacing),
          // 예산 초과 시 버튼 비활성화
          CustomButton(
            text: over ? '예산을 초과했어요' : '완료',
            onPressed: over ? () {} : widget.onComplete,
            enabled: !over,
          ),
        ],
      ),
    );
  }
}

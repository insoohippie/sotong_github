import 'package:flutter/material.dart';

import '../../../../component/buttons/custom_button.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../view_model/home/home_view_model.dart';
import '../../../../view_model/services/saving_calculator.dart';

/// 종료일 자동 연장 완료 통보 팝업.
///
/// "종료일이 지났는데 목표 미달"이라 앱이 modEndDate를 뒤로 민 뒤,
/// 사용자에게 부족액·연장일수·새 종료일을 알린다.
/// [onAdjustPlan]: '계획 조정하기' — 플랜 편집 화면으로 이동
Future<void> showHomeEndDateExtensionDialog(
  BuildContext context, {
  required EndDateExtensionResult result,
  required VoidCallback onAdjustPlan,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final bgColor = isDark ? AppColors.darkSurface : Colors.white;
  final textColor = isDark ? AppColors.darkText : Colors.black87;
  final subColor = isDark ? AppColors.darkSubText : AppColors.subText;

  final shortfallText = SavingPlanCalculator.formatAmount(result.shortfall);
  final days = result.extendedDays;
  final newEnd = result.newEnd;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: _ScaleIn(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '목표일이 조정됐어요',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '아직 $shortfallText원이 남았어요.\n'
                  '지금 페이스대로면 $days일 뒤인\n'
                  '${newEnd.month}월 ${newEnd.day}일에 도달할 수 있어요.',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '목표일을 ${newEnd.month}월 ${newEnd.day}일로 옮겼어요. 조금만 더 힘내요!',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 14,
                    color: subColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onAdjustPlan();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '계획 조정하기',
                          style: TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: '확인',
                        height: 50,
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 설정 다이얼로그(_AnimatedCenterPopup)와 동일한 등장 애니메이션
class _ScaleIn extends StatefulWidget {
  const _ScaleIn({required this.child});
  final Widget child;

  @override
  State<_ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<_ScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      alignment: Alignment.center,
      child: widget.child,
    );
  }
}

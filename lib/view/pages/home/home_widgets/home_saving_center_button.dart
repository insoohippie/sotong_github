import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/view_model/home/home_view_model.dart';
import 'package:sotong_local/view_model/services/saving_calculator.dart';

class HomeSavingCenterButton extends StatelessWidget {
  const HomeSavingCenterButton({
    super.key,
    required this.vm,
    required this.clickedSection, // 'plan' | 'user' | null
    required this.onCloseSection,
    required this.onOpenCountdown,
  });

  final HomeViewModel vm;
  final String? clickedSection;
  final VoidCallback onCloseSection;
  final VoidCallback onOpenCountdown;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: vm.secondTick,
      builder: (_, __, ___) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final isExiting = animation.status == AnimationStatus.reverse;

            final slide =
            Tween<Offset>(
              begin: isExiting ? Offset.zero : const Offset(0.1, 0),
              end: isExiting ? const Offset(-0.2, 0) : Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: isExiting ? Curves.easeInCubic : Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: _buildContent(context),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final isUser = clickedSection == 'user';
    final isPlan = clickedSection == 'plan';

    Color bg;
    Color textColor;
    Color border;

    if (isUser) {
      bg = const Color(0xFF7DAFFF);
      textColor = Colors.white;
      border = const Color(0xFF7DAFFF);
    } else if (isPlan) {
      bg = const Color(0xFF0062FF);
      textColor = Colors.white;
      border = const Color(0xFF0062FF);
    } else {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      bg = isDark ? theme.colorScheme.surface : Colors.white;
      textColor = AppColors.primary;
      border = isDark ? theme.dividerColor : Colors.grey[300]!;
    }

    // 기본 상태: D-Day + 모인 금액 (클릭 시 상세 모달 오픈)
    if (!isUser && !isPlan) {
      final remain = vm.liveRemaining;
      String dDayText = '목표일 없음';
      if (remain != null) {
        dDayText = remain.isNegative ? 'D-Day 달성' : 'D-${remain.inDays}';
      }

      return InkWell(
        key: const ValueKey('center-default'),
        onTap: onOpenCountdown,
        child: _circleShell(
          bg: bg,
          border: border,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dDayText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '모인 금액',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              _AnimatedAmount(textColor: textColor, amount: vm.liveSavedAmount),
            ],
          ),
        ),
      );
    }

    // 클릭 상태: 정보 표시 (클릭하면 닫기)
    final title = isUser ? '${vm.name}님 그래프' : '플랜 그래프';

    final items = <Map<String, String>>[];
    if (isUser) {
      final currentAmount = SavingPlanCalculator.formatAmount(
        vm.liveSavedAmount,
      );

      String actualProgressText = '0%';
      if (vm.latestPlan?.targetAmount != null &&
          vm.latestPlan!.targetAmount! > 0) {
        final target = vm.latestPlan!.targetAmount!.toDouble();
        final p = (vm.liveSavedAmount / target * 100);
        actualProgressText = '${p.toStringAsFixed(1)}%';
      }

      String dailySavingText = '0원/일';
      if (vm.latestPlan?.startDate != null && vm.liveSavedAmount > 0) {
        final days = DateTime.now()
            .difference(vm.latestPlan!.startDate!)
            .inDays;
        if (days > 0) {
          final avg = vm.liveSavedAmount / days;
          dailySavingText = '${SavingPlanCalculator.formatAmount(avg)}원/일';
        }
      }

      items.addAll([
        {'label': '현재까지 모은 금액', 'value': currentAmount},
        {'label': '실제저축률', 'value': actualProgressText},
        {'label': '하루저축금액', 'value': dailySavingText},
      ]);
    } else {
      String targetAmountText = '0원';
      if (vm.latestPlan?.targetAmount != null) {
        targetAmountText = SavingPlanCalculator.formatAmount(
          vm.latestPlan!.targetAmount!.toDouble(),
        );
      }

      String progressText = '0%';
      if (vm.latestPlan?.targetAmount != null &&
          vm.latestPlan!.targetAmount! > 0) {
        progressText = '55%'; // 기존 코드 유지(나중에 실제 계산으로 교체)
      }

      String dailySavingText = '0원/일';
      if (vm.calc != null && vm.calc!.dailySaving > 0) {
        dailySavingText =
        '${SavingPlanCalculator.formatAmount(vm.calc!.dailySaving)}원/일';
      }

      items.addAll([
        {'label': '목표금액', 'value': targetAmountText},
        {'label': '저축률', 'value': progressText},
        {'label': '하루저축금액', 'value': dailySavingText},
      ]);
    }

    return GestureDetector(
      key: ValueKey(clickedSection),
      onTap: onCloseSection,
      child: _circleShell(
        bg: bg,
        border: border,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                ...items.map(
                      (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${e['label']}: ${e['value']}',
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

  Widget _circleShell({
    required Color bg,
    required Color border,
    required Widget child,
  }) {
    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AnimatedAmount extends StatelessWidget {
  const _AnimatedAmount({required this.textColor, required this.amount});

  final Color textColor;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final formatted = SavingPlanCalculator.formatAmount(amount);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        formatted,
        key: ValueKey(formatted),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

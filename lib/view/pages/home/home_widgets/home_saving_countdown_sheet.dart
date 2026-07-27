import 'package:flutter/material.dart';
import 'package:sotong/view_model/home/home_view_model.dart';
import 'package:sotong/view_model/services/saving_calculator.dart';

class HomeSavingCountdownSheet extends StatefulWidget {
  const HomeSavingCountdownSheet({super.key, required this.vm});

  final HomeViewModel vm;

  @override
  State<HomeSavingCountdownSheet> createState() =>
      _HomeSavingCountdownSheetState();
}

class _HomeSavingCountdownSheetState extends State<HomeSavingCountdownSheet> {
  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // 헤더(닫기)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context),
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
                  child: Column(
                    children: [
                      _CountdownHeader(vm: vm),
                      const SizedBox(height: 24),

                      _GoalPaceContainer(vm: vm),
                      const SizedBox(height: 24),

                      _buildProgressBarCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBarCard() {
    final vm = widget.vm;
    final theme = Theme.of(context);
    const planColor = Color(0xFF0062FF);
    const userColor = Color(0xFFFFC107);
    const behindColor = Color(0xFFFF6B6B);

    return ValueListenableBuilder<int>(
      valueListenable: vm.secondTick,
      builder: (_, __, ___) {
        final planPercent = (vm.graphPlanPercent * 100)
            .clamp(0.0, 100.0)
            .toDouble();
        final userPercent = (vm.graphUserPercent * 100)
            .clamp(0.0, 100.0)
            .toDouble();
        final planProgress = planPercent / 100.0;
        final userProgress = userPercent / 100.0;
        final averageDailySaving = vm.averageDailySaving;
        final savedDiff = vm.actualSavedNow - vm.plannedSavedNow;

        String paceText;
        Color paceColor;
        if (averageDailySaving <= 0) {
          paceText = '플랜 대비 차이를 계산할 수 없어요';
          paceColor = theme.colorScheme.onSurfaceVariant;
        } else {
          final dayDiff = savedDiff / averageDailySaving;
          final absDays = dayDiff.abs().toStringAsFixed(1);
          if (absDays == '0.0') {
            paceText = '플랜과 같은 속도로 진행 중이에요';
            paceColor = theme.colorScheme.onSurfaceVariant;
          } else if (dayDiff > 0) {
            paceText = '플랜보다 $absDays일 빨라요';
            paceColor = userColor;
          } else if (dayDiff < 0) {
            paceText = '플랜보다 $absDays일 느려요';
            paceColor = behindColor;
          } else {
            paceText = '플랜과 같은 속도로 진행 중이에요';
            paceColor = theme.colorScheme.onSurfaceVariant;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '저축 목표 진행률',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final today = DateTime.now();
                      final dateText =
                          '${today.year.toString().substring(2)}.'
                          '${today.month.toString().padLeft(2, '0')}.'
                          '${today.day.toString().padLeft(2, '0')}일자 기준';
                      return Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final maxMarkerLeft = barWidth > 2 ? barWidth - 2 : 0.0;
                  final markerLeft = (barWidth * userProgress - 1)
                      .clamp(0.0, maxMarkerLeft)
                      .toDouble();

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: planProgress,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: planColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Positioned(
                        left: markerLeft.toDouble(),
                        top: -4,
                        child: Container(
                          width: 2,
                          height: 20,
                          decoration: BoxDecoration(
                            color: userColor,
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: [
                              BoxShadow(
                                color: userColor.withValues(alpha: 0.5),
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
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: paceColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paceText,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountdownHeader extends StatelessWidget {
  const _CountdownHeader({required this.vm});
  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: vm.secondTick,
      builder: (_, __, ___) {
        final remain = vm.liveRemaining;
        if (remain == null) {
          return Column(
            children: [
              Text(
                '목표일 없음',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '현재 저축 속도로는 계산할 수 없어요',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }

        final clamped = remain.isNegative ? Duration.zero : remain;

        final days = clamped.inDays;
        final hours = clamped.inHours % 24;
        final minutes = clamped.inMinutes % 60;
        final seconds = clamped.inSeconds % 60;

        String two(int v) => v.toString().padLeft(2, '0');

        return Column(
          children: [
            Text(
              '$days일 ${two(hours)}:${two(minutes)}:${two(seconds)}',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '1초마다 ${vm.perSecondSaving}원이 증가해요',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GoalPaceContainer extends StatelessWidget {
  const _GoalPaceContainer({required this.vm});
  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        return ValueListenableBuilder<int>(
          valueListenable: vm.secondTick,
          builder: (context, __, ___) => _buildContent(context),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    const aheadColor = Color(0xFF0062FF);
    const behindColor = Color(0xFFFF6B6B);
    const reachedColor = Color(0xFF4CAF50);

    final amountDiff = vm.paceAmountDiff;
    final dayDiff = vm.averagePaceDayDiff;
    final amountDiffText = SavingPlanCalculator.formatAmount(amountDiff.abs());
    final dayDiffText = dayDiff.abs().toStringAsFixed(1);
    final isAmountSame = amountDiff.abs().round() == 0;

    String amountText;
    Color amountColor;
    String daysText;
    Color daysColor;

    final theme = Theme.of(context);
    final neutralColor = theme.colorScheme.onSurfaceVariant;

    if (vm.latestPlan == null) {
      amountText = '플랜 없음';
      amountColor = neutralColor;
      daysText = '계산할 수 없어요';
      daysColor = neutralColor;
    } else if (vm.effectiveTargetAmount <= 0 ||
        vm.hasReachedSavingTarget ||
        isAmountSame) {
      amountText = '목표를 달성했어요';
      amountColor = reachedColor;
      daysText = '목표 달성';
      daysColor = reachedColor;
    } else {
      if (amountDiff > 0) {
        amountText = '$amountDiffText원 더 모았어요';
        amountColor = aheadColor;
      } else {
        amountText = '$amountDiffText원 부족해요';
        amountColor = behindColor;
      }

      if (vm.averageDailySaving <= 0) {
        daysText = '계산할 수 없어요';
        daysColor = neutralColor;
      } else if (dayDiffText == '0.0') {
        daysText = '평균 페이스와 같아요';
        daysColor = neutralColor;
      } else if (dayDiff > 0) {
        daysText = '$dayDiffText일 빨라요';
        daysColor = aheadColor;
      } else {
        daysText = '$dayDiffText일 느려요';
        daysColor = behindColor;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _YellowDot(),
              const SizedBox(width: 8),
              Text(
                '목표 페이스',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const _PaceIcon(
                      child: Text(
                        '💰',
                        style: TextStyle(fontSize: 16, height: 1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '금액',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amountText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: theme.dividerColor),
              Expanded(
                child: Column(
                  children: [
                    const _PaceIcon(
                      child: Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFFFF5F5F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '일수',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: daysColor,
                      ),
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
}

class _PaceIcon extends StatelessWidget {
  const _PaceIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 20, height: 20, child: Center(child: child));
  }
}

class _YellowDot extends StatelessWidget {
  const _YellowDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFFFC107),
        shape: BoxShape.circle,
      ),
    );
  }
}

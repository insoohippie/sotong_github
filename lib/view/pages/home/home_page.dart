import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/custom_app_bar_home.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';

import '../../../model/plan/plan_edit_result.dart';
import '../../../services/chart_animation_haptic.dart';
import '../../../services/plan_extension_notice_storage.dart';
import '../../../view_model/home/home_view_model.dart';
import '../../../view_model/notification/notification_view_model.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../view_model/setting/setting_view_model.dart';
import '../../../services/tab_chart_animation_notifier.dart';
import '../plan/plan_edit_page.dart';

import 'home_widgets/home_end_date_extension_dialog.dart';
import 'home_widgets/home_plan_intro_dialog.dart';
import 'home_widgets/home_saving_chart_widget.dart';
import 'home_widgets/home_saving_countdown_sheet.dart';
import 'home_widgets/plan_name_edit_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _planIntroDialogScheduled = false;
  bool _celebrationScheduled = false;
  bool _extensionScheduled = false;
  final GlobalKey<HomeSavingChartWidgetState> _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeViewModel>().load();
      context.read<NotificationViewModel>().loadNotifications();
    });
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}월 ${date.day}일 ($weekday)';
  }

  String _compactIncomeText(int amount) {
    if (amount >= 100000000) {
      final value = amount / 100000000;
      final text = value % 1 == 0
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);
      return '+$text억';
    }

    if (amount >= 10000) {
      final value = amount / 10000;
      final text = value % 1 == 0
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);
      return '+$text만';
    }

    return '+$amount';
  }

  double _toChartPercent(double ratio) {
    final percent = (ratio * 100).clamp(0.0, 100.0);
    return (percent * 100).round() / 100;
  }

  void _schedulePlanIntroDialog(HomeViewModel vm) {
    if (_planIntroDialogScheduled || !vm.shouldShowPlanGraphIntro) return;
    // 완료된 플랜에서는 인트로 예약 자체를 하지 않는다 (ViewModel 가드와 이중 방어)
    if (vm.isActivePlanCompleted) return;
    _planIntroDialogScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      final homeVM = context.read<HomeViewModel>();
      // 1초 대기 중 목표에 도달했을 수 있으므로 표시 직전에 다시 확인
      if (!homeVM.shouldShowPlanGraphIntro || homeVM.isActivePlanCompleted) {
        return;
      }

      await showHomePlanIntroDialog(
        context,
        vm: vm,
        onFinished: () {
          context.read<HomeViewModel>().markPlanGraphIntroSeen();
        },
      );
    });
  }

  void _scheduleCelebrationIfNeeded(HomeViewModel vm) {
    if (_celebrationScheduled || !vm.shouldShowPlanCelebration) return;
    _celebrationScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _celebrationScheduled = false;
        return;
      }
      // 홈이 최상단이 아닐 때(기록 화면·다이얼로그 등이 덮은 상태) 전환하면
      // 다른 화면의 pop과 충돌하므로 보류한다. 티커 재통지가 재시도를 이끈다.
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) {
        _celebrationScheduled = false;
        return;
      }
      final homeVM = context.read<HomeViewModel>();
      if (!homeVM.shouldShowPlanCelebration) {
        _celebrationScheduled = false;
        return;
      }

      // 스냅샷은 완료 감지 시점에 이미 저장됐으므로 전달하지 않는다(중복 저장 방지).
      final info = homeVM.planCompletionInfo;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/celebration_plan_success',
        (_) => false,
        arguments: {
          'planName': info?['planName'] as String?,
          'daysTaken': (info?['daysTaken'] as num?)?.toInt(),
        },
      );
    });
  }

  // ---------- 종료일 자동 연장 (종료일 경과 + 목표 미달) ----------
  /// HomeViewModel이 감지한 연장 요청을 ChatPlanViewModel로 실행하고,
  /// 결과가 있으면 통보 팝업을 1회 띄운다. 우선순위: celebration > 연장 > 인트로.
  void _runEndDateExtensionIfNeeded(HomeViewModel vm) {
    if (_extensionScheduled) return;
    if (vm.shouldShowPlanCelebration) return; // 완료가 우선
    final hasRequest = vm.pendingEndDateExtension != null;
    final hasResult = vm.lastEndDateExtension != null;
    if (!hasRequest && !hasResult) return;
    _extensionScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _extensionScheduled = false;
        return;
      }
      final homeVM = context.read<HomeViewModel>();

      // 1) 실행 단계: 요청이 있으면 연장 수행 (팝업과 무관하게 먼저 적용)
      final req = homeVM.takeEndDateExtensionRequest();
      if (req != null) {
        DateTime? newEnd;
        try {
          newEnd = await context.read<ChatPlanViewModel>().extendPlanEndForShortfall(
            shortfall: req.shortfall,
            dailyNetSaving: req.dailyNetSaving,
          );
        } catch (e) {
          debugPrint('[HomePage] end-date extension failed: $e');
        }
        homeVM.completeEndDateExtension(newEnd);
        if (!mounted) {
          _extensionScheduled = false;
          return;
        }

        // 연장(및 재연장) 시 플랜 업로드 — 플랜 문서뿐 아니라 로컬 전용(localMode)으로
        // 쌓인 소비 기록·카테고리까지 서버에 동기화한다. 실패해도 연장 자체는 유지.
        if (newEnd != null) {
          await _uploadPlanAfterExtension();
          if (!mounted) {
            _extensionScheduled = false;
            return;
          }
        }
      }

      // 2) 표시 단계: 홈이 최상단일 때만, 결과당 1회
      final result = homeVM.lastEndDateExtension;
      if (result == null) {
        _extensionScheduled = false;
        return;
      }
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) {
        _extensionScheduled = false; // 홈으로 돌아오면 재시도
        return;
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null &&
          PlanExtensionNoticeStorage.instance.hasShown(
            uid: uid,
            planId: result.planId,
            newEnd: result.newEnd,
          )) {
        homeVM.clearEndDateExtensionResult();
        _extensionScheduled = false;
        return;
      }

      homeVM.clearEndDateExtensionResult();
      if (uid != null) {
        await PlanExtensionNoticeStorage.instance.markShown(
          uid: uid,
          planId: result.planId,
          newEnd: result.newEnd,
        );
      }
      if (!mounted) {
        _extensionScheduled = false;
        return;
      }
      await showHomeEndDateExtensionDialog(
        context,
        result: result,
        onAdjustPlan: _openPlanEditFromExtension,
      );
      _extensionScheduled = false;
    });
  }

  /// 종료일 연장 후 플랜 업로드 (설정 화면의 '플랜 업로드'와 동일 동작).
  /// 오프라인이면 건너뛴다 — 로컬에는 이미 저장되어 있고 dirty 플래그로 다음 기회에 동기화된다.
  Future<void> _uploadPlanAfterExtension() async {
    final settingVM = context.read<SettingViewModel>();
    if (!settingVM.isOnline) {
      debugPrint('[HomePage] skip upload after extension: offline');
      return;
    }
    try {
      await settingVM.uploadAllData();
      debugPrint('[HomePage] plan uploaded after end-date extension');
    } catch (e) {
      debugPrint('[HomePage] upload after extension failed: $e');
    }
  }

  /// 연장 팝업의 '계획 조정하기' → 플랜 편집 화면 (설정 화면과 동일 흐름)
  Future<void> _openPlanEditFromExtension() async {
    final chatVm = context.read<ChatPlanViewModel>();
    final navigator = Navigator.of(context, rootNavigator: true);
    final result = await navigator.push<PlanEditResult>(
      MaterialPageRoute(builder: (_) => PlanEditPage(useLocalDraft: false)),
    );
    if (!navigator.mounted || result == null) return;
    chatVm.applyPlanEditResult(result);
    final ok = await chatVm.savePlan();
    if (!navigator.mounted) return;
    ScaffoldMessenger.of(navigator.context).showSnackBar(
      SnackBar(content: Text(ok ? '플랜이 수정되었습니다.' : '플랜 저장에 실패했어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final notificationVM = context.watch<NotificationViewModel>();
    final homeChartAnimationTick = context.homeChartAnimationTick;
    final horizontalPadding = PaddingResponsive16_40Vw.horizontal(
      context,
      PaddingResponsive16_40Vw.fractionScreen075,
    );
    final viewHeight = MediaQuery.sizeOf(context).height;
    final cardGap = viewHeight < 750
        ? 24.0
        : viewHeight < 820
        ? 32.0
        : 40.0;

    if (vm.isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (vm.error != null) {
      return Scaffold(
        body: SafeArea(child: Center(child: Text('오류: ${vm.error}'))),
      );
    }

    // 우선순위: celebration(완료) > 종료일 연장 > 인트로
    _scheduleCelebrationIfNeeded(vm);
    _runEndDateExtensionIfNeeded(vm);
    _schedulePlanIntroDialog(vm);

    final userName = vm.name;
    final planName = vm.planTitle;
    final fixedSpending = vm.selectedDateDailyLimitText;

    final selectedDate = vm.selectedDate;
    final displayDate = _formatDate(selectedDate);

    final todayIncome = vm.selectedDateIncome;
    final todaySpending = vm.selectedDateSpending;
    final day = vm.selectedDayRecord;

    final hasIncome =
        (day?.incomeEntries.isNotEmpty ?? false) ||
            todayIncome > 0;

    final hasSpending =
        (day?.spendingEntries.isNotEmpty ?? false) ||
            todaySpending > 0;
    final todaySpendingText = vm.selectedDateSpendingText;
    final isUnrecorded = vm.isSelectedDateUnrecorded;
    final showPendingCalendarBadge = vm.hasUnrecordedSpendingDays;
    final dailyLimit = vm.selectedDateDailyLimit.toDouble();
    final actualSpent = todaySpending.toDouble();
    final isOverLimit =
        hasSpending &&
            !isUnrecorded &&
            dailyLimit > 0 &&
            actualSpent > dailyLimit;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerBackgroundColor = (!hasSpending || isUnrecorded)
        ? (isDark ? theme.colorScheme.surface : AppColors.greyBackground)
        : isOverLimit
        ? (isDark ? const Color(0xFF3D2020) : const Color(0xFFFFEFEF))
        : (isDark ? theme.colorScheme.surface : const Color(0xFFEFF5FF));

    final spentTextColor = !hasSpending
        ? theme.colorScheme.onSurface
        : isUnrecorded
        ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
        : isOverLimit
        ? const Color(0xFFFF5F5F)
        : AppColors.primary;

    final isPlanCompleted = vm.isActivePlanCompleted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBarHome(
              text: '$userName 님',
              unreadCount: notificationVM.unreadCount,
              onNotifications: () {
                Navigator.pushNamed(context, '/notification');
              },
              onSettings: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed('/setting');
              },
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _chartKey.currentState?.resetToDefaultView(),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        RoundedInfoContainer(
                        backgroundColor: isDark
                            ? AppColors.darkBackground
                            : theme.colorScheme.surface,
                        padding: 12,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.planTagBackground,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            planName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            HomeSavingChartWidget(
                              key: _chartKey,
                              vm: vm,
                              userPercent: _toChartPercent(
                                vm.displayGraphUserPercent,
                              ),
                              planPercent: _toChartPercent(
                                vm.displayGraphPlanPercent,
                              ),
                              replayGaugeAnimation: vm.shouldShowPlanGraphIntro,
                              animationTrigger: homeChartAnimationTick,
                              onOpenCountdown: () => _onCenterGaugeTap(vm),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: cardGap),
                      RoundedInfoContainer(
                        backgroundColor: containerBackgroundColor,
                        padding: 20,
                        child: Column(
                          crossAxisAlignment: hasSpending
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 32,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayDate,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),

                                  /*
       * 소비 기록 여부와 상관없이
       * 수입이 있으면 날짜 옆에 +5만 형태로 표시
       */
                                  if (hasIncome) ...[
                                    const SizedBox(width: 8),
                                    _IncomeChip(
                                      text: _compactIncomeText(todayIncome),
                                    ),
                                  ],

                                  const SizedBox(width: 8),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _HeaderIconButton(
                                        icon: Icons.chevron_left,
                                        iconColor:
                                        theme.colorScheme.onSurfaceVariant,
                                        onTap: () => vm.changeDate(-1),
                                      ),
                                      const SizedBox(width: 2),
                                      _HeaderIconButton(
                                        icon: Icons.chevron_right,
                                        iconColor:
                                        theme.colorScheme.onSurfaceVariant,
                                        enabled: vm.canNavigateToNextDate,
                                        onTap: () => vm.changeDate(1),
                                      ),
                                      const SizedBox(width: 2),
                                      _CalendarHeaderButton(
                                        isUnrecorded: showPendingCalendarBadge,
                                        enabled: !isPlanCompleted,
                                        onTap: () {
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pushNamed(
                                            '/pending_spending',
                                            arguments: <String, dynamic>{
                                              'initialMonth': selectedDate,
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (!hasSpending)
                              SmallRoundedButton(
                                text: hasIncome
                                    ? '소비 기록하기'
                                    : '수입/소비 기록하러 가기',
                                enabled: !isPlanCompleted,
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(
                                    '/record',
                                    arguments: selectedDate,
                                  );
                                },
                              )
                            else
                              InkWell(
                                onTap: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(
                                    '/today_record',
                                    arguments: selectedDate,
                                  );
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              todaySpendingText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: spentTextColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            ' / ',
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              fixedSpending,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCenterGaugeTap(HomeViewModel vm) {
    if (vm.isActivePlanCompleted) {
      final info = vm.planCompletionInfo;
      Navigator.of(context, rootNavigator: true).pushNamed(
        '/celebration_plan_success',
        arguments: {
          'planName': info?['planName'] as String? ?? vm.planTitle,
          'daysTaken': (info?['daysTaken'] as num?)?.toInt(),
        },
      );
      return;
    }
    _openSavingSheet(vm);
  }

  void _openSavingSheet(HomeViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: HomeSavingCountdownSheet(vm: vm),
        );
      },
    );
  }
}

class _IncomeChip extends StatelessWidget {
  final String text;

  const _IncomeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool enabled;

  const _HeaderIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? iconColor
        : iconColor.withValues(alpha: 0.35);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        width: 32,
        height: 32,
        child: InkResponse(
          onTap: enabled
              ? () {
                  AppHaptics.buttonTap();
                  onTap();
                }
              : null,
          radius: 18,
          child: Center(child: Icon(icon, size: 24, color: effectiveColor)),
        ),
      ),
    );
  }
}

class _CalendarHeaderButton extends StatelessWidget {
  final bool isUnrecorded;
  final bool enabled;
  final VoidCallback onTap;

  const _CalendarHeaderButton({
    required this.isUnrecorded,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = enabled
        ? AppColors.primary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: InkResponse(
                onTap: enabled
                    ? () {
                        AppHaptics.buttonTap();
                        onTap();
                      }
                    : null,
                radius: 18,
                child: Center(
                  child: Icon(
                    Icons.calendar_month_outlined,
                    size: 24,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            if (isUnrecorded && enabled)
              Positioned(
                right: -1,
                top: -1,
                child: IgnorePointer(
                  child: Container(
                    width: 11,
                    height: 11,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
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

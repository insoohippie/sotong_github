import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong/view/pages/home/home_widgets/home_saving_chart_widget.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';
import '../../../component/theme/padding/vertical_section_spacing_ref_height_600.dart';

import '../../../repository/auth_repository.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../view_model/services/saving_calculator.dart';
import '../../../services/local_notification_service.dart';
import '../../../services/notification_settings_storage.dart';

const _kSuccessSectionGaps = <double>[24, 24, 12];

PreferredSizeWidget _emptyTopAppBar() {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    automaticallyImplyLeading: false,
    toolbarHeight: kToolbarHeight,
  );
}

class PlanSuccessPage extends StatefulWidget {
  const PlanSuccessPage({super.key});

  @override
  State<PlanSuccessPage> createState() => _PlanSuccessPageState();
}

class _PlanSuccessPageState extends State<PlanSuccessPage> {
  bool _started = false;
  bool _savingDone = false;
  bool _saveOk = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_runSave);
  }

  Future<void> _runSave() async {
    if (_started) return;
    _started = true;

    final vm = context.read<ChatPlanViewModel>();
    vm.preparePlanStructureForSummary();
    final ok = await vm.savePlan();

    final authRepo = context.read<AuthRepository>();
    final uid = authRepo.cachedUid ?? authRepo.currentUserId;

    if (ok && uid != null) {
      final storage = NotificationSettingsStorage.instance;
      final applied = await storage.hasAppliedSignupDefaults(uid);

      if (!applied) {
        final defaults = defaultSignupNotificationSettings;
        await storage.save(uid, defaults);
        try {
          await LocalNotificationService.instance.updateSchedules(defaults);
          // 예약이 성공했을 때만 적용 완료로 마킹해, 실패 시 재시도 여지를 남긴다.
          await storage.markSignupDefaultsApplied(uid);
        } catch (e) {
          debugPrint('[PlanSuccessPage] 기본 알림 예약 실패: $e');
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _savingDone = true;
      _saveOk = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatPlanViewModel>();
    final isLoading = vm.isSaving || !_savingDone;
    final horizontalPadding = PaddingResponsive16_40Vw.horizontal(
      context,
      PaddingResponsive16_40Vw.fractionScreen075,
    );

    // 로딩 중
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _emptyTopAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('플랜을 저장하는 중입니다...'),
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

    // 저장 실패
    if (!_saveOk) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _emptyTopAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 56,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '플랜 저장에 실패했어요.\n잠시 후 다시 시도해주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(text: '다시 시도', onPressed: _runSave),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home_tab_navigator',
                              (route) => false,
                            );
                          },
                          child: const Text('홈으로 이동'),
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

    // 저장 성공 → VM 데이터로 화면 구성
    final userName = vm.userName.isNotEmpty ? vm.userName : '사용자';

    final startDate = vm.totalPlan.startDate ?? DateTime.now();
    final calc = vm.calculationResult;
    final goalDate = calc?.goalDateTime ?? startDate;

    final dailyLimit = vm.refData.primaryDailyConsumeSum;
    final targetAmount = (vm.totalPlan.targetAmount ?? 0).toDouble();

    // 텍스트 파트 구성
    final List<TextPart> messageHeaderParts = [
      TextPart(userName, AppColors.primary, bold: true),
      TextPart('님을 위한\n플랜이 생성되었어요! 🎉', AppColors.text),
    ];

    final List<TextPart> messageParagraphParts1 = [
      TextPart('${startDate.year}년 ', AppColors.text),
      TextPart('${startDate.month}월 ${startDate.day}일', AppColors.primary),
      TextPart('부터\n${goalDate.year}년 ', AppColors.text),
      TextPart('${goalDate.month}월 ${goalDate.day}일', AppColors.primary),
      TextPart('까지\n\n', AppColors.text),
      TextPart('하루 소비한도 금액은\n', AppColors.text, bold: true),
      TextPart(
        '${SavingPlanCalculator.formatAmount(dailyLimit)}원',
        AppColors.primary,
        bold: true,
      ),
      TextPart('입니다.', AppColors.text, bold: true),
    ];

    final List<TextPart> messageParagraphParts2 = [
      TextPart(
        '${goalDate.year}년 ${goalDate.month}월 ${goalDate.day}일에\n',
        AppColors.text,
      ),
      TextPart(
        '${SavingPlanCalculator.formatAmount(targetAmount)}원',
        AppColors.primary,
      ),
      TextPart('이 모여요!', AppColors.text),
    ];

    final sectionGaps = SectionGapRefHeight600.scaledMinsFromContext(
      context,
      minGaps: _kSuccessSectionGaps,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _emptyTopAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: sectionGaps[0]),
                    MultiColorText(
                      baseStyle: AppTextStyles.header,
                      parts: messageHeaderParts,
                    ),
                    SizedBox(height: sectionGaps[1]),
                    RoundedInfoContainer(
                      child: Row(
                        children: [
                          Expanded(
                            child: MultiColorText(
                              baseStyle: AppTextStyles.paragraph,
                              parts: messageParagraphParts1,
                            ),
                          ),
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionGaps[2]),
                    RoundedInfoContainer(
                      child: Row(
                        children: [
                          Expanded(
                            child: MultiColorText(
                              baseStyle: AppTextStyles.paragraph,
                              parts: messageParagraphParts2,
                            ),
                          ),
                          const Icon(
                            Icons.savings_outlined,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomButton(
              text: '다음',
              onPressed: () async {
                HomeSavingChartWidget.resetGaugeAnimationForPlay();
                await context.read<AuthRepository>().setHasPlan(true); // 추후 수정 필요
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home_tab_navigator',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }
}

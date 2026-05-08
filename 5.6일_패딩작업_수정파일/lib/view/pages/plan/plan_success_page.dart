import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../component/appbars/back_only_app_bar.dart';
import 'package:sotong_local/view/pages/home/home_widgets/home_saving_chart_widget.dart';
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

/// [SectionGapRefHeight600.refHeight] 600에서의 **최소** 구역 간 pt.
/// 구역 3개(헤더, 카드1, 카드2) → 3칸: 맨 위~1, 1~2, 2~3. 값만 조정.
const _kSuccessSectionGaps = <double>[24, 24, 12];

class PlanSuccessPage extends StatefulWidget {
  const PlanSuccessPage({super.key});

  @override
  State<PlanSuccessPage> createState() => _PlanSuccessPageState();
}

class _PlanSuccessPageState extends State<PlanSuccessPage> {
  /// 저장 루프가 이미 돌고 있을 때(중복 탭 방지)만 막는다. 첫 시도 이후 `true`로 고정돼
  /// 끊기면(구버전 `if (_started) return`처럼) '다시 시도'가 영구 무반응이 된다.
  bool _saveInFlight = false;
  bool _savingDone = false;
  bool _saveOk = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_runSave);
  }

  Future<void> _runSave() async {
    if (_saveInFlight) {
      return;
    }
    _saveInFlight = true;
    if (mounted) {
      setState(() {
        _savingDone = false;
      });
    }

    try {
      final vm = context.read<ChatPlanViewModel>();
      vm.preparePlanStructureForSummary();
      final ok = await vm.savePlan();

      if (ok) {
        final storage = NotificationSettingsStorage.instance;
        final applied = await storage.hasAppliedSignupDefaults();
        if (!applied) {
          final defaults = defaultSignupNotificationSettings;
          await storage.save(defaults);
          await storage.markSignupDefaultsApplied();
          await LocalNotificationService.instance.updateSchedules(defaults);
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _savingDone = true;
        _saveOk = ok;
      });
    } finally {
      _saveInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatPlanViewModel>();
    final isLoading = vm.isSaving || !_savingDone;

    // 로딩 중
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const BackOnlyAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: PaddingResponsive16_40Vw.horizontal(
                      context,
                      PaddingResponsive16_40Vw.fractionScreen075,
                    ),
                  ),
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
        appBar: const BackOnlyAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: PaddingResponsive16_40Vw.horizontal(
                      context,
                      PaddingResponsive16_40Vw.fractionScreen075,
                    ),
                  ),
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
                            Navigator.of(context, rootNavigator: true)
                                .pushNamedAndRemoveUntil(
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
      appBar: const BackOnlyAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: PaddingResponsive16_40Vw.horizontal(
                    context,
                    PaddingResponsive16_40Vw.fractionScreen075,
                  ),
                ),
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
                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil(
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

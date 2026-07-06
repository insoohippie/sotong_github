import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../component/buttons/custom_button.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';
import '../../../repository/auth_repository.dart';
import '../../../repository/plan_cache_repository.dart';
import '../../../repository/plan_repository.dart';
import '../../../repository/ref_category_repository.dart';
import '../../../repository/ref_data_repository.dart';
import '../../../repository/record_repository.dart';
import '../../../services/plan_debug_printer.dart';
import '../../../view_model/auth/login_view_model.dart';
import '../../../view_model/home/home_view_model.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  bool _start = false;
  Timer? _timer;

  static const double _startLogoSize = 180;
  static const double _endLogoSize = 88;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _start = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    final horizontalPadding = PaddingResponsive16_40Vw.horizontal(
      context,
      PaddingResponsive16_40Vw.fractionScreen075,
    );

    final screenSize = MediaQuery.of(context).size;
    final logoSize = _start ? _endLogoSize : _startLogoSize;
    final titleWidth =
        screenSize.width - (horizontalPadding * 2) - _endLogoSize - 12;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              left: _start ? horizontalPadding : screenSize.width,
              top: 60,
              width: titleWidth,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _start ? 1 : 0,
                child: MultiColorText(
                  baseStyle: AppTextStyles.header,
                  parts: const [
                    TextPart('재미있게 ', Colors.black),
                    TextPart('소통', AppColors.primary),
                    TextPart('하며\n', Colors.black),
                    TextPart('소', AppColors.primary),
                    TextPart('비 ', Colors.black),
                    TextPart('통', AppColors.primary),
                    TextPart('제 하자!', Colors.black),
                  ],
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              left: _start ? horizontalPadding : screenSize.width,
              right: _start ? horizontalPadding : -screenSize.width,
              top: 190,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _start ? 1 : 0,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.fieldSpacing),
                          CustomTextField(
                            controller: vm.emailController,
                            hintText: '아이디 입력',
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: vm.passwordController,
                            hintText: '비밀번호 입력',
                            obscureText: true,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (vm.errorMessage != null)
                                Text(
                                  '• ${vm.errorMessage}',
                                  style: AppTextStyles.errorText,
                                )
                              else
                                const SizedBox(),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pushNamed(context, '/signup');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF0062FF),
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 16),
                        child: vm.isLoading
                            ? const SizedBox(
                                height: 48,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : CustomButton(
                                padding: EdgeInsets.zero,
                                text: '로그인',
                                onPressed: () async {
                                  final success = await vm.login();

                                  if (!context.mounted) return;

                                  if (success) {
                                    final hydrated =
                                        await _hydrateCachesIfNeeded(context);
                                    if (!hydrated) return;

                                    final authRepo = context.read<AuthRepository>();
                                    var next = authRepo.nextRouteBySession();

                                    final shouldProbeExistingPlan =
                                        next == '/unsuccess_plan_quit' ||
                                            !authRepo.cachedHasPlan;

                                    if (shouldProbeExistingPlan) {
                                      try {
                                        final planRepo =
                                            context.read<PlanRepository>();
                                        final existingPlan = await planRepo
                                            .getLatestPlanForCurrentUser();

                                        if (existingPlan != null) {
                                          final refDataRepo =
                                              context.read<RefDataRepository>();
                                          final refData =
                                              await refDataRepo.loadAll();
                                          refData.planId = existingPlan.planId;

                                          final tree = PlanDebugPrinter.describe(
                                            plan: existingPlan,
                                            refData: refData,
                                          );

                                          debugPrint(
                                            '--- Plan Tree Loaded (Login) ---\n$tree',
                                          );

                                          final cacheRepo =
                                              context.read<PlanCacheRepository>();
                                          final uid = authRepo.cachedUid ??
                                              authRepo.currentUserId;

                                          if (uid != null) {
                                            await cacheRepo.saveSnapshot(
                                              uid: uid,
                                              snapshot: PlanCacheSnapshot(
                                                plan: existingPlan,
                                                refData: refData,
                                                needsInitialUpload: false,
                                              ),
                                            );

                                            debugPrint(
                                              '[EmailLoginPage] plan snapshot cached for uid=$uid',
                                            );
                                          } else {
                                            debugPrint(
                                              '[EmailLoginPage] skipping plan cache save: uid missing',
                                            );
                                          }

                                          await authRepo.setHasPlan(true);
                                          next = authRepo.nextRouteBySession(
                                            skipHasPlanCheck: true,
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint(
                                          '[EmailLoginPage] failed to probe existing plan: $e',
                                        );
                                      }
                                    }

                                    if (authRepo.cachedHasPlan) {
                                      final cacheRepo =
                                          context.read<PlanCacheRepository>();
                                      final uid = authRepo.cachedUid ??
                                          authRepo.currentUserId;
                                      final snapshot = uid != null
                                          ? cacheRepo.loadSnapshot(uid)
                                          : null;

                                      if (snapshot != null) {
                                        final tree = PlanDebugPrinter.describe(
                                          plan: snapshot.plan,
                                          refData: snapshot.refData,
                                        );

                                        debugPrint(
                                          '--- Plan Cache Snapshot (Login) ---\n$tree',
                                        );
                                      } else {
                                        debugPrint(
                                          '[EmailLoginPage] hasPlan=true but cache snapshot missing',
                                        );
                                      }
                                    }

                                    debugPrint(
                                      '🧩 [EmailLoginPage] login success -> nextRoute=$next',
                                    );

                                    if (next == '/home_tab_navigator') {
                                      await context.read<HomeViewModel>().refresh();
                                    }

                                    if (!context.mounted) return;

                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      next,
                                      (route) => false,
                                    );
                                  }
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeInOutCubic,
              width: logoSize,
              height: logoSize,
              left: _start
                  ? screenSize.width - horizontalPadding - logoSize
                  : (screenSize.width - logoSize) / 2,
              top: _start ? 54 : (screenSize.height - logoSize) / 2 - 40,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/sotong_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _hydrateCachesIfNeeded(BuildContext context) async {
  final cacheRepo = context.read<PlanCacheRepository>();
  final authRepo = context.read<AuthRepository>();
  final recordRepo = context.read<RecordRepository>();
  final refCatRepo = context.read<RefCategoryRepository>();
  final planRepo = context.read<PlanRepository>();

  final uid = authRepo.cachedUid ?? authRepo.currentUserId;
  if (uid == null) return true;

  final snapshot = cacheRepo.loadSnapshot(uid);
  final needsPlanUpload = snapshot?.needsInitialUpload ?? false;
  final needRecordHydration = !recordRepo.hasAnyCacheForCurrentUser();
  final needSpendingCats = !refCatRepo.hasCachedDoc('recordSpending');
  final needIncomeCats = !refCatRepo.hasCachedDoc('recordAddIncome');

  final requiresOnline =
      needsPlanUpload || needRecordHydration || needSpendingCats || needIncomeCats;

  if (requiresOnline && (!recordRepo.isOnline || !refCatRepo.isOnline)) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('인터넷 연결 필요'),
          content: const Text(
            '저장된 데이터를 불러오거나 업로드하려면 인터넷 연결이 필요합니다. 연결 후 다시 로그인해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    return false;
  }

  if (needsPlanUpload && snapshot != null) {
    try {
      var planToSave = snapshot.plan;

      if (planToSave.planId.isEmpty) {
        final newId = await planRepo.saveCurrentUserPlan(planToSave);
        if (newId.isNotEmpty) {
          planToSave = planToSave.copyWith(planId: newId);
        }
      } else {
        await planRepo.replacePlan(planToSave);
      }

      await cacheRepo.saveSnapshot(
        uid: uid,
        snapshot: PlanCacheSnapshot(
          plan: planToSave,
          refData: snapshot.refData,
          recordCache: snapshot.recordCache,
          needsInitialUpload: false,
        ),
      );

      await authRepo.setHasPlan(true);
    } catch (e) {
      _showInitialUploadFailedDialog(context);
      return false;
    }
  }

  if (needRecordHydration) {
    final prevLocalMode = recordRepo.localMode;
    recordRepo.localMode = false;

    try {
      await recordRepo.hydrateAllFromRemote();
    } finally {
      recordRepo.localMode = prevLocalMode;
    }
  }

  if (needSpendingCats) {
    await refCatRepo.fetchRefCategories(docId: 'recordSpending');
  }

  if (needIncomeCats) {
    await refCatRepo.fetchRefCategories(docId: 'recordAddIncome');
  }

  return true;
}

void _showInitialUploadFailedDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('플랜 업로드 실패'),
        content: const Text(
          '저장된 플랜을 서버에 업로드하지 못했습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}
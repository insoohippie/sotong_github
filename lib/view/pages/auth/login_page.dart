import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../repository/auth_repository.dart';
import '../../../repository/plan_cache_repository.dart';
import '../../../repository/plan_repository.dart';
import '../../../view_model/auth/login_view_model.dart';
import '../../../view_model/home/home_view_model.dart';
import '../../../repository/ref_data_repository.dart';
import '../../../services/plan_debug_printer.dart';
import '../../../repository/record_repository.dart';
import '../../../repository/ref_category_repository.dart';

class EmailLoginPage extends StatelessWidget {
  const EmailLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MultiColorText(
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
                    const SizedBox(height: 20),
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
                        // 에러 메시지 (왼쪽 정렬)
                        if (vm.errorMessage != null)
                          Text(
                            '• ${vm.errorMessage}',
                            style: AppTextStyles.errorText,
                          )
                        else
                          const SizedBox(), // 에러 없을 때 공간 유지
                        // 회원가입 버튼 (오른쪽 정렬)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(context, '/signup');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // 로그인 버튼 + 로딩 인디케이터
            vm.isLoading
                ? const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            )
                : CustomButton(
              text: '로그인',
              onPressed: () async {
                final success = await vm.login();

                if (!context.mounted) return;

                if (success) {
                  final authRepo = context.read<AuthRepository>();
                  var next = authRepo.nextRouteBySession();
                  if (next == '/plan_chat') {
                    try {
                      final planRepo = context.read<PlanRepository>();
                      final existingPlan =
                          await planRepo.getLatestPlanForCurrentUser();
                      if (existingPlan != null) {
                        final hydrated = await _hydrateCachesIfNeeded(context);
                        if (!hydrated) return;
                        final refDataRepo = context.read<RefDataRepository>();
                        final refData = await refDataRepo.loadAll();
                        refData.planId = existingPlan.planId;
                        final tree = PlanDebugPrinter.describe(
                          plan: existingPlan,
                          refData: refData,
                        );
                        debugPrint('--- Plan Tree Loaded (Login) ---\n$tree');
                        final cacheRepo = context.read<PlanCacheRepository>();
                        final uid =
                            authRepo.cachedUid ?? authRepo.currentUserId;
                        if (uid != null) {
                          await cacheRepo.saveSnapshot(
                            uid: uid,
                            snapshot: PlanCacheSnapshot(
                              plan: existingPlan,
                              refData: refData,
                            ),
                          );
                          debugPrint('[EmailLoginPage] plan snapshot cached for uid=$uid');
                        } else {
                          debugPrint('[EmailLoginPage] skipping plan cache save: uid missing');
                        }
                        await authRepo.setHasPlan(true);
                        next = authRepo.nextRouteBySession(skipHasPlanCheck: true);
                      }
                    } catch (e) {
                      debugPrint('[EmailLoginPage] failed to probe existing plan: $e');
                    }
                  }

                  if (authRepo.cachedHasPlan) {
                    final cacheRepo = context.read<PlanCacheRepository>();
                    final uid =
                        authRepo.cachedUid ?? authRepo.currentUserId;
                    final snapshot =
                        uid != null ? cacheRepo.loadSnapshot(uid) : null;
                    if (snapshot != null) {
                      final tree = PlanDebugPrinter.describe(
                        plan: snapshot.plan,
                        refData: snapshot.refData,
                      );
                      debugPrint('--- Plan Cache Snapshot (Login) ---\n$tree');
                    } else {
                      debugPrint('[EmailLoginPage] hasPlan=true but cache snapshot missing');
                    }
                  }

                  print('🧩 [EmailLoginPage] login success -> nextRoute=$next');

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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Future<bool> _hydrateCachesIfNeeded(BuildContext context) async {
  final cacheRepo = context.read<PlanCacheRepository>();
  final authRepo = context.read<AuthRepository>();
  final uid = authRepo.cachedUid ?? authRepo.currentUserId;
  if (uid == null) return true;

  final snapshot = cacheRepo.loadSnapshot(uid);
  if (snapshot != null) return true;

  debugPrint('[EmailLoginPage] cache snapshot missing -> hydrate record/categories');
  final recordRepo = context.read<RecordRepository>();
  final refCatRepo = context.read<RefCategoryRepository>();
  if (!recordRepo.isOnline || !refCatRepo.isOnline) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('인터넷 연결 필요'),
          content: const Text('저장된 플랜을 불러오려면 인터넷 연결이 필요합니다. 연결 후 다시 로그인해주세요.'),
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
  final prevLocalMode = recordRepo.localMode;
  if (!recordRepo.hasAnyCacheForCurrentUser()) {
    recordRepo.localMode = false;
    try {
      await recordRepo.hydrateAllFromRemote();
    } finally {
      recordRepo.localMode = prevLocalMode;
    }
  }
  if (!refCatRepo.hasCachedDoc('recordSpending')) {
    await refCatRepo.fetchRefCategories(docId: 'recordSpending');
  }
  if (!refCatRepo.hasCachedDoc('recordAddIncome')) {
    await refCatRepo.fetchRefCategories(docId: 'recordAddIncome');
  }
  return true;
}
